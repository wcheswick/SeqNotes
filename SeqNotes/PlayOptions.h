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
    int32_t beatsPerMinute;
    int32_t instrumentIndex;    // starts at zero
    int32_t maxLength;
}

@property (assign)  int32_t beatsPerMinute;
@property (assign)  int32_t instrumentIndex;
@property (assign)  int32_t maxLength;

- (void) save;
- (void) dump: (NSString *) title;

@end

NS_ASSUME_NONNULL_END
