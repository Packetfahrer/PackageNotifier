#import "BBDataProvider-Protocol.h"
#import "CydiaNotifierProvider.h"
#import <mach/mach_types.h>


extern "C" id BBDataProviderAddBulletinForDestinations(id, BBBulletinRequest*, int);
extern "C" void BBDataProviderWithdrawBulletinsWithRecordID(id dataProvider, NSString* recordID);
extern "C" mach_port_t SBSSpringBoardServerPort();
extern "C" void SBSetApplicationBadgeNumber(mach_port_t serverPort, const char* applicationIdentifier, int badgeAmount);


static CydiaNotifierProvider* sharedProvider;

static void refresh_callback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[((__bridge CydiaNotifierProvider*)observer) refreshAndUpdate];
}

static void cancel_callback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[((__bridge CydiaNotifierProvider*)observer) cancelRefresh];
}

static void prefs_callback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[((__bridge CydiaNotifierProvider*)observer) reloadPreferences];
}

@implementation CydiaNotifierProvider
+ (CydiaNotifierProvider*)sharedProvider
{
	return sharedProvider;
}

-(CydiaNotifierProvider*)init{
	NSProcessInfo *processInfo;
	NSDictionary* environment;

	if ( self ){
		processInfo = [NSProcessInfo processInfo];
		environment = [processInfo environment];
		if ([environment objectForKey:@"SubstrateSafeMode_"]){
			//don't load when in safe mode
			self = nil;
		}
		else{
			sharedProvider = self;
			self.isWorking = NO;
			self->cachedBulletins = [[NSMutableDictionary alloc]init];
			self->currentlyShownBulletins = [[NSMutableDictionary alloc]init];
			notify_register_check("com.accuratweaks.cydianotifier/status", &self->status_token);
		    [LASharedActivator registerListener: self forName:@"com.accuratweaks.cydianotifier.refresh"];

		    CFNotificationCenterRef darwinCenter = CFNotificationCenterGetDarwinNotifyCenter();
	   		CFNotificationCenterAddObserver(darwinCenter, (const void*)self, refresh_callback, CFSTR("com.accuratweaks.cydianotifier/refresh"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	   		CFNotificationCenterAddObserver(darwinCenter, (const void*)self, cancel_callback, CFSTR("com.accuratweaks.cydianotifier/cancel"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	   		CFNotificationCenterAddObserver(darwinCenter, (const void*)self, prefs_callback, CFSTR("com.accuratweaks.cydianotifier/prefschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);

		}
	}
	return self;
}

#pragma mark BulletinDataProvider logic

//Todo: Check on older iOS versions - the destination ids (actually not ids, more combined flags) have most certainly changed! That explains why curiosa is not making any sounds or banners on iOS 8.

-(NSString*)sectionIdentifier
{
	return @"com.saurik.Cydia";
}

-(NSString*) sectionDisplayName
{
  return @"Cydia";
}


- (id)clearedInfoForBulletins:(NSSet *)bulletins2Remove lastClearedInfo:(id)arg2{
	//callend when we tap on a bulletin, or swipe and click dismiss, or dismiss the whole section in the nc.
	for(BBBulletin* bulletin in bulletins2Remove){
	  	[self->cachedBulletins removeObjectForKey:[bulletin publisherBulletinID]];
	  	[self->dismissedBulletins addObject:[bulletin publisherBulletinID]];
	  	[self->currentlyShownBulletins removeObjectForKey:[bulletin publisherBulletinID]];
	}

	[self saveDismissed];
	[self saveCurrentlyShownBulletins];
	return nil;
}

- (NSSet *)bulletinsFilteredBy:(unsigned long long)arg1 count:(unsigned long long)arg2 lastCleared:(id)arg3
{
	//this is required as of iOS 8.1
  	return [NSSet setWithArray:[self->cachedBulletins allValues]];
}

- (NSArray *)sortDescriptors{
	NSSortDescriptor* sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@("date") ascending:FALSE];
	return [NSArray arrayWithObject:sortDescriptor];
}


- (void)dataProviderDidLoad{
	//Called after respring
	[self reloadPreferences];
	[self reloadPackagesWithUpdates];
	[self restoreBulletins];
}

#pragma mark refresh logic

-(void)refreshAndUpdate{
	if(!self.isWorking){
		self.isWorking = TRUE;
		notify_set_state(self->status_token, 1);
		notify_post("com.accuratweaks.cydianotifier/status");
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			BOOL successful = [self refresh];
			if(successful){
				//this (hopefully) changed.
				[self reloadLastUpdateTime];

				//we got new data, let's update and create some bulletins
				NSArray* packages = [self getUpdates];

				//this uses xpc which is actually not nesseasary, since we are allready in springboard.
				SBSetApplicationBadgeNumber(SBSSpringBoardServerPort(), "com.saurik.Cydia", [packages count]);
				[self updateBulletinsForPackages:packages];
			}
			notify_set_state(self->status_token, 0);
			notify_post("com.accuratweaks.cydianotifier/status");
			self.isWorking = FALSE;

		});
	}
}

-(void)reloadPackagesWithUpdates{
	dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
		NSDictionary* packagesWithUpdates = [self getPackagesWithUpdates];

		//save that. we need it for the preferences.
		NSArray* packageIdentifiers = [packagesWithUpdates allKeys];
		NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:CydiaNotifierPreferencePlistPath];
		NSMutableDictionary* mutableSettings = settings ? [settings mutableCopy] : [[NSMutableDictionary alloc]init];
		mutableSettings[@"packagesWithUpdates"] = packageIdentifiers;
		[mutableSettings writeToFile:CydiaNotifierPreferencePlistPath atomically:YES];
	});
}


