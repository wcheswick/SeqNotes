//
//  ShowSeqVC.m
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import "ShowSeqVC.h"
#import "Defines.h"

@interface ShowSeqVC ()

@property (nonatomic, strong)   Sequence *sequence;

@property (nonatomic, strong)   UIView *containerView;
@property (nonatomic, strong)   UIScrollView *scrollView;

@end

@implementation ShowSeqVC

@synthesize sequence;
@synthesize containerView, scrollView;

- (id)initWithSequence: (Sequence *)s {
    self = [super init];
    if (self) {
        sequence = s;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.opaque = YES;
    self.title = sequence.seq;
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doDone:)];
    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    containerView = [[UIView alloc] init];
    containerView.frame = CGRectMake(0, 0, LATER, LATER);

    UILabel *titleView = [[UILabel alloc] init];
    titleView.text = [sequence titleToUse];
    titleView.font = [UIFont systemFontOfSize:LARGE_FONT_SIZE];
    titleView.numberOfLines = 0;
    titleView.lineBreakMode = NSLineBreakByWordWrapping;
    titleView.frame = CGRectMake(0, 0, self.view.frame.size.width, 3*LARGE_H);
    [containerView addSubview:titleView];

    UILabel *descriptionView = [[UILabel alloc] init];
    descriptionView.text = [sequence subtitleToUse];
    descriptionView.lineBreakMode = NSLineBreakByWordWrapping;
    descriptionView.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
    descriptionView.numberOfLines = 0;
    descriptionView.lineBreakMode = NSLineBreakByWordWrapping;
    descriptionView.frame = CGRectMake(0, BELOW(titleView.frame) + SEP,
                                       self.view.frame.size.width, 4*LABEL_H);
    [containerView addSubview:descriptionView];
    
    UIView *soundControlView = [[UIView alloc] init];
    soundControlView.frame = CGRectMake(0, BELOW(descriptionView.frame) + SEP,
                                        self.view.frame.size.width, LARGE_H);
    soundControlView.layer.borderWidth = 1.0;
    soundControlView.layer.cornerRadius = 5.0;
    soundControlView.layer.borderColor = [UIColor lightGrayColor].CGColor;
    
    UILabel *controls = [[UILabel alloc] init];
    controls.text = @"(Sound controls under construction)";
    controls.font = [UIFont systemFontOfSize:SMALL_LABEL_FONT_SIZE];
    controls.frame = CGRectMake(0, 0, soundControlView.frame.size.width, SMALL_LABEL_H);
    [soundControlView addSubview:controls];
    [containerView addSubview:soundControlView];
    
    CGRect f = containerView.frame;
    if (sequence.plotData) {
        UIImage *plotImage = [UIImage imageWithData:sequence.plotData];
        UIImageView *plotsView = [[UIImageView alloc] initWithImage:plotImage];
        plotsView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat aspect = plotImage.size.height/plotImage.size.width;
        plotsView.frame = CGRectMake(0, BELOW(soundControlView.frame) + SEP,
                                     self.view.frame.size.width, self.view.frame.size.width*aspect);
        [containerView addSubview:plotsView];
        f.size.height = BELOW(plotsView.frame);
    } else {
        f.size.height = BELOW(soundControlView.frame);
    }
    containerView.frame = f;

    scrollView = [[UIScrollView alloc] init];
    scrollView.pagingEnabled = NO;
    scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    scrollView.showsVerticalScrollIndicator = YES;
    scrollView.userInteractionEnabled = YES;
    scrollView.exclusiveTouch = NO;
    scrollView.bounces = NO;
    scrollView.delaysContentTouches = YES;
    scrollView.canCancelContentTouches = YES;
    [scrollView addSubview:containerView];

    SET_VIEW_WIDTH(containerView, scrollView.frame.size.width);
    scrollView.contentSize = containerView.frame.size;

    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:scrollView];
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGRect f = self.view.frame;
    f.origin.y = self.navigationController.navigationBar.frame.size.height;
    f.size.height -= f.origin.y;
    scrollView.frame = CGRectInset(f, INDENT, INDENT);
    
    SET_VIEW_WIDTH(containerView, scrollView.frame.size.width);
    scrollView.contentSize = containerView.frame.size;
}

@end
