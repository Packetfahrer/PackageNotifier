#import <substrate.h>
#import <UIKit/UIKit.h>
#import <Preferences/Preferences.h>
#import <objc/runtime.h>
#import <ATCommon/ATPackageInfo.h>
#import <ATCommon/UIColor+ATExtension.h>
#import <ATCommon/UIImage+ATExtension.h>
#import <ATCommon/ATPackageInfo.h>
#import "./PackageNotifierProvider/PackageNotifierProvider.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)

@interface PSListController (libprefs)
//preferenceloader methods
- (NSArray *)specifiersFromEntry:(NSDictionary *)entry sourcePreferenceLoaderBundlePath:(NSString *)sourceBundlePath title:(NSString *)title;
- (PSViewController*)controllerForSpecifier:(PSSpecifier*)specifier;
//new method added by us
-(NSString *)identifierForPackageContainingFile:(NSString *)filepath;
@end

//array to keep track of the hooked classes
static NSMutableArray* hookedClasses = [[NSMutableArray alloc]init];

//array of original "specifiers" method implementation
static IMP* orig_PSListController_specifiers;
static int orig_PSListController_specifiers_size = 0;
static int orig_PSListController_specifiers_used = 0;

static NSArray* packagesWithUpdates;
static NSMutableDictionary* packageIdentifierCache;

//Package Notifier Settings values
static BOOL PNEnableBadges;
static BOOL PNEnableAdaptiveBadgeColor;
static NSString* PNBadgeColor;
static NSString* PNBadgeTextColor;
static BOOL PNEnableBadgeBorder;
static NSString* PNBadgeAlignment;
static NSString* PNCustomBadgeText;

//if an update is available, insert an "install the new update" cell at the top of the preferences
static NSArray* replaced_PSListController_specifiers(PSListController* self, SEL _cmd){
	bool haveToInsert = (MSHookIvar<NSArray*>(self, "_specifiers") == nil);
	PSSpecifier* parentSpecifier = MSHookIvar<PSSpecifier*>(self, "_specifier");
	int i = [hookedClasses indexOfObject:[self class]];
	NSArray* _specifiers = orig_PSListController_specifiers[i](self, _cmd);

	if(haveToInsert && _specifiers){
		NSString* packageIdentifier = parentSpecifier.properties[@"packageIdentifier"];
		if(packageIdentifier && [packagesWithUpdates containsObject:packageIdentifier]){
			//we got a new update
			PSSpecifier* groupSpecifier1 = [PSSpecifier emptyGroupSpecifier];
			[groupSpecifier1 setProperty:@"ATPSEmptyHeaderView" forKey:@"headerCellClass"];
			if([_specifiers count] > 0){
				PSSpecifier* firstSpecifier = (PSSpecifier*)[_specifiers objectAtIndex:0];
				if([firstSpecifier.properties[@"headerCellClass"] isEqualToString:@"ATPSEmptyHeaderView"]){
					//support for QRMode and CallEnhancer with use ATPSEmptyHeaderView
					[groupSpecifier1 setProperty:@"ATPSEmptyHeaderView" forKey:@"footerCellClass"];
				}
			}

			PSSpecifier *installUpdateSpecifier = [PSTextFieldSpecifier preferenceSpecifierNamed:@"Install the new update"
															  target:self
															  set:nil
															  get:nil
															  detail:nil
															  cell:[PSTableCell cellTypeFromString:@"PSLinkCell"]
															  edit:nil];

			[installUpdateSpecifier setProperty:@"red" forKey:@"backgroundColor"];
			[installUpdateSpecifier setProperty:@"white" forKey:@"textColor"];
			NSString* iconPath = @"/Library/Application Support/PackageNotifier/Icons/gear-white.png";
			[installUpdateSpecifier setProperty:[UIImage imageNamed:iconPath] forKey:@"iconImage"];
			[installUpdateSpecifier setProperty:NSClassFromString(@"ATPSColoredTableCell") forKey:@"cellClass"];
			installUpdateSpecifier->action = @selector(packageNotifier_installUpdate);

			PSSpecifier* groupSpecifier2 = [PSSpecifier emptyGroupSpecifier];

			NSMutableArray* newSpecifiers = [_specifiers mutableCopy];
			[newSpecifiers insertObject: groupSpecifier1 atIndex:0];
			[newSpecifiers insertObject: installUpdateSpecifier atIndex:1];

			if([newSpecifiers count] > 3 && ((PSSpecifier*)[newSpecifiers objectAtIndex:2])->cellType != PSGroupCell){
				//we need space between our cell and the original content!
				[newSpecifiers insertObject: groupSpecifier2 atIndex:2];
			}

			[_specifiers release];
			MSHookIvar<NSArray*>(self, "_specifiers") = newSpecifiers;
			_specifiers = newSpecifiers;
		}
		[packageIdentifier release];
	}
	return _specifiers;
}

