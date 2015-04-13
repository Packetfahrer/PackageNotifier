#import <Preferences/Preferences.h>
#import <ATCommonPrefs/ATPSTableCell.h>
#import <notify.h>
#import "CNTimeSelectionCell.h"
#define kCydiaNotifierPreferencePlistPath @"/User/Library/Preferences/com.accuratweaks.cydianotifier.plist"


@interface CydiaNotifierAutoRefreshPreferencesListController: PSListController {
	PSSpecifier* _timeSelectionSpecifier;
	PSSpecifier* _requiresWiFiSpecifier;
}
@end


@implementation CydiaNotifierAutoRefreshPreferencesListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"CydiaNotifierAutoRefreshPreferences" target:self];
		PSSpecifier* autoRefreshEnabled = [self specifierForID:@"AUTO_REFRESH_ENABLED"];
		_timeSelectionSpecifier = [self specifierForID:@"FREQUENCY_SELECTION_CELLS"];
		_requiresWiFiSpecifier = [self specifierForID:@"REQUIRES_WIFIS"];
		if([[self readPreferenceValue:autoRefreshEnabled] boolValue] == FALSE){
			NSMutableArray* specifiers = [_specifiers mutableCopy];
			[specifiers removeObject:_timeSelectionSpecifier];
			[specifiers removeObject:_requiresWiFiSpecifier];
			_specifiers = specifiers;
		}
	}
	return _specifiers;
}


-(void)toggleAutoRefresh:(id)value forSpecifier:(PSSpecifier*)specifier{
	[self setPreferenceValue:value specifier:specifier];
	if([value boolValue]){
		[self insertContiguousSpecifiers:@[_timeSelectionSpecifier, _requiresWiFiSpecifier] atIndex:2 animated:YES];
	}else{
		[self removeContiguousSpecifiers:@[_timeSelectionSpecifier, _requiresWiFiSpecifier] animated:YES] ;
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
	NSDictionary *exampleTweakSettings = [NSDictionary dictionaryWithContentsOfFile:kCydiaNotifierPreferencePlistPath];
	if (!exampleTweakSettings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return exampleTweakSettings[specifier.properties[@"key"]];
}
 
-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:kCydiaNotifierPreferencePlistPath]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:kCydiaNotifierPreferencePlistPath atomically:YES];
	CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
	if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}
@end
