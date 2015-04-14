#import "BBDataProvider-Protocol.h"
#import <Foundation/Foundation.h>
#import <BulletinBoard/BBSectionInfo.h>
#import <BulletinBoard/BBBulletinRequest.h>
#import <BulletinBoard/BBAction.h>
#import <BulletinBoard/BBSound.h>
#import <libactivator/libactivator.h>
#import <spawn.h>
#import <notify.h>

#define PackageNotifierPreferencePlistPath @"/User/Library/Preferences/com.accuratweaks.packagenotifier.plist"

@interface SBWiFiManager : NSObject
+(id)sharedInstance;
-(BOOL)isAssociated;
@end

@interface PackageNotifierProvider : NSObject <BBDataProvider, LAListener>{
	NSMutableDictionary *cachedBulletins;
	int status_token;
	//prefs
	BOOL PNEnableAutoRefresh;
	int PNAutoRefreshInterval;
	BOOL PNAutorefreshRequiresWiFi;

	double PNAutoRefreshIntervalSeconds;

	double lastUpdateTime;

	NSMutableArray* dismissedBulletins;
	NSMutableDictionary* currentlyShownBulletins;
}
@property(nonatomic) BOOL isWorking;
+ (PackageNotifierProvider*)sharedProvider;
-(void)refreshAndUpdate;
-(void)cancelRefresh;
-(void)reloadPreferences;
-(void)dismissAllBulletins;
-(void)reloadPackagesWithUpdates;
-(void)reloadLastUpdateTime;
@end
