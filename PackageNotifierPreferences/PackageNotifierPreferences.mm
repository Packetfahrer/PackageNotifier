#import <Preferences/Preferences.h>
#import <ATCommonPrefs/ATPSTableCell.h>
#import <notify.h>
#import <Twitter/Twitter.h>
#import <MessageUI/MFMailComposeViewController.h>
#import <Social/Social.h>
#import <ATCommon/ATSupportInfo.h>
#define kPackageNotifierPreferencePlistPath @"/User/Library/Preferences/com.accuratweaks.packagenotifier.plist"
#define kPackageNotifierSupportMailAddress @"packagenotifier@accuratweaks.com"


@interface PackageNotifierPreferencesListController: PSListController<MFMailComposeViewControllerDelegate> {
	int status_token;
}

-(void)updateRefreshButton;
@end

void status_callback(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	[((__bridge PackageNotifierPreferencesListController*)observer) updateRefreshButton];
}

@implementation PackageNotifierPreferencesListController
-(id)init{
	self = [super init];
	if(self){
		notify_register_check("com.accuratweaks.packagenotifier/status", &self->status_token);
	}
	return self;
}
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"PackageNotifierPreferences" target:self];
	}
	return _specifiers;
}

-(void)viewDidLoad{
	[super viewDidLoad];
	NSString *headerImagePath = [NSString stringWithFormat:@"%@/%@", [self bundle].bundlePath, @"accuraLogoNavBar.png"];
	UIImage *icon = [[UIImage alloc] initWithContentsOfFile:headerImagePath];
	UIImageView *iconView = [[UIImageView alloc] initWithImage:icon];
	self.navigationItem.titleView = iconView;

	NSString *loveIconPath = [NSString stringWithFormat:@"%@/%@", [self bundle].bundlePath, @"heart.png"];
	UIBarButtonItem *showLove = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:loveIconPath] style:UIBarButtonItemStylePlain target:self action:@selector(showLove)];

	self.navigationItem.rightBarButtonItem = showLove;
	[self.navigationItem.rightBarButtonItem setEnabled:YES];
}


-(void)showLove{
	SLComposeViewController *controllerSLC = [SLComposeViewController composeViewControllerForServiceType:SLServiceTypeTwitter];
	[controllerSLC setInitialText:@"I'm loving #PackageNotifier by @AccuraTweaks - check it out: http://accuratweaks.com/package-notifier.html"];
	[self presentViewController:controllerSLC animated:YES completion:Nil];
}

- (void)sendSupportEmail {
	if (![MFMailComposeViewController canSendMail] ) {
		UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"No mail accounts are set up."
			message:@"Please go to the Mail settings to add a new account."
			delegate:nil cancelButtonTitle:@"OK"
			otherButtonTitles:nil];

		[alertView show];

		return;
	}

	ATSupportInfo* supportInfo = [[ATSupportInfo alloc]initWithPackageFilePath:[self.bundle bundlePath]];
	MFMailComposeViewController *viewController = [[MFMailComposeViewController alloc] init];
	viewController.mailComposeDelegate = self;
	viewController.toRecipients = @[kPackageNotifierSupportMailAddress];
	viewController.subject = [supportInfo mailSubject];

	[viewController setMessageBody:@"\n\n---------------------------------------\nWe attached some information about your Package Notifier Preferences and your device here. This will help us solve your problem more quickly." isHTML:NO];
	[viewController addAttachmentData:[supportInfo supportAttachmentDataForPreferencePath:kPackageNotifierPreferencePlistPath] mimeType:@"application/x-plist" fileName:@"Information.plist"];

	[self.navigationController.navigationController presentViewController:viewController animated:YES completion:nil];
}

-(void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error{
	[self dismissViewControllerAnimated:YES completion:nil];
}

-(void) viewWillAppear:(BOOL)animated{
	[super viewWillAppear:animated];
	[self updateRefreshButton];

	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), (const void*)self, status_callback, CFSTR("com.accuratweaks.packagenotifier/status"), NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
	[[NSNotificationCenter defaultCenter] addObserver: self
										 selector: @selector(handleEnterForeground:)
											 name: UIApplicationWillEnterForegroundNotification
										   object: nil];
}

