#import <Preferences/Preferences.h>
#import <ATCommonPrefs/ATPSTableCell.h>
#define CydiaNotifierPreferencePlistPath @"/User/Library/Preferences/com.accuratweaks.cydianotifier.plist"


@interface CydiaNotifierPromotionPreferences: PSListController<UIWebViewDelegate>
@property(nonatomic)UIWebView* sizeCalculationView;
@property(nonatomic)PSSpecifier* loadingSpecifier;
@end