//
//  PlayOptions.m
//  SeqNotes
//
//  Created by ches on 12/21/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import "PlayOptions.h"
#import "Defines.h"

@implementation PlayOptions

@synthesize beatsPerMinute;
@synthesize instrumentIndex;


- (id)init {
    self = [super init];
    if (self) {
        beatsPerMinute = 100;
        instrumentIndex = 0;
    }
    return self;
}

#define kInstrumentIndex @"Instrument"
#define kBPM             @"BeatsPerMinute"

- (id) initWithCoder: (NSCoder *)coder {
    self = [super init];
    if (self) {
        beatsPerMinute = [coder decodeIntForKey:kBPM];
        instrumentIndex = [coder decodeIntForKey:kInstrumentIndex];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt64:beatsPerMinute forKey:kBPM];
    [coder encodeInt64:instrumentIndex forKey:kInstrumentIndex];
}

- (void) save {
    if (![NSKeyedArchiver archiveRootObject:self
                                     toFile:PLAY_OPTIONS_ARCHIVE])
        NSLog(@"play options save failed");
}

@end
