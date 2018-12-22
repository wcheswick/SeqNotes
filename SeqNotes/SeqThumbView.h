//
//  SeqThumbView.h
//  SeqNotes
//
//  Created by ches on 12/21/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sequence.h"

#define SEQ_W   (300/2)
#define SEQ_H   SEQ_W

NS_ASSUME_NONNULL_BEGIN

@interface SeqThumbView : UIView


- (id)initWithSequence: (Sequence *)s;

@end

NS_ASSUME_NONNULL_END
