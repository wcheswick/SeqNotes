//
//  PositionViewVC.m
//  SeqNotes
//
//  Created by ches on 1/21/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "PositionView.h"
#import "Defines.h"

@interface PositionView ()

@property (nonatomic, strong)   UILabel *musicLengthLabel;
@property (nonatomic, strong)   UISlider *positionSlider;

@property (nonatomic, strong)   UIImage *scaledRightNote, *scaledLeftNote;

@end

@implementation PositionView

@synthesize target;
@synthesize positionSlider, musicLengthLabel;
@synthesize scaledRightNote, scaledLeftNote;

- (void) setPosition:(float) p {
    if (p == position)
        return;
    position = p;
    positionSlider.value = position/duration;
    [positionSlider setNeedsDisplay];
}

- (void) setDuration:(float) d {
    if (d == duration)
        return;
    duration = d;
    int min = d / 60.0;
    float sec = d - (60.0 * min);
    musicLengthLabel.text = [NSString stringWithFormat:@"%d:%02.0f", min, sec];
    [musicLengthLabel setNeedsDisplay];
    positionSlider.value = position/duration;
    [self setNeedsLayout];
}

@synthesize position,duration;

- (id)initWithFrame:(CGRect)f {
    self = [super initWithFrame:f];
    if (self) {
        self.frame = f;
        
        musicLengthLabel = [[UILabel alloc]
                            initWithFrame:CGRectMake(LATER, 0,
                                                    SMALL_LABEL_FONT_SIZE*0.7*@"00:00".length, self.frame.size.height)];
        musicLengthLabel.text = @"";
        musicLengthLabel.font = [UIFont boldSystemFontOfSize:SMALL_LABEL_FONT_SIZE];
        musicLengthLabel.textAlignment = NSTextAlignmentCenter;
        musicLengthLabel.backgroundColor = [UIColor whiteColor];
        [self addSubview:musicLengthLabel];
        
        positionSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, LATER, self.frame.size.height)];
        positionSlider.minimumValue = 0.0;
        positionSlider.maximumValue = 1.0;
        [positionSlider addTarget:self
                           action:@selector(doChangePosition:)
                 forControlEvents:UIControlEventValueChanged];
        positionSlider.backgroundColor = [UIColor whiteColor];
        [self addSubview: positionSlider];
        
        UIImage *rightNote = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                               pathForResource:@"rightnote"
                                                               ofType:@"png"]];
        scaledRightNote = [UIImage imageWithCGImage:rightNote.CGImage
                                                   scale:10 //(smallNote.scale * f.size.height/smallNote.size.height)
                                             orientation:rightNote.imageOrientation];
        
        UIImage *leftNote = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                               pathForResource:@"leftnote"
                                                               ofType:@"png"]];
        scaledLeftNote = [UIImage imageWithCGImage:leftNote.CGImage
                                             scale:10 //(smallNote.scale * f.size.height/smallNote.size.height)
                                       orientation:rightNote.imageOrientation];
        [positionSlider setThumbImage:scaledLeftNote
                             forState:UIControlStateNormal];
        self.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

- (void) layoutSubviews {
    [super layoutSubviews];
    
    NSLog(@"positionview: layout subviews");
    SET_VIEW_X(musicLengthLabel, self.frame.size.width - musicLengthLabel.frame.size.width);
    [musicLengthLabel setNeedsLayout];
    SET_VIEW_WIDTH(positionSlider, self.frame.size.width - musicLengthLabel.frame.size.width);
    [positionSlider setNeedsLayout];
}

- (IBAction)doChangePosition:(UIView *)sender {
    UISlider *view = (UISlider *)sender;
    [target newPosition:view.value * duration];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
