//
//  Sequence.h
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

#import "PlayOptions.h"

NS_ASSUME_NONNULL_BEGIN

@class Sequence;

@protocol sequenceProtocol <NSObject>
- (void) addSequence: (Sequence *)sequence;
- (void) valuesFetchedForSequence:(Sequence *)sequence;
@end

@protocol midiSequenceProtocol <NSObject>
- (void) midiFileReady:(NSString *) midiFile;
@end

@interface Sequence : NSObject {
    NSString *name, *title, *description;
    NSString *shortTitle, *shortComment;    // manual, from startup file
    BOOL valuesUnavailable;
    id<sequenceProtocol> target;
    id<midiSequenceProtocol> MIDItarget;
}

@property (nonatomic, strong)   NSString *name, *title, *description;
@property (nonatomic, strong)   NSString *shortTitle, *shortComment;
@property (assign)              BOOL valuesUnavailable;
@property (nonatomic, strong)   id<sequenceProtocol> target;
@property (nonatomic, strong)   id<midiSequenceProtocol> MIDItarget;

- (id)initSequence: (NSString *)seq;
- (void) loadBasicDataFromOEIS:(id<sequenceProtocol>)caller;
- (NSString *) fetchValues;
- (NSString *) titleToUse;
- (NSString *) subtitleToUse;
- (void) dump;

- (NSString *) pathToPlotData;
- (NSString *) pathToValues;

- (UIImage *) plotImage;
- (UIImage *) plotIconForWidth:(CGFloat) width;

- (BOOL) havePlots;
- (BOOL) haveValues;
- (NSString *) fetchOEISMidiFor:(PlayOptions *)options
                        target:(id<midiSequenceProtocol>)caller;

- (NSArray *) values;

NS_ASSUME_NONNULL_END

@end
