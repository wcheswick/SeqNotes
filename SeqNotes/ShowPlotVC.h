//
//  ShowPlotVC.h
//  SeqNotes
//
//  Created by William Cheswick on 1/5/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sequence.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShowPlotVC : UIViewController
    <UIScrollViewDelegate>

- (id)initWithSequence:(Sequence *)s width:(CGFloat) w;

@end

NS_ASSUME_NONNULL_END
