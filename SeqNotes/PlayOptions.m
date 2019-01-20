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
@synthesize maxLength;

- (id)init {
    self = [super init];
    if (self) {
        beatsPerMinute = 100;
        instrumentIndex = 0;
        maxLength = 0;
    }
    return self;
}

#define kInstrumentIndex @"Instrument"
#define kBPM             @"BeatsPerMinute"
#define kMaxLength      @"MaxLength"

- (id) initWithCoder: (NSCoder *)coder {
    self = [super init];
    if (self) {
        beatsPerMinute = [coder decodeIntForKey:kBPM];
        instrumentIndex = [coder decodeIntForKey:kInstrumentIndex];
        maxLength = [coder decodeInt32ForKey:kMaxLength];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeInt32:beatsPerMinute forKey:kBPM];
    [coder encodeInt32:instrumentIndex forKey:kInstrumentIndex];
    [coder encodeInt32:maxLength forKey:kMaxLength];
}

- (void) save {
    if (![NSKeyedArchiver archiveRootObject:self
                                     toFile:PLAY_OPTIONS_ARCHIVE])
        NSLog(@"**** play options save failed");
}

- (void) dump: (NSString *) title {
    NSLog(@"play options:  %@", title);
    NSLog(@"    beats per minute: %d", beatsPerMinute);
    NSLog(@"    instrument index: %d", instrumentIndex);
    NSLog(@"          max length: %d", maxLength);
}

@end
