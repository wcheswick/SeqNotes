//
//  SeqThumbView.h
//  SeqNotes
//
//  Created by ches on 12/21/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sequence.h"

#define EAR_W   30

// Type identifiers from the thumb view
#define PLOT_VIEW_TAG   1
#define SOUND_VIEW_TAG  2

// INDEX/type identifiers from the main screen
#define PLOT_INDEX_BIAS     1000
#define SOUND_INDEX_BIAS    2000

#define IS_PLOT_BUTTON_TAG(t)   ((t) >= PLOT_INDEX_BIAS && \
            (t) < SOUND_INDEX_BIAS)
#define IS_SOUND_BUTTON_TAG(t)   ((t) >= SOUND_INDEX_BIAS)

NS_ASSUME_NONNULL_BEGIN

@interface SeqThumbView : UIView {
    Sequence *sequence;
}

@property (nonatomic, strong)   Sequence *sequence;

- (id)initWithSequence: (Sequence *)s
                 width:(CGFloat)w;
- (void) adjustThumb;
- (void) applyNewThumbWidth:(CGFloat) w;

@end

NS_ASSUME_NONNULL_END
