//
//  PlayOptions.h
//  SeqNotes
//
//  Created by ches on 12/21/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface PlayOptions : NSObject {
    long beatsPerMinute;
    long instrumentIndex;
}

@property (assign)  long beatsPerMinute;
@property (assign)  long instrumentIndex;

- (void) save;

@end

NS_ASSUME_NONNULL_END