-(BOOL)refresh{
	//this is sync, better run it in a queue

	//we need a helper binary, since the refresh command must be run as root, and I can't do that from SpringBoard itself.
	pid_t _child;
	const char* args[] = {"refresh-helper", "start", NULL};
	posix_spawn(&_child, "/Library/Application Support/CydiaNotifier/refresh-helper", NULL, NULL, (char* const*)args, NULL);
	setpriority(PRIO_PROCESS, _child, 10);
	int status = -1;
	int result;
	if (waitpid(_child, &result, 0) != -1)
		if (WIFEXITED(result))
			status = WEXITSTATUS(result);

	return (status == 0);
}


-(void)cancelRefresh{
	if(self.isWorking){
		dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
			//need a helper binary, same reason as for -(BOOL)refresh.
			pid_t _child;
			const char* args[] = {"refresh-helper", "stop", NULL};
			posix_spawn(&_child, "/Library/Application Support/CydiaNotifier/refresh-helper", NULL, NULL, (char* const*)args, NULL);
			setpriority(PRIO_PROCESS, _child, 10);
			int result;
			waitpid(_child, &result, 0);

			notify_set_state(self->status_token, 0);
			notify_post("com.accuratweaks.cydianotifier/status");
		});
	}
}

#pragma mark Bulletin Logic

-(void)restoreBulletins{
	//restores the bulleitns after a respring
	[self->currentlyShownBulletins enumerateKeysAndObjectsUsingBlock:^(NSString* bulletinID, NSDictionary* package_data, BOOL* stop) {
			NSString* bulletinTitle = package_data[@"title"];
			NSString* bulletinSubtitle = package_data[@"subtitle"];
			NSString* bulletinMessage = package_data[@"message"];
			NSString* bulletinURLStr = package_data[@"urlString"];
			NSDate* bulletinDate = package_data[@"date"];

			BBBulletinRequest* bulletin = [[BBBulletinRequest alloc]init];
			[bulletin setTitle:bulletinTitle];
			[bulletin setSectionID: @"com.saurik.Cydia"];
			NSURL* bulletinURL = [NSURL URLWithString:bulletinURLStr];
			BBAction* action = [BBAction actionWithLaunchURL:bulletinURL callblock:nil];
			[bulletin setDefaultAction:action];
			[bulletin setBulletinID: bulletinID];
			[bulletin setPublisherBulletinID: bulletinID];
			[bulletin setRecordID: bulletinID];
			BBSound* sound = [[BBSound alloc]initWithToneAlert:2];
			[bulletin setSound: sound];

			[bulletin setMessage:bulletinMessage];
			[bulletin setSubtitle:bulletinSubtitle];

			[bulletin setDate: bulletinDate];
			[bulletin setLastInterruptDate: bulletinDate];

			BBDataProviderAddBulletinForDestinations(self, bulletin, 2); //on iOs 8 this only shows an entry in the NC; not a banner

			[self->cachedBulletins setObject:bulletin forKey:bulletinID];

	}];
	[self saveCurrentlyShownBulletins];
}

