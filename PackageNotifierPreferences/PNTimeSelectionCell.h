#import <Preferences/Preferences.h>
#import <Preferences/PSSliderTableCell.h>
#import <Preferences/PSDiscreteSlider.h>

@interface PNTimeSelectionCell : PSSliderTableCell{
	UILabel* _leftLabel;
	UILabel* _middleLabel;
	UILabel* _rightLabel;
	UILabel* _bottomLabel;
}


- (CGFloat)preferredHeightForWidth:(CGFloat)width;
@end