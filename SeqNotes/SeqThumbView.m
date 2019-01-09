//
//  SeqThumbView.m
//  SeqNotes
//
//  Created by ches on 12/21/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import "SeqThumbView.h"
#import "Defines.h"

@interface SeqThumbView ()

@property (nonatomic, strong)   UILabel *titleLabel;
@property (nonatomic, strong)   UILabel *subTitleLabel;
@property (nonatomic, strong)   UILabel *descLabel;
@property (nonatomic, strong)   UIButton *earButton;
@property (nonatomic, strong)   UIActivityIndicatorView *busyDownloadingView;
@property (nonatomic, strong)   UIButton *plotButton;

@end

@implementation SeqThumbView

@synthesize sequence;
@synthesize titleLabel, subTitleLabel;
@synthesize earButton, plotButton;
@synthesize busyDownloadingView;
@synthesize descLabel;

- (id)initWithSequence: (Sequence *)s width:(CGFloat)w {
    self = [super init];
    if (self) {
        sequence = s;

        earButton = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *ear = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                                         pathForResource:@"ear"
                                                         ofType:@"jpg"]];
        earButton.frame = CGRectMake(LATER, INSET, EAR_W, EAR_W);
        [earButton.imageView setContentMode: UIViewContentModeScaleAspectFit];
        earButton.tag = SOUND_VIEW_TAG;
        [self.earButton setImage:ear forState:UIControlStateNormal];
        [self addSubview:earButton];
        
        busyDownloadingView = [[UIActivityIndicatorView alloc]
                               initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        busyDownloadingView.frame = earButton.frame;
        busyDownloadingView.hidesWhenStopped = YES;
//        busyDownloadingView.opaque = YES;
        [busyDownloadingView stopAnimating];
        [self addSubview:busyDownloadingView];
        
        plotButton = [UIButton buttonWithType:UIButtonTypeCustom];
        plotButton.frame = earButton.frame;
        SET_VIEW_Y(plotButton, BELOW(earButton.frame) +SEP);
        [plotButton.imageView setContentMode: UIViewContentModeScaleAspectFit];
        plotButton.tag = PLOT_VIEW_TAG;
        plotButton.hidden = YES;
        plotButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
        plotButton.layer.borderWidth = 1.0;
        plotButton.layer.cornerRadius = 3.0;
        [self addSubview:plotButton];

        titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(INSET, INSET,
                                                              LATER,
                                                              LABEL_H)];
        titleLabel.text = sequence.name;
        titleLabel.font = [UIFont boldSystemFontOfSize:LABEL_FONT_SIZE];
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 0.5;
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:titleLabel];
        
        subTitleLabel = [[UILabel alloc] initWithFrame:titleLabel.frame];
        SET_VIEW_Y(subTitleLabel, BELOW(titleLabel.frame));
        subTitleLabel.text = [sequence subtitleToUse];
        subTitleLabel.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
        subTitleLabel.lineBreakMode = NSLineBreakByWordWrapping;
        subTitleLabel.numberOfLines = 0;
        self.backgroundColor = [UIColor whiteColor];
        [self addSubview:subTitleLabel];
        
        descLabel = [[UILabel alloc] init];
        descLabel.text = sequence.title;
        descLabel.font = [UIFont systemFontOfSize:14];
        descLabel.lineBreakMode = NSLineBreakByWordWrapping;
        descLabel.numberOfLines = 0;
        [self addSubview:descLabel];
        
        self.layer.borderColor = [UIColor blackColor].CGColor;
        self.layer.borderWidth = 0.5;
        self.backgroundColor = [UIColor whiteColor];

        [self applyNewThumbWidth: w];
        [self adjustThumb];
    }
    return self;
}

- (void) applyNewThumbWidth:(CGFloat) w {
    self.frame = CGRectMake(0, 0, w, LATER);
    SET_VIEW_X(earButton, w - INSET - EAR_W);
    SET_VIEW_X(plotButton, earButton.frame.origin.x);
    SET_VIEW_WIDTH(titleLabel, earButton.frame.origin.x - SEP);
    [earButton setNeedsDisplay];
    [plotButton setNeedsDisplay];
    [titleLabel setNeedsDisplay];

    CGRect f = [subTitleLabel.text boundingRectWithSize:CGSizeMake(titleLabel.frame.size.width, CGFLOAT_MAX)
                                                options:NSStringDrawingUsesLineFragmentOrigin
                                             attributes:@{NSFontAttributeName: subTitleLabel.font}
                                                context:nil];
    f.size.width = ceil(f.size.width);
    f.size.height = ceil(f.size.height);
    f.origin = subTitleLabel.frame.origin;
    subTitleLabel.frame = f;
    [subTitleLabel setNeedsDisplay];

    SET_VIEW_WIDTH(descLabel, self.frame.size.width - 2*INSET);
    
    f = [descLabel.text boundingRectWithSize:CGSizeMake(descLabel.frame.size.width, CGFLOAT_MAX)
                                     options:NSStringDrawingUsesLineFragmentOrigin
                                  attributes:@{NSFontAttributeName: descLabel.font}
                                     context:nil];
    f.size.width = ceil(f.size.width);
    f.size.height = ceil(f.size.height);
    f.origin.x = INSET;
    f.origin.y = BELOW(subTitleLabel.frame) + SEP;
    descLabel.frame = f;
    [descLabel setNeedsDisplay];
    SET_VIEW_HEIGHT(self, BELOW(descLabel.frame) + INSET);
    [self setNeedsDisplay];
}

- (void) adjustThumb {
    if ([sequence haveValues]) {
        earButton.hidden = NO;
        [busyDownloadingView stopAnimating];
    } else {
        earButton.hidden = YES;
        [busyDownloadingView startAnimating];
    }
    [earButton setNeedsDisplay];
    
    if (plotButton.hidden && [sequence havePlots]) {   // install the icon
        UIImage *plotIcon = [sequence plotIconForWidth:plotButton.frame.size.width];
        [self.plotButton setImage:plotIcon forState:UIControlStateNormal];
        plotButton.hidden = NO;
        [plotButton setNeedsDisplay];
    }
    [busyDownloadingView setNeedsDisplay];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