//called when taped on said cell
static void installUpdate(PSListController* self, SEL _cmd){
	//todo: cache this information
	ATPackageInfo* packageInfo = [[ATPackageInfo alloc]initWithPackageFilePath:[self.bundle bundlePath]];
	NSString* packageIdentifier = packageInfo.packageIdentifier;
	[packageInfo release];
	NSURL* cydiaURL = [NSURL URLWithString:[NSString stringWithFormat:@"cydia://package/%@", packageIdentifier]];
	[[UIApplication sharedApplication] openURL:cydiaURL];
}


%group PreferencesHook


%hook PSListController

- (NSArray *)specifiersFromEntry:(NSDictionary *)entry sourcePreferenceLoaderBundlePath:(NSString *)sourceBundlePath title:(NSString *)title {
	NSString* plistPath = [NSString stringWithFormat:@"%@/%@.plist", sourceBundlePath, title];
	//ATPackageInfo* packageInfo = [[ATPackageInfo alloc]initWithPackageFilePath:plistPath];
	NSString* packageIdentifier = [self identifierForPackageContainingFile:plistPath];
	//[packageInfo release];

	NSArray* specifiers = %orig(entry, sourceBundlePath, title);
	if([packagesWithUpdates containsObject:packageIdentifier]){
		PSSpecifier* specifier = specifiers[0];
		if(specifier){
			//add the update badge
			[specifier setProperty:packageIdentifier forKey:@"packageIdentifier"];

			[specifier setProperty:%c(ATPSBadgeTableCell) forKey:@"cellClass"];
			[specifier setProperty:PNBadgeAlignment forKey:@"badgeAlignment"];
			[specifier setProperty:PNBadgeTextColor forKey:@"badgeTextColor"];
			[specifier setProperty:PNBadgeColor forKey:@"badgeColor"];
			[specifier setProperty:PNCustomBadgeText forKey:@"badgeString"];
			if(PNEnableBadgeBorder){
				[specifier setProperty:@(0.5) forKey:@"badgeBorderWidth"];
				[specifier setProperty:@"black" forKey:@"badgeBorderColor"];
			}

			if(PNEnableAdaptiveBadgeColor){
				UIImage* iconImage = specifier.properties[@"iconImage"];
				if(iconImage){
					UIColor* imageMainColor = [iconImage ATMainColor];
					[specifier setProperty:imageMainColor forKey:@"badgeColor"];
					NSString* textColor = ([imageMainColor ATBrightness] > 0.8) ? @"black" : @"white";
					[specifier setProperty:textColor forKey:@"badgeTextColor"];
					
					//add a border if nessesary.
					NSString* borderColor = ([imageMainColor ATBrightness] > 0.8) ? @"black" : @"white";
					[specifier setProperty:borderColor forKey:@"badgeBorderColor"];
					[specifier setProperty:@(0.5) forKey:@"badgeBorderWidth"];
				}
			}
		}
	}
	return specifiers;
}

- (PSViewController*)controllerForSpecifier:(PSSpecifier*)specifier{
	id retVal = %orig;
	if([retVal isKindOfClass:[PSListController class]]){
		Class _class = [retVal class];
		if(![hookedClasses containsObject:_class]){
			//hook the PSListController (sub)class of the preferences bundle
			[hookedClasses addObject:_class];
			int i = [hookedClasses indexOfObject:_class];
			MSHookMessageEx(_class, @selector(specifiers), (IMP)replaced_PSListController_specifiers, (IMP *)&orig_PSListController_specifiers[i]);
			//add the installUpdate method
			class_addMethod(_class, @selector(packageNotifier_installUpdate), (IMP)installUpdate, "v:");+
			//increase counter 
			orig_PSListController_specifiers_used+= 1;
			if(orig_PSListController_specifiers_used == orig_PSListController_specifiers_size){
				//we are out of space. allocate more. 50 is maybe an overkill tho...
				orig_PSListController_specifiers = (IMP *)realloc(orig_PSListController_specifiers, 50*sizeof(IMP) + orig_PSListController_specifiers_size*sizeof(IMP));
				orig_PSListController_specifiers_used += 50;
			}
		}
	}
	return retVal;
}

