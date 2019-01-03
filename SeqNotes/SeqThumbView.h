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

#define PLOT_VIEW_TAB   1000
#define SOUND_VIEW_TAG  2000
#define THUMB_INDEX_BIAS  3000

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
