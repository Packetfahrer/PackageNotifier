#import <Preferences/Preferences.h>
#import <ATCommonPrefs/ATPSTableCell.h>
#define CydiaNotifierPreferencePlistPath @"/User/Library/Preferences/com.accuratweaks.cydianotifier.plist"


@interface CydiaNotifierBadgePreferencesListController: PSListController {
	int status_token;
	NSMutableArray* _enableGroupSpecifiers;

	PSSpecifier* _enableGroupSpecifier;
	PSSpecifier* _badgeColorGroupSpecifier;
	PSSpecifier* _badgeColorSpecifier;
	PSSpecifier* _badgeTextColorGroupSpecifier;
	PSSpecifier* _badgeTextColorSpecifier;
}
@end