//issue here: when user had a pirated version of some package installed, and buys the original version, the cached package identifier is wrong. 
%new
-(NSString *)identifierForPackageContainingFile:(NSString *)filepath{
	//cache the packages for specific file paths, as reuqests take time and may come frequest
	
	if([packageIdentifierCache objectForKey:filepath]){
		//if the package is in cache, use that.
		return [packageIdentifierCache objectForKey:filepath];
	}
	NSString *packageIdentifier = nil;
	
	NSString* dpkgQuery = [NSString stringWithFormat:@"dpkg-query -S \"%@\" | head -1", filepath];
	FILE *f = popen([dpkgQuery UTF8String], "r");
	if (f != NULL) {
	// Read until : is hit.
	NSMutableData *packageIdentifierBuffer = [[NSMutableData alloc]init];
	char buf[1025];
	size_t bufferSize = (sizeof(buf) - 1);
	while (!feof(f)) {
		//read as many chars as possible, but not more as fit in the buffer
		size_t readSize = fread(buf, 1, bufferSize, f);
		buf[readSize] = '\0';//make sure the buffer is 0 terminated
		
		size_t packageIdentifierSize = strcspn(buf, ":");//output looks like this: me.simonselg.qrmode: /Library/MobileSubstrate/DynamicLibraries/QRMode.dylib
		[packageIdentifierBuffer appendBytes:buf length:packageIdentifierSize];
		if (packageIdentifierSize != bufferSize) {
			//we found something - no need to read more.
		break;
		}
	}
	if ([packageIdentifierBuffer length] > 0) {
		//if we found something
		packageIdentifier = [[NSString alloc] initWithData:packageIdentifierBuffer encoding:NSUTF8StringEncoding];
	}
	pclose(f);
	[packageIdentifierBuffer release];
	}
	
	//now compare if the "Package identifier" was dpkg - in that case it's not a hit (dpkg: file not found or somethign, don't remember!)
	if([packageIdentifier isEqualToString:@"dpkg"]){
		packageIdentifier = nil;
	}else if(packageIdentifier){
		//cache the result
		packageIdentifierCache[filepath] = packageIdentifier;
		NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PackageNotifierPreferencePlistPath];
		NSMutableDictionary* mutableSettings = settings ? [settings mutableCopy] : [[NSMutableDictionary alloc]init];
	
		mutableSettings[@"packageIdentifierCache"] = packageIdentifierCache;
		[mutableSettings writeToFile:PackageNotifierPreferencePlistPath atomically:YES];
		[mutableSettings release];
	}
	
	return packageIdentifier;
}

%end
%end


%group PreferencesHook_iOS7
%hook UITableView
%new
-(UIScrollView*)_wrapperView{
	return MSHookIvar<UIScrollView*>(self, "_wrapperView");
}
%end
%end

@interface SBApplicationIcon : NSObject
-(void)launchFromLocation:(int)arg1 ;
-(id)leafIdentifier;
@end

@interface SBApplication : NSObject
-(NSString*)bundleIdentifier;
@end

%group SpringBoardHooks_iOS8
%hook SBApplication
-(void)processWillLaunch:(id)arg1{
	if([[self bundleIdentifier]isEqualToString:@"com.saurik.Cydia"]){
		//we are launching cydia! Stop refresh (if refreshing) and dismiss all bulletins. 
		PackageNotifierProvider* notifierProvider = [%c(PackageNotifierProvider) sharedProvider];
		if(notifierProvider.isWorking){
			[notifierProvider cancelRefresh];
		}
		[notifierProvider dismissAllBulletins];
	}
	%orig;
}
-(void)didExitWithType:(int)arg1 terminationReason:(long long)arg2{
	%orig;
	if([[self bundleIdentifier]isEqualToString:@"com.saurik.Cydia"]){
		//cydia closed. Reload last update time and available updates (without refreshing, just to refresh the badge on the cydia icon and the plist).
		PackageNotifierProvider* notifierProvider = [%c(PackageNotifierProvider) sharedProvider];
		//reload the packages with updates.
		[notifierProvider reloadLastUpdateTime];
		[notifierProvider reloadPackagesWithUpdates];
	}
}
%end
%end

