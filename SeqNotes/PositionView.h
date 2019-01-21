//
//  PositionView.h
//  SeqNotes
//
//  Created by ches on 1/21/19.
//  Copyright © 2019 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol PositionProtocol <NSObject>

- (void) newPosition:(float) newPosition;

@end

@interface PositionView : UIView {
    float position, duration;
    __unsafe_unretained id<PositionProtocol> target;
}

@property (assign, nonatomic)  float position, duration;
@property (assign)  __unsafe_unretained id<PositionProtocol> target;

@end

NS_ASSUME_NONNULL_END