-(void) viewWillDisappear:(BOOL)animated{
	[super viewWillDisappear:animated];
	//remove it. Curiosa doesn't, which leads to crashes.
	CFNotificationCenterRemoveObserver (CFNotificationCenterGetDarwinNotifyCenter(), (const void*)self, CFSTR("com.accuratweaks.packagenotifier/status"), NULL);
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)handleEnterForeground:(NSNotification*)notification{
	[self updateRefreshButton];
}


-(void)updateRefreshButton{
	NSString *buttonTitle;
	NSString *buttonStatus;
	PSSpecifier* refresh_button_specifier;
	PSSpecifier* refresh_group_specifier;
	NSString* refresh_group_footerText;
	uint64_t state = 0;

	notify_get_state(self->status_token, &state);
	if (state){
		buttonTitle = @"Cancel refresh";
		buttonStatus = @"Refreshing package list...";
	}else{
		buttonTitle = @"Manual Refresh";
	}
	refresh_button_specifier = [self specifierForID: @"REFRESH_BUTTON"];
	NSString* buttonCurrentTitle = [refresh_button_specifier name];
	if (![buttonCurrentTitle isEqualToString: buttonTitle]){
		[refresh_button_specifier setName: buttonTitle];
		[self reloadSpecifier: refresh_button_specifier];
	}
	refresh_group_specifier = [self specifierForID: @"REFRESH_GROUP"];
	refresh_group_footerText = [refresh_group_specifier propertyForKey: @"footerText"];
	if (![refresh_group_footerText isEqualToString: buttonStatus]){
		if (buttonStatus){
			refresh_group_specifier.properties[@"footerText"] = buttonStatus;
		}
		else{
			[refresh_group_specifier removePropertyForKey: @"footerText"];
		}
		[self reloadSpecifier:refresh_group_specifier];
	}
}

/*-(void)deleteShowNotifications{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kPackageNotifierPreferencePlistPath];
	NSMutableDictionary* mutableSettings = settings ? [settings mutableCopy] : [[NSMutableDictionary alloc]init];
	mutableSettings[@"dismissedBulletins"] = @[];
	[mutableSettings writeToFile:kPackageNotifierPreferencePlistPath atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.accuratweaks.packagenotifier/prefschanged"), NULL, NULL, YES);
}

-(void)deletePackageIdentifierCache{
	NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:kPackageNotifierPreferencePlistPath];
	NSMutableDictionary* mutableSettings = settings ? [settings mutableCopy] : [[NSMutableDictionary alloc]init];
	mutableSettings[@"packageIdentifierCache"] = @{};
	[mutableSettings writeToFile:kPackageNotifierPreferencePlistPath atomically:YES];
	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), CFSTR("com.accuratweaks.packagenotifier/prefschanged"), NULL, NULL, YES);
}*/

-(void) toggleSourcesRefresh{
	uint64_t state;
	notify_get_state(self->status_token, &state);
	if ( state == 1 ){
		notify_post("com.accuratweaks.packagenotifier/cancel");
	}else if ( state == 0 ){
		notify_post("com.accuratweaks.packagenotifier/refresh");
	}
}

#pragma mark ATCommonPSTableCell

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	PSSpecifier* specifier = [self specifierAtIndex:[self indexForIndexPath:indexPath]];
	NSNumber* dynamicHeight = [specifier.properties objectForKey:@"dynamicHeight"];
	if(dynamicHeight && [dynamicHeight boolValue]){
		UITableViewCell<ATPSTableCell>* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
		return [cell preferredHeightForWidth:tableView._wrapperView.frame.size.width];
	}

		return [super tableView:tableView heightForRowAtIndexPath:indexPath];

}



#pragma mark plist save/read methods to ensure ios8-compatiblity

-(id) readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *exampleTweakSettings = [NSDictionary dictionaryWithContentsOfFile:kPackageNotifierPreferencePlistPath];
	if (!exampleTweakSettings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return exampleTweakSettings[specifier.properties[@"key"]];
}

-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kPackageNotifierPreferencePlistPath]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:kPackageNotifierPreferencePlistPath atomically:YES];
	CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
	if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}
@end