-(void)dismissAllBulletins{
	[[self->cachedBulletins copy] enumerateKeysAndObjectsUsingBlock:^(NSString* bulletinID, BBBulletin* bulletin, BOOL* stop) {

       [self->cachedBulletins removeObjectForKey:bulletinID];
       [self->currentlyShownBulletins removeObjectForKey:bulletinID];
       [self->dismissedBulletins addObject:bulletinID];
       BBDataProviderWithdrawBulletinsWithRecordID(self, bulletinID);
    }];
    [self saveDismissed];
    [self saveCurrentlyShownBulletins];
}

-(void)updateBulletinsForPackages:(NSArray*)packages{
	for(NSDictionary* package_data in packages){
		NSString* bulletinID =  [NSString stringWithFormat:@"%@-v%@", package_data[@"Package"], package_data[@"Version"]];

		if(!([self->dismissedBulletins containsObject:bulletinID] || [self->currentlyShownBulletins objectForKey:bulletinID])){
			//we did not show it allready

			NSString* bulletinTitle = [NSString stringWithFormat:@"%@ Updated", package_data[@"Name"]];
			NSString* bulletinSubtitle = [NSString stringWithFormat:@"New version v%@", package_data[@"Version"]];
			NSString* bulletinMessage = package_data[@"Description"];	
			NSString* bulletinURLStr = [NSString stringWithFormat:@"cydia://package/%@", package_data[@"Package"]];
			NSDate* bulletinDate = [NSDate date];

			//Save that
			NSDictionary* bulletinData = @{@"title" : bulletinTitle, @"subtitle" : bulletinSubtitle, @"message" : bulletinMessage, @"urlString": bulletinURLStr, @"date" : bulletinDate};
			[self->currentlyShownBulletins setObject:bulletinData forKey:bulletinID];

			BBBulletinRequest* bulletin = [[BBBulletinRequest alloc]init];
			[bulletin setTitle:bulletinTitle];
			[bulletin setSectionID: @"com.saurik.Cydia"];
			NSURL* bulletinURL = [NSURL URLWithString:bulletinURLStr];
			BBAction* action = [BBAction actionWithLaunchURL:bulletinURL callblock:nil];
			[bulletin setDefaultAction:action];
			[bulletin setBulletinID: bulletinID];
			[bulletin setPublisherBulletinID: bulletinID];
			[bulletin setRecordID: bulletinID];
			BBSound* sound = [[BBSound alloc]initWithToneAlert:2];
			[bulletin setSound: sound];
			
			[bulletin setMessage:bulletinMessage];
			[bulletin setSubtitle:bulletinSubtitle];

			[bulletin setDate: bulletinDate];
			[bulletin setLastInterruptDate: bulletinDate];

			BBDataProviderAddBulletinForDestinations(self, bulletin, 78);
			[self->cachedBulletins setObject:bulletin forKey:bulletinID];
		}
	}
	[self saveCurrentlyShownBulletins];
}

#pragma mark apt helpers

-(NSArray*)getUpdates{
	NSDictionary* packagesWithUpdates = [self getPackagesWithUpdates];

	//save that. we need it for the preferences.
	NSArray* packageIdentifiers = [packagesWithUpdates allKeys];
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:CydiaNotifierPreferencePlistPath];
	NSMutableDictionary* mutableSettings = settings ? [settings mutableCopy] : [[NSMutableDictionary alloc]init];
	mutableSettings[@"packagesWithUpdates"] = packageIdentifiers;
	[mutableSettings writeToFile:CydiaNotifierPreferencePlistPath atomically:YES];


	__block NSMutableArray* packages = [[NSMutableArray alloc]init];
	[packagesWithUpdates enumerateKeysAndObjectsUsingBlock:^(NSString* package_identifier, NSString* version, BOOL* stop) {
	   NSDictionary* package_data = [self getPackageDetailsForIdentifier:package_identifier];
	   if(package_data){
	  	 [packages addObject:package_data];
	   }
	}];
	return packages;
}


