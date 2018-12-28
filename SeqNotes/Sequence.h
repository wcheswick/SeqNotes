//
//  Sequence.h
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class Sequence;
@protocol sequenceProtocol <NSObject>

- (void) addSequence: (Sequence *)sequence;
- (void) valuesFetchedForSequence:(Sequence *)sequence;

@end

@interface Sequence : NSObject {
    NSString *seq, *name, *description;
    NSString *shortTitle, *shortComment;    // manual, from startup file
    NSMutableArray *values;
    BOOL valuesUnavailable;
    NSData *plotData;
    NSData *midiData;
    id<sequenceProtocol> target;
}

@property (nonatomic, strong)   NSString *seq, *name, *description;
@property (nonatomic, strong)   NSString *shortTitle, *shortComment;
@property (nonatomic, strong)   NSMutableArray *values;
@property (nonatomic, strong)   NSData *plotData;
@property (nonatomic, strong)   NSData *midiData;
@property (assign)              BOOL valuesUnavailable;
@property (nonatomic, strong)   id<sequenceProtocol> target;

- (id)initSequence: (NSString *)seq;
- (void) loadBasicDataFromOEIS:(id<sequenceProtocol>)caller;
- (NSString *) fetchValues;
- (NSString *) titleToUse;
- (NSString *) subtitleToUse;
- (void) dump;

NS_ASSUME_NONNULL_END

@end
