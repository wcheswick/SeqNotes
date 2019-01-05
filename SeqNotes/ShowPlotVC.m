//
//  ShowPlotVC.m
//  SeqNotes
//
//  Created by William Cheswick on 1/5/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import "ShowPlotVC.h"
#import "Defines.h"

@interface ShowPlotVC ()

@property (nonatomic, strong)   Sequence *sequence;
@property (nonatomic, strong)   UIView *containerView;
@property (nonatomic, strong)   UIScrollView *scrollView;

@end

@implementation ShowPlotVC

@synthesize sequence;
@synthesize containerView;
@synthesize scrollView;

- (id)initWithSequence:(Sequence *)s width:(CGFloat) w {
    self = [super init];
    if (self) {
        sequence = s;
        
        containerView = [[UIView alloc]
                         initWithFrame:CGRectMake(INSET, INSET, w - 2*INSET, LATER)];
        containerView.backgroundColor = [UIColor yellowColor];
 
        UIImage *plotImage = [UIImage imageWithData:sequence.plotData];
        UIImageView *plotsView = [[UIImageView alloc] initWithImage:plotImage];
        plotsView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat aspect = plotImage.size.height/plotImage.size.width;
        plotsView.frame = CGRectMake(0, 0,
                                     containerView.frame.size.width,
                                     containerView.frame.size.width*aspect);
        plotsView.opaque = YES;
        [containerView addSubview:plotsView];
        SET_VIEW_HEIGHT(containerView, BELOW(plotsView.frame));
        
        scrollView = [[UIScrollView alloc] init];
        scrollView.pagingEnabled = NO;
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        scrollView.showsVerticalScrollIndicator = YES;
        scrollView.exclusiveTouch = NO;
        scrollView.bounces = NO;
        [scrollView addSubview:containerView];
        scrollView.contentSize = containerView.frame.size;
        scrollView.frame = self.view.frame;
        SET_VIEW_Y(scrollView, 0);
        [self.view addSubview:scrollView];
        
        self.view.frame = CGRectMake(0, LATER,
                                     w, containerView.frame.size.height + INSET);
        self.view.backgroundColor = [UIColor whiteColor];
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
    SET_VIEW_Y(self.view, BELOW(self.navigationController.navigationBar.frame));
    NSLog(@"svc vdl: %@", NSStringFromCGRect(self.view.frame));
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat top = self.navigationController.navigationBar.frame.size.height;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        top += [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    SET_VIEW_Y(containerView, top);
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [self dismissViewControllerAnimated:YES completion:NULL];
}


@end
