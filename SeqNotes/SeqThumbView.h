//
//  SeqThumbView.h
//  SeqNotes
//
//  Created by ches on 12/21/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sequence.h"

#define SEQ_W   (320)
#define EAR_W   30

#define SOUND_VIEW_TAG  1000
#define THUMB_INDEX_BIAS  2000
#define PLOT_VIEW_TAB   3000

NS_ASSUME_NONNULL_BEGIN

@interface SeqThumbView : UIView {
    Sequence *sequence;
}

@property (nonatomic, strong)   Sequence *sequence;

- (id)initWithSequence: (Sequence *)s;
- (void) adjustThumb;

@end

NS_ASSUME_NONNULL_END