#import "PNTimeSelectionCell.h"

@implementation PNTimeSelectionCell

-(id)initWithStyle:(int)style reuseIdentifier:(NSString*)reuseIdentifier specifier:(PSSpecifier*)specifier{
	self = [super initWithStyle:style  reuseIdentifier:reuseIdentifier specifier:specifier];
	if ( self )
	{
		_leftLabel = [[UILabel alloc]init];
		_leftLabel.font = [UIFont systemFontOfSize:14];
		_leftLabel.text = @"1h";
		_leftLabel.textAlignment = NSTextAlignmentLeft;;

		_middleLabel = [[UILabel alloc]init];
		_middleLabel.font = [UIFont systemFontOfSize:14];
		_middleLabel.text = @"6h";
		_middleLabel.textAlignment = NSTextAlignmentCenter;

		_rightLabel = [[UILabel alloc]init];
		_rightLabel.font = [UIFont systemFontOfSize:14];
		_rightLabel.text = @"48h";
		_rightLabel.textAlignment = NSTextAlignmentRight;

		_bottomLabel = [[UILabel alloc]init];
		_bottomLabel.font = [UIFont systemFontOfSize:16];
		//_bottomLabel.text = @"Manual";
		_bottomLabel.textAlignment = NSTextAlignmentCenter;

		[self.contentView addSubview:_leftLabel];
		[self.contentView addSubview:_middleLabel];
		[self.contentView addSubview:_rightLabel];
		[self.contentView addSubview:_bottomLabel];
	}
	return self;
}

-(void)sliderValueChanged:(PSDiscreteSlider*)slider{
	_bottomLabel.text = [self stringForPosition:(int)slider.value];

}

-(void)setValue:(id)value{
	[super setValue:value];
	_bottomLabel.text = [self stringForPosition:(int)((UISlider*)self.control).value];
}

-(NSString*)stringForPosition:(int)position{
	NSArray* values = @[@"hourly", @"every two hours", @"every three hours", @"every six hours", @"every 12 hours", @"every day", @"every two days"];
	if(position < [values count]){
		return [NSString stringWithFormat:@"Refresh %@", values[position]];
	}
	return nil;
}

-(id)newControl{
	//
	UIColor* stepperColor = [UIColor colorWithWhite:0.596078 alpha:1];
	PSDiscreteSlider* slider = [[PSDiscreteSlider alloc]initWithFrame:CGRectZero];
	[slider setMinimumTrackTintColor:stepperColor];
	[slider setMaximumTrackTintColor:stepperColor];
	[slider setTrackMarkersColor:stepperColor];
	
	[slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
	return slider;
}

-(void)layoutSubviews{
	[super layoutSubviews];
	CGFloat width = self.contentView.bounds.size.width;
	//CGFloat height = self.contentView.bounds.size.height;

	CGRect topLabelFrame = CGRectMake(20, 10, width - 40, 20);
	_leftLabel.frame = topLabelFrame;
	_middleLabel.frame = topLabelFrame;
	_rightLabel.frame = topLabelFrame;

	((UISlider*)self.control).continuous = YES; //doTo: move this somewhere else
	CGRect controlFrame = CGRectMake(20, 20, width - 40, 60);
	self.control.frame = controlFrame;

	CGRect bottomLabelFrame = CGRectMake(10, 70, width - 20, 30);
	_bottomLabel.frame = bottomLabelFrame;
}

- (CGFloat)preferredHeightForWidth:(CGFloat)width {
	return 110;
}

@end