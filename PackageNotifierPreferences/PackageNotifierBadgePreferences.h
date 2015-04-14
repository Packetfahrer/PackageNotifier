#import <Preferences/Preferences.h>
#import <ATCommonPrefs/ATPSTableCell.h>
#define PackageNotifierPreferencePlistPath @"/User/Library/Preferences/com.accuratweaks.packagenotifier.plist"


@interface PackageNotifierBadgePreferencesListController: PSListController {
	int status_token;
	NSMutableArray* _enableGroupSpecifiers;

	PSSpecifier* _enableGroupSpecifier;
	PSSpecifier* _badgeColorGroupSpecifier;
	PSSpecifier* _badgeColorSpecifier;
	PSSpecifier* _badgeTextColorGroupSpecifier;
	PSSpecifier* _badgeTextColorSpecifier;
}
@end
