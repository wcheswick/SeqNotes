//
//  ShowSeqVC.h
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sequence.h"

NS_ASSUME_NONNULL_BEGIN

@interface ShowSeqVC : UIViewController
    <UIScrollViewDelegate>

- (id)initWithSequence: (Sequence *)s;

@end

NS_ASSUME_NONNULL_END