-(NSDictionary*)getPackagesWithUpdates{
	FILE* f = popen("apt-get upgrade -s -qq -y -f", "r");

	NSMutableDictionary* packagesWithUpdates = [[NSMutableDictionary alloc]init];
	if (f != NULL) {
		//holds the line we're reading right now untill we reached the end of the line or EOF
		NSMutableData *lineBuffer = [[NSMutableData alloc]init];
		char buf[1025];
		size_t maxSize = (sizeof(buf) - 1);
		while (!feof(f)) {
			//as long as we didn't reach EOF
			if (fgets(buf, maxSize, f)) {
				buf[maxSize] = '\0';//make sure the string is 0 terminated!

				//check if we reached the end of the line
				char *lineBreakLocation = strrchr(buf, '\n');
				if (lineBreakLocation != NULL) {
					//we did find a line break. Add it to lineBuffer and we got the whole line
					[lineBuffer appendBytes:buf length:(NSUInteger)(lineBreakLocation - buf)];

					//the whole line is now in the buffer
					NSString *lineString = [[NSString alloc] initWithData:lineBuffer encoding:NSUTF8StringEncoding];

					if([lineString hasPrefix:@"Inst"]){
						//looks like this: Inst com.accuratweaks.common [0.1-2] (0.1-2 BigBoss:1.0/stable)
						//parse it
						NSArray* splittedString = [lineString componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
						NSString* package = splittedString[1];
						NSString* newVersion = [splittedString[3] substringFromIndex:1];
						if(package && newVersion){
							packagesWithUpdates[package] = newVersion;
						}
					}
					//reset the lineBuffer
					[lineBuffer setLength:0];
				} else {
					//we didn't reach the end of the line yet. Buffer everything
					[lineBuffer appendBytes:buf length:maxSize];
				}
			}
		}
	}
	pclose(f);
	return packagesWithUpdates;
}


-(NSDictionary*)getPackageDetailsForIdentifier:(NSString*)packageIdentifier{
	//gets deatil information for the package. Also, if two packages with teh same identifier are available (one installed from local, one available on a repor for example), the one with the heighest version is used.
    NSString* dpkgQuery = [[NSString alloc] initWithFormat:@"apt-cache show \"%@\"", packageIdentifier];
    FILE* f = popen([dpkgQuery UTF8String], "r");

    NSMutableDictionary* packageDetail = [NSMutableDictionary dictionary];
    if (f != NULL) {
    	//holds the line we're reading right now untill we reached the end of the line or EOF
        NSMutableData *lineBuffer = [[NSMutableData alloc]init];
	    char buf[1025];
	    size_t maxSize = (sizeof(buf) - 1);
	    while (!feof(f)) {
	    	//as long as we didn't reach EOF
	        if (fgets(buf, maxSize, f)) {
	            buf[maxSize] = '\0';//make sure the string is 0 terminated!

	            //check if we reached the end of the line
	            char *lineBreakLocation = strrchr(buf, '\n');
	            if (lineBreakLocation != NULL) {
	            	//we did find a line break. Add it to lineBuffer and we got the whole line
	                [lineBuffer appendBytes:buf length:(NSUInteger)(lineBreakLocation - buf)];

	                //the whole line is now in the buffer
	                NSString *lineString = [[NSString alloc] initWithData:lineBuffer encoding:NSUTF8StringEncoding];


	                if([lineString length] == 0){
	                	//it's the end of a package.
	                	break;
	                }else{
	                	 //check if we got a key and a value
		                NSUInteger firstColon = [lineString rangeOfString:@":"].location;
		                if (firstColon != NSNotFound) {
		                    NSUInteger length = [lineString length];
		                    //check if value is not empty
		                    if (length > (firstColon + 1)) {
		                        NSString *key = [lineString substringToIndex:firstColon];
		                        NSString *value = [lineString substringFromIndex:(firstColon + 1)];
		                        //remove any whitespaces from value
		                        value = [value stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
		                        if ([value length] > 0) {
		                            [packageDetail setObject:value forKey:key];
		                        }
		                    }
		                }
	                }
	                //reset the lineBuffer
	                [lineBuffer setLength:0];
	            } else {
	            	//we didn't reach the end of the line yet. Buffer everything
	                [lineBuffer appendBytes:buf length:maxSize];
	            }
	        }
	    }
    }
	pclose(f);
	if(!packageDetail[@"Package"])
		//only return a dict if we got an entry!
		packageDetail = nil;

	return packageDetail;
}

#pragma mark libactivator
- (void)activator:(LAActivator *)activator didChangeToEventMode:(NSString *)eventMode {
	//this is called whenever the event mode is changed - to lockscreen, springboard or application. Good enough to cehck the passed time here
	if(![eventMode isEqualToString:@"lockscreen"]){
		//no refresh on lockscreen
		if(CNEnableAutoRefresh){
			BOOL mayProceed = true;
			if(CNAutorefreshRequiresWiFi){
				SBWiFiManager* wifiManger = (SBWiFiManager*)[NSClassFromString(@"SBWiFiManager") sharedInstance];
				mayProceed = [wifiManger isAssociated];
			}
			if(mayProceed){
				double secondsAfterLastRefresh = [[NSDate date] timeIntervalSinceReferenceDate] - lastUpdateTime;
				if(secondsAfterLastRefresh > CNAutoRefreshIntervalSeconds){
					[self refreshAndUpdate];
				}
			}
		}
	}
}

- (void)activator:(LAActivator *)activator receiveEvent:(LAEvent *)event forListenerName:(NSString *)listenerName {
	// Called when we receive an event - eg the action that was assigned to cydiaNotifier was "done"
	if (!self.isWorking) {
		[self refreshAndUpdate];
		[event setHandled:YES];
	}
}

#pragma mark preferences
-(void)reloadPreferences{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:CydiaNotifierPreferencePlistPath];

	CNEnableAutoRefresh = settings[@"CNEnableAutoRefresh"] ? [settings[@"CNEnableAutoRefresh"] boolValue] : TRUE;
	CNAutoRefreshInterval = settings[@"CNAutoRefreshInterval"] ? [settings[@"CNAutoRefreshInterval"] intValue] : 3;
	CNAutorefreshRequiresWiFi =  settings[@"CNAutorefreshRequiresWiFi"] ? [settings[@"CNAutorefreshRequiresWiFi"] boolValue] : FALSE;

	if(CNAutoRefreshInterval < 0 || CNAutoRefreshInterval > 6 )
		CNAutoRefreshInterval = 3;
	NSArray* refreshIntervalMap = @[@(60), @(7200), @(10800), @(21600), @(43200), @(86400), @(172800)];
	CNAutoRefreshIntervalSeconds = [refreshIntervalMap[CNAutoRefreshInterval] doubleValue];

	dismissedBulletins = [settings[@"dismissedBulletins"] isKindOfClass:[NSArray class]] ? [settings[@"dismissedBulletins"] mutableCopy] : [[NSMutableArray alloc]init];
	currentlyShownBulletins = [settings[@"currentlyShownBulletins"] isKindOfClass:[NSDictionary class]] ? [settings[@"currentlyShownBulletins"] mutableCopy]: [[NSMutableDictionary alloc]init];
	[self reloadLastUpdateTime];
}

-(void)reloadLastUpdateTime{
	//loads it from the plist that cydia uses too. Important, so we respect cydias last refresh, and cydia respects ours.
	NSDictionary* cydiaMetadata = [NSDictionary dictionaryWithContentsOfFile: @"/var/lib/cydia/metadata.plist"];
	id lastUpdate = cydiaMetadata[@"LastUpdate"];
	if ([lastUpdate isKindOfClass: [NSDate class]]){
		self->lastUpdateTime = [lastUpdate timeIntervalSinceReferenceDate];
	}
}

-(void)saveDismissed{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:CydiaNotifierPreferencePlistPath];
	NSMutableDictionary* mutableSettings = settings ? [settings mutableCopy] : [[NSMutableDictionary alloc]init];

	mutableSettings[@"dismissedBulletins"] = self->dismissedBulletins;
	[mutableSettings writeToFile:CydiaNotifierPreferencePlistPath atomically:YES];
}

-(void)saveCurrentlyShownBulletins{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:CydiaNotifierPreferencePlistPath];
	NSMutableDictionary* mutableSettings = settings ? [settings mutableCopy] : [[NSMutableDictionary alloc]init];

	mutableSettings[@"currentlyShownBulletins"] = self->currentlyShownBulletins;
	[mutableSettings writeToFile:CydiaNotifierPreferencePlistPath atomically:YES];
}
@end