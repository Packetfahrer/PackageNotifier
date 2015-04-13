#import "CydiaNotifierBadgePreferences.h"

#define enableGroupFooterTextDisabled @"Enabling this option will show a badge, similar to the OTA Update badge in the cells of packages, for which updates are available. \n\nAll changes here require a restart of the preference app."
#define enableGroupFooterTextEnabled @"All changes here require a restart of the preference app."

@implementation CydiaNotifierBadgePreferencesListController
- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"CydiaNotifierBadgePreferences" target:self];

		_enableGroupSpecifiers = [[_specifiers subarrayWithRange:NSMakeRange(2, [_specifiers count]-2)] mutableCopy];
		_enableGroupSpecifier = _specifiers[0];
		PSSpecifier* enableBadgesSpecifier = [self specifierForID:@"ENABLE_BADGES"];

		_badgeColorGroupSpecifier = [self specifierForID:@"BADGE_COLOR_GROUP"];
		_badgeColorSpecifier = [self specifierForID:@"BADGE_COLOR"];
		_badgeTextColorGroupSpecifier  = [self specifierForID:@"BADGE_TEXT_COLOR_GROUP"];
		_badgeTextColorSpecifier = [self specifierForID:@"BADGE_TEXT_COLOR"];

		BOOL adaptiveColorEnabled = [[self readPreferenceValue:[self specifierForID:@"ENABLE_ADAPTIVE_COLOR"]]boolValue];


		if([[self readPreferenceValue:enableBadgesSpecifier] boolValue]){
			//it's enabled
			[_enableGroupSpecifier.properties setObject:enableGroupFooterTextEnabled forKey:@"footerText"];

			if(adaptiveColorEnabled){
				NSMutableArray* specifiers = [_specifiers mutableCopy];
				NSArray* colorGroupSpecifiers = @[_badgeTextColorGroupSpecifier, _badgeTextColorSpecifier, _badgeColorGroupSpecifier, _badgeColorSpecifier];

				[_enableGroupSpecifiers removeObjectsInArray:colorGroupSpecifiers];
				[specifiers removeObjectsInArray:colorGroupSpecifiers];
				_specifiers = specifiers;
			}
		}else{
			//it's not enabled. Remove everything exept the switch.
			_specifiers = [_specifiers subarrayWithRange:NSMakeRange(0, 2)];
			[_enableGroupSpecifier.properties setObject:enableGroupFooterTextDisabled forKey:@"footerText"];

			if(adaptiveColorEnabled){
				NSArray* colorGroupSpecifiers = @[_badgeTextColorGroupSpecifier, _badgeTextColorSpecifier, _badgeColorGroupSpecifier, _badgeColorSpecifier];
				[_enableGroupSpecifiers removeObjectsInArray:colorGroupSpecifiers];
			}
		}
	}
	return _specifiers;
}

-(void)toggleEnableBadges:(id)value forSpecifier:(PSSpecifier*)specifier{
	[self setPreferenceValue:value specifier:specifier];
	if([value boolValue] == YES){
			[_enableGroupSpecifier.properties setObject:enableGroupFooterTextEnabled forKey:@"footerText"];
		[self insertContiguousSpecifiers:_enableGroupSpecifiers atIndex:2 animated:YES];
	}else{
			[_enableGroupSpecifier.properties setObject:enableGroupFooterTextDisabled forKey:@"footerText"];
		[self removeContiguousSpecifiers:_enableGroupSpecifiers animated:YES] ;
	}
	[self reloadSpecifier:_enableGroupSpecifier animated:YES];
}

-(void)toggleAdaptiveColor:(id)value forSpecifier:(PSSpecifier*)specifier{
	[self setPreferenceValue:value specifier:specifier];
	NSArray* colorGroupSpecifiers = @[_badgeTextColorGroupSpecifier, _badgeTextColorSpecifier, _badgeColorGroupSpecifier, _badgeColorSpecifier];

	if(![value boolValue]){
		NSIndexSet *indexes = [NSIndexSet indexSetWithIndexesInRange: NSMakeRange(2,[colorGroupSpecifiers count])];
		[_enableGroupSpecifiers insertObjects:colorGroupSpecifiers atIndexes:indexes];

		//seriously. This is messed up.
		[self insertContiguousSpecifiers:colorGroupSpecifiers atIndex:4 animated:YES];
	}else{
		[_enableGroupSpecifiers removeObjectsInArray:colorGroupSpecifiers];
		[self removeContiguousSpecifiers:colorGroupSpecifiers animated:YES] ;
	}
}

#pragma mark plist save/read methods to ensure ios8-compatiblity
 
-(id) readPreferenceValue:(PSSpecifier*)specifier {
	NSDictionary *exampleTweakSettings = [NSDictionary dictionaryWithContentsOfFile:CydiaNotifierPreferencePlistPath];
	if (!exampleTweakSettings[specifier.properties[@"key"]]) {
		return specifier.properties[@"default"];
	}
	return exampleTweakSettings[specifier.properties[@"key"]];
}
 
-(void) setPreferenceValue:(id)value specifier:(PSSpecifier*)specifier {
	NSMutableDictionary *defaults = [NSMutableDictionary dictionary];
	[defaults addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:CydiaNotifierPreferencePlistPath]];
	[defaults setObject:value forKey:specifier.properties[@"key"]];
	[defaults writeToFile:CydiaNotifierPreferencePlistPath atomically:YES];
	CFStringRef toPost = (CFStringRef)specifier.properties[@"PostNotification"];
	if(toPost) CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), toPost, NULL, NULL, YES);
}
@end
