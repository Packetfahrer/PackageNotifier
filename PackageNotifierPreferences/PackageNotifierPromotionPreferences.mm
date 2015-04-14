#import "PackageNotifierPromotionPreferences.h"



@implementation PackageNotifierPromotionPreferences

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
 	PSTextFieldSpecifier *TweaksPromotionCell = [PSTextFieldSpecifier preferenceSpecifierNamed:@""
                                                              target:self
                                                              set:nil
                                                              get:nil
                                                              detail:nil
                                                              cell:[PSTableCell cellTypeFromString:@"PSDefaultCell"]
                                                              edit:nil];

	[TweaksPromotionCell setProperty:NSClassFromString(@"ATPSWebViewTableCell") forKey:@"cellClass"];
	[TweaksPromotionCell setProperty:@"TweaksPromotionCell" forKey:@"id"];
	NSString* url = @"http://api.accuratweaks.com/tweaks/tweaks.php?id=com.accuratweaks.packagenotifier";
	[TweaksPromotionCell setProperty:url forKey:@"url"];

    [self replaceContiguousSpecifiers:@[self.loadingSpecifier] withSpecifiers:@[TweaksPromotionCell] animated:YES];
}



- (NSArray *)specifiers
{
	if (_specifiers == nil) {
        NSMutableArray *specifiers = [NSMutableArray array];

        NSString* tweaksURLStr = @"http://api.accuratweaks.com/tweaks/tweaks.php?id=com.accuratweaks.packagenotifier";

		NSURL *tweaksURL = [NSURL URLWithString:tweaksURLStr];
		NSURLRequest* tweaksRequest = [NSURLRequest requestWithURL:tweaksURL cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:30];

		self.sizeCalculationView = [[UIWebView alloc]initWithFrame:CGRectZero];
		self.sizeCalculationView.delegate = self;
		self.sizeCalculationView.hidden = YES;
		self.sizeCalculationView.scrollView.scrollEnabled = YES;
		[self.sizeCalculationView loadRequest:tweaksRequest];

		[self.view addSubview:self.sizeCalculationView];

        self.loadingSpecifier = [PSSpecifier preferenceSpecifierNamed:@""
                                                              target:self
                                                              set:nil
                                                              get:nil
                                                              detail:nil
                                                              cell:[PSTableCell cellTypeFromString:@"PSDefaultCell"]
                                                              edit:nil];

		[self.loadingSpecifier setProperty:NSClassFromString(@"ATPSSpinnerTableCell") forKey:@"cellClass"];
		[self.loadingSpecifier setProperty:@(100) forKey:@"height"];

    	[specifiers addObjectsFromArray:@[self.loadingSpecifier]];

      	_specifiers = specifiers;
    }
	return _specifiers;

}

#pragma mark ATCommonPSTableCell

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
	PSSpecifier* specifier = [self specifierAtIndex:[self indexForIndexPath:indexPath]];
	id specifierID = [specifier.properties objectForKey:@"id"];
	if([specifierID isEqual:@"TweaksPromotionCell"]){
		CGFloat width = tableView._wrapperView.frame.size.width;
		self.sizeCalculationView.frame = CGRectMake(0,0,width,1);
		CGFloat height= self.sizeCalculationView.scrollView.contentSize.height;//[[self.sizeCalculationView stringByEvaluatingJavaScriptFromString:@"function f(){var b=document.body,a=	document.documentElement;return Math.max(b.scrollHeight,b.offsetHeight,a.clientHeight,a.scrollHeight,a.offsetHeight)}f();"] floatValue];
		return height;
	}

	return [super tableView:tableView heightForRowAtIndexPath:indexPath];
}
@end
