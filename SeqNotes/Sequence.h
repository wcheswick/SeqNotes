//
//  Sequence.h
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@class Sequence;
@protocol sequenceProtocol <NSObject>

- (void) addSequence: (Sequence *)sequence;
- (void) valuesFetchedForSequence:(Sequence *)sequence;

@end

@interface Sequence : NSObject {
    NSString *name, *title, *description;
    NSString *shortTitle, *shortComment;    // manual, from startup file
    BOOL valuesUnavailable;
    id<sequenceProtocol> target;
}

@property (nonatomic, strong)   NSString *name, *title, *description;
@property (nonatomic, strong)   NSString *shortTitle, *shortComment;
@property (assign)              BOOL valuesUnavailable;
@property (nonatomic, strong)   id<sequenceProtocol> target;

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
- (BOOL) haveDavidMidi; // Applegate's MIDI from OEIS, for debugging our stuff

- (NSArray *) values;

NS_ASSUME_NONNULL_END

@end
