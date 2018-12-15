//
//  BrowseOEISVC.m
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <WebKit/WebKit.h>

#import "BrowseOEISVC.h"
#import "Defines.h"

@interface BrowseOEISVC ()

@property (nonatomic, strong)   WKWebView *webView;

@end

@implementation BrowseOEISVC

@synthesize webView;

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.opaque = YES;
    self.title = @"OEIS";
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                       target:self action:@selector(doSelectSeq:)];
    rightBarButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = rightBarButton;

    webView = [[WKWebView alloc] init];
    webView.navigationDelegate = self;
    webView.scrollView.showsVerticalScrollIndicator = YES;
    [self.view addSubview:webView];
    
    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc]
                                           initWithTarget:self
                                           action:@selector(swipeLeft:)];
    leftSwipe.direction = UISwipeGestureRecognizerDirectionLeft;
    leftSwipe.enabled = YES;
    [self.view addGestureRecognizer:leftSwipe];
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                       target:self action:@selector(swipeLeft:)];
    leftBarButton.enabled = NO;
    self.navigationItem.leftBarButtonItem = leftBarButton;

}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:OEIS_URL]]];
    [webView setNeedsDisplay];
}


- (IBAction)doSelectSeq:(UISwipeGestureRecognizer *)sender {
    //    LogVC *lvc = [[LogVC alloc] initWithLog:log];
    //    //    self.navigationController.toolbarHidden = NO;
    //    [[self navigationController] pushViewController: lvc animated: YES];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