%group SpringBoardHooks_iOS7
%hook SBApplication
-(void)didBeginLaunch:(id)arg1{
	if([[self bundleIdentifier]isEqualToString:@"com.saurik.Cydia"]){
		//we are launching cydia! Stop refresh (if refreshing) and dismiss all bulletins. 
		PackageNotifierProvider* notifierProvider = [%c(PackageNotifierProvider) sharedProvider];
		if(notifierProvider.isWorking){
			[notifierProvider cancelRefresh];
		}
		[notifierProvider dismissAllBulletins];
	}
	%orig;
}

-(void)didExitWithInfo:(id)arg1 type:(int)arg2{
	%orig;
	if([[self bundleIdentifier]isEqualToString:@"com.saurik.Cydia"]){
		//cydia closed. Reload last update time and available updates (without refreshing, just to refresh the badge on the cydia icon and the plist).
		PackageNotifierProvider* notifierProvider = [%c(PackageNotifierProvider) sharedProvider];
		//reload the packages with updates.
		[notifierProvider reloadLastUpdateTime];
		[notifierProvider reloadPackagesWithUpdates];
	}
}
%end
%end

#pragma mark preferences
static void reloadPreferences(){
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:PackageNotifierPreferencePlistPath];
	packagesWithUpdates = settings[@"packagesWithUpdates"] ? settings[@"packagesWithUpdates"] : [[NSArray alloc]init];
	packageIdentifierCache = settings[@"packageIdentifierCache"] ? [settings[@"packageIdentifierCache"] mutableCopy] : [[NSMutableDictionary alloc]init];

	PNEnableBadges = settings[@"PNEnableBadges"] ? [settings[@"PNEnableBadges"] boolValue] : TRUE;
	PNEnableAdaptiveBadgeColor = settings[@"PNEnableAdaptiveBadgeColor"] ? [settings[@"PNEnableAdaptiveBadgeColor"] boolValue] : TRUE;
	PNBadgeColor = settings[@"PNBadgeColor"] ?: @"red";
	PNBadgeTextColor = settings[@"PNBadgeTextColor"] ?: @"white";
	PNEnableBadgeBorder = settings[@"PNEnableBadgeBorder"] ? [settings[@"PNEnableBadgeBorder"] boolValue] : FALSE;
	PNBadgeAlignment = settings[@"PNBadgeAlignment"] ?: @"right";
	PNCustomBadgeText = settings[@"PNCustomBadgeText"] ?: @"Update available!";
	if([PNCustomBadgeText isEqualToString:@""]){
		PNCustomBadgeText = @"Update available!";
	}

}


/*//Enable BulletinBoard Logging
/*static Boolean (*orig_CFPreferencesGetAppBooleanValue)( CFStringRef key, CFStringRef applicationID, Boolean *keyExistsAndHasValidFormat );
Boolean replaced_CFPreferencesGetAppBooleanValue( CFStringRef key, CFStringRef applicationID, Boolean *keyExistsAndHasValidFormat ) {
	if([((NSString*)key) hasPrefix:@"BB"]){
		return YES;
	}
	return orig_CFPreferencesGetAppBooleanValue(key, applicationID, keyExistsAndHasValidFormat);
}*/

%ctor{

	//
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.springboard"]){
		/*Enable BulletinBoard Logging
		MSHookFunction(CFPreferencesGetAppBooleanValue, replaced_CFPreferencesGetAppBooleanValue, &orig_CFPreferencesGetAppBooleanValue);*/
		CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), nil, (CFNotificationCallback)reloadPreferences, CFSTR("com.accuratweaks.packagenotifier/prefschanged"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
		//%init(SpringBoardHooks);
		if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"8.0")){
			%init(SpringBoardHooks_iOS8);
		}
		else{
			//iOS 7 for now
			%init(SpringBoardHooks_iOS7);
		}
	}
	if ([[[NSBundle mainBundle] bundleIdentifier] isEqualToString:@"com.apple.Preferences"]){
		orig_PSListController_specifiers = (IMP *)malloc(50*sizeof(IMP));
		orig_PSListController_specifiers_size = 50;
		orig_PSListController_specifiers_used = 0;
		dlopen("/Library/MobileSubstrate/DynamicLibraries/PreferenceLoader.dylib", RTLD_LAZY);
		dlopen("/usr/lib/libatcommonprefs.dylib", RTLD_LAZY);
		reloadPreferences();
		if(PNEnableBadges){
			%init(PreferencesHook);
		}

		//make iOS 7 compatible with my preferences for now
		if(SYSTEM_VERSION_LESS_THAN(@"8.0")){
			%init(PreferencesHook_iOS7);
		}
	}
}
