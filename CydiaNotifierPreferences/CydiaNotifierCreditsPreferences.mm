#import "CydiaNotifierCreditsPreferences.h"

@implementation CydiaNotifierCreditsPreferences

-(void)followOnTwitter{
	NSURL* twitterURL = [NSURL URLWithString:@"twitter://user?screen_name=AccuraTweaks"];
	if ([[UIApplication sharedApplication] canOpenURL:twitterURL]) {
		[[UIApplication sharedApplication] openURL:twitterURL];
	}else{
		NSURL* url = [NSURL URLWithString:@"https://twitter.com/intent/user?screen_name=AccuraTweaks"];
		[[UIApplication sharedApplication] openURL:url];
	}
}

-(void)donate{
	NSURL* url = [NSURL URLWithString:@"https://www.paypal.com/cgi-bin/webscr?cmd=_s-xclick&hosted_button_id=KU4J9QBLBRANL"];
	[[UIApplication sharedApplication] openURL:url];
}

-(void)visitAccuraTweaks{
	NSURL* url = [NSURL URLWithString:@"http://www.accuratweaks.com"];
	[[UIApplication sharedApplication] openURL:url];
}

-(void)visitGithub{
	NSURL* url = [NSURL URLWithString:@"https://github.com/Cr4zyS1m0n/CydiaNotifier"];
	[[UIApplication sharedApplication] openURL:url];
}


- (id)specifiers {
	if(_specifiers == nil) {
		_specifiers = [self loadSpecifiersFromPlistName:@"CydiaNotifierCreditsPreferences" target:self];

		 PSSpecifier* AccuraTweaks = [self specifierForID:@"ACCURA_TWEAKS"];
		 NSString *logoPath = [NSString stringWithFormat:@"%@/%@", [self bundle].bundlePath, @"accura-logo.png"];
		 NSString *head1Path = [NSString stringWithFormat:@"%@/%@", [self bundle].bundlePath, @"avatar-simon.png"];
		 NSString *head2Path = [NSString stringWithFormat:@"%@/%@", [self bundle].bundlePath, @"avatar-ibrahim.png"];
		 [AccuraTweaks setProperty:logoPath forKey:@"logo"];
		 [AccuraTweaks setProperty:head1Path forKey:@"head1"];
		 [AccuraTweaks setProperty:head2Path forKey:@"head2"];
	}
	return _specifiers;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	PSSpecifier* specifier = [self specifierAtIndex:[self indexForIndexPath:indexPath]];
	NSNumber* dynamicHeight = [specifier.properties objectForKey:@"dynamicHeight"];
	if(dynamicHeight && [dynamicHeight boolValue]){
		UITableViewCell<ATPSTableCell>* cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
		return [cell preferredHeightForWidth:tableView._wrapperView.frame.size.width];
	}


	return [super tableView:tableView heightForRowAtIndexPath:indexPath];

}


-(id)tableView:(id)arg1 cellForRowAtIndexPath:(NSIndexPath*)indexPath{
	PSTableCell* cell = [super tableView:arg1 cellForRowAtIndexPath:indexPath];

  	if(indexPath.row == 0){
	  	if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
	           [cell setSeparatorInset:UIEdgeInsetsZero];
	    }

	    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
	        [cell setPreservesSuperviewLayoutMargins:NO];
	    }

	    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
	        [cell setLayoutMargins:UIEdgeInsetsZero];
	    }
  }
    
    return cell;
}

@end