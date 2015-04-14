#import <Preferences/Preferences.h>
#import <ATCommonPrefs/ATPSTableCell.h>
#define PackageNotifierPreferencePlistPath @"/User/Library/Preferences/com.accuratweaks.packagenotifier.plist"


@interface PackageNotifierPromotionPreferences: PSListController<UIWebViewDelegate>
@property(nonatomic)UIWebView* sizeCalculationView;
@property(nonatomic)PSSpecifier* loadingSpecifier;
@end