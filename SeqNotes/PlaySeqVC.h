//
//  PlaySeqVC.h
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sequence.h"

#import <MessageUI/MessageUI.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlaySeqVC : UIViewController
    <UIScrollViewDelegate,
    MFMailComposeViewControllerDelegate,
    UIPickerViewDataSource,
    UIPickerViewDelegate>

- (id)initWithSequence:(Sequence *)s width:(CGFloat) w;

@end

NS_ASSUME_NONNULL_END
