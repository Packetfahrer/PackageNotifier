#import "BBDataProvider-Protocol.h"
#import <Foundation/Foundation.h>
#import <BulletinBoard/BBSectionInfo.h>
#import <BulletinBoard/BBBulletinRequest.h>
#import <BulletinBoard/BBAction.h>
#import <BulletinBoard/BBSound.h>
#import <libactivator/libactivator.h>
#import <spawn.h>
#import <notify.h>

#define CydiaNotifierPreferencePlistPath @"/User/Library/Preferences/com.accuratweaks.cydianotifier.plist"

@interface SBWiFiManager : NSObject
+(id)sharedInstance;
-(BOOL)isAssociated;
@end

@interface CydiaNotifierProvider : NSObject <BBDataProvider, LAListener>{
	NSMutableDictionary *cachedBulletins;
	int status_token;
	//prefs
	BOOL CNEnableAutoRefresh;
	int CNAutoRefreshInterval;
	BOOL CNAutorefreshRequiresWiFi;

	double CNAutoRefreshIntervalSeconds;

	double lastUpdateTime; //this is either cydia or cydiaNotifier

	NSMutableArray* dismissedBulletins;
	NSMutableDictionary* currentlyShownBulletins;
}
@property(nonatomic) BOOL isWorking;
+ (CydiaNotifierProvider*)sharedProvider;
-(void)refreshAndUpdate;
-(void)cancelRefresh;
-(void)reloadPreferences;
-(void)dismissAllBulletins;
-(void)reloadPackagesWithUpdates;
-(void)reloadLastUpdateTime;
@end
