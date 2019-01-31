//
//  Sequence.m
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//


#import "SeqToMIDI.h"
#import "Sequence.h"
#import "Defines.h"


@implementation Sequence

@synthesize name, title, description;
@synthesize shortTitle, shortComment;
@synthesize valuesUnavailable;
@synthesize target, MIDItarget;

- (id)initSequence: (NSString *)s {
    self = [super init];
    if (self) {
        name = s;
        title = description = @"";
        shortTitle = shortComment = nil;
        description = nil;
        valuesUnavailable = NO;
        target = nil;
        MIDItarget = nil;
    }
    return self;
}

#define kSeq    @"Seq"  // "seq" is deprecated. if found, force reload from OEIS

#define kName   @"Name"
#define kTitle   @"Title"
#define kDescription    @"Description"
#define kShortTitle     @"ShortTitle"
#define kShortComment   @"ShortComment"
#define kValuesUnavailable  @"ValuesUnavailable"

- (id) initWithCoder: (NSCoder *)coder {
    self = [super init];
    if (self) {
        NSString *seq = [coder decodeObjectForKey: kSeq];
        if (seq)    // old archived data format, reload
            return nil;
        name = [coder decodeObjectForKey:kName];
        title = [coder decodeObjectForKey: kTitle];
        description = [coder decodeObjectForKey: kDescription];
        shortTitle = [coder decodeObjectForKey: kShortTitle];
        shortComment = [coder decodeObjectForKey: kShortComment];
        valuesUnavailable = [coder decodeBoolForKey:kValuesUnavailable];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:name forKey:kName];
    [coder encodeObject:title forKey:kTitle];
    [coder encodeObject:description forKey:kDescription];
    [coder encodeObject:shortTitle forKey:kShortTitle];
    [coder encodeObject:shortComment forKey:kShortComment];
    [coder encodeBool:valuesUnavailable forKey:kValuesUnavailable];
}

- (void) loadBasicDataFromOEIS:(id<sequenceProtocol>)caller {
    target = caller;
    [self fetchSummary];
    [self fetchPlots];
    [self fetchValues];
    [self downloadComplete];
}

- (void) downloadComplete {
//    NSLog(@"    ... MIDI length %lu, fetch complete", (unsigned long)midiData.length);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self->target addSequence:self];
    });
}

- (BOOL) fetchSummary {
    NSString *url = [NSString stringWithFormat:@"https://oeis.org/search?q=id:%@&fmt=text", name];
    NSURL *URL = [NSURL URLWithString:url];
    NSError *error;
    NSString *contents = [NSString stringWithContentsOfURL:URL
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    if (!contents) {
        NSLog(@"OEIS load failed: %@", [error localizedDescription]);
        return NO;
    }
    
    // contents looks like this:
    // # Greetings from The On-Line Encyclopedia of Integer Sequences! http://oeis.org/
    //
    // Search: id:a000055
    // Showing 1-1 of 1
    //
    // %I A000055 M0791 N0299
    // %S A000055 1,1,1,1,2,3,6,11,23,47,106,235,551,1301,3159,7741,19320,48629,123867,
    // %T A000055 317955,823065,2144505,5623756,14828074,39299897,104636890,279793450,
    // %U A000055 751065460,2023443032,5469566585,14830871802,40330829030,109972410221,300628862480,823779631721,2262366343746,6226306037178
    // %N A000055 Number of trees with n unlabeled nodes.
    // %C A000055 Also, number of unlabeled 2-gonal 2-trees with n 2-gons.
    // %C A000055 Main diagonal of A054924.
    // %C A000055 Left border of A157905. - _Gary W. Adamson_, Mar 08 2009
    // %C A000055 From _Robert Munafo_, Jan 24 2010: (Start)
    // %C A000055 Also counts classifications of n items that require exactly n-1 binary partitions; see Munafo link at A005646, also A171871
    // ...
    
    NSArray *lines = [contents componentsSeparatedByString:@"\n"];
    //    NSLog(@" number of text lines for %@: %lu", seq, (unsigned long)lines.count);
    
    for (NSString *line in lines) {
        if (![line hasPrefix:@"%"])
            continue;
        if (line.length <= @"%C A000055 ".length)
            continue;
        NSString *data = [line substringFromIndex:@"%C A000055 ".length];
        if ([line hasPrefix:@"%S"]) {   // first line of numbers
            //            [self appendNumbers: data];
        } else if ([line hasPrefix:@"%T"]) {   // second line of numbers
            //           [self appendNumbers: data];
        } else if ([line hasPrefix:@"%U"]) {   // third line of numbers
            //           [self appendNumbers: data];
        } else if ([line hasPrefix:@"%N"]) {   // title
            title = data;
        }
    }
    return YES;
}

#ifdef notused
- (void) appendNumbers: (NSString *) list {
    NSArray *numbers = [list componentsSeparatedByString:@","];
    for (NSString *number in numbers) {
        if (![number isEqualToString:@""]) {
            [values addObject:@([number integerValue])];
        }
    }
}
#endif

- (NSString *) pathToPlotData {
    return [NSString stringWithFormat:@"./%@.plotdata", name];
}

- (NSString *) pathToValues {
    return [NSString stringWithFormat:@"./%@-values.archive", name];
}

- (NSString *) pathToMIDIWithOptions:(PlayOptions *) options {
    return [NSString stringWithFormat:@"./%@-midi-for-%d-%d-%d",
            name, options.instrumentIndex, options.beatsPerMinute,
            options.maxLength];
}

- (BOOL) havePlots {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self pathToPlotData]];
}

- (BOOL) haveValues {
    return [[NSFileManager defaultManager] fileExistsAtPath:[self pathToValues]];
}

- (NSArray *) values {
    if (![self haveValues])
        return nil;
    return [NSKeyedUnarchiver unarchiveObjectWithFile:[self pathToValues]];
}

- (void) fetchPlots {
    if ([self havePlots])
        return;
    
    NSString *plotUrl = [NSString stringWithFormat:@"https://oeis.org/%@/graph?png=1", name];
    NSURL *URL = [NSURL URLWithString:plotUrl];
    NSData *plotData = [NSData dataWithContentsOfURL:URL];
    [plotData writeToFile:[self pathToPlotData] atomically:NO];
}

- (NSString *) fetchValues {
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self pathToValues]])
        return nil;
    
#ifdef notdef
    NSString *plotUrl = [NSString stringWithFormat:@"https://oeis.org/%@/graph?png=1", name];
    NSURL *URL = [NSURL URLWithString:plotUrl];
    NSData *plotData = [NSData dataWithContentsOfURL:URL];
    [plotData writeToFile:[self pathToPlotData] atomically:NO];
#endif
    
    NSString *number = [[name substringFromIndex:@"A".length] substringToIndex:@"000000".length];
    NSString *valuesURL = [NSString stringWithFormat:@"https://oeis.org/%@/b%@.txt", name, number];
    NSURL *URL = [NSURL URLWithString:valuesURL];
    NSError *error;
    NSString *contents = [NSString stringWithContentsOfURL:URL
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    NSMutableArray *values;

    if (!contents) {
        valuesUnavailable = YES;    // XXX network might be down, this is too permanent
        return [NSString stringWithFormat:@"OEIS fetch failed: %@", [error localizedDescription]];
    } else {
        NSArray *lines = [contents componentsSeparatedByString:@"\n"];
        
        // two fields, an ordinal, and a (potentially very large) integer
        int lineno = 0;
        for (NSString *line in lines) {
            if ([line isEqualToString:@""])
                continue;
            NSArray *fields = [line componentsSeparatedByString:@" "];
            lineno++;
            if (fields.count != 2) {
                NSLog(@"        %d: value format error: '%@'", lineno, line);
                break;
            }
            number = [fields objectAtIndex:1];
            if (!values)
                values = [[NSMutableArray alloc] initWithCapacity:lines.count];
            [values addObject:@([number integerValue])];
            if (values.count >= MAX_VALUES)
                break;
        }
        valuesUnavailable = NO;
    }
    if (![NSKeyedArchiver archiveRootObject:values
                                     toFile:[self pathToValues]])
        NSLog(@"values save failed");
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self->target valuesFetchedForSequence:self];
    });
    return nil;
}

- (NSString *)fetchOEISMidiFor:(PlayOptions *)options
                        target:(id<midiSequenceProtocol>)caller {
    NSString *midiPath = [self pathToMIDIWithOptions:options];
    if ([[NSFileManager defaultManager] fileExistsAtPath:midiPath]) {
        NSLog(@"** returning cached OEIS MIDI");
        return midiPath;
    }
    
    MIDItarget = caller;
    NSMutableData *body = [NSMutableData data];
    NSString *davesParams = [NSString stringWithFormat:@"midi=1&SAVE=SAVE&seq=%@&bpm=%d&vol=100&voice=%d&velon=80&veloff=80&pmod=88&poff=20&dmod=1&doff=0&cutoff=%d\n",
                             name, options.beatsPerMinute, options.instrumentIndex, MAX_VALUES];
    NSString *appParams  = [NSString stringWithFormat:@"midi=1&SAVE=SAVE&seq=%@&bpm=%d&vol=%d&voice=%d&velon=%d&veloff=%d&pmod=%d&poff=%d&dmod=%d&doff=%d&cutoff=%d\n",
                            name, options.beatsPerMinute, VOL,
                            options.instrumentIndex, VELON, VELOFF, PMOD, POFF, DMOD, DOFF,
                            options.maxLength];
    
    if (![davesParams isEqualToString:appParams]) {
        NSLog(@"%@", davesParams);
        NSLog(@"%@", appParams);
        NSLog(@"param generations not right yet");
    }
    [options dump: @"dave's params"];
    NSLog(@"dave's params: %@", davesParams);
    [body appendData:[davesParams
                      dataUsingEncoding:NSUTF8StringEncoding]];
    
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 30;
    config.HTTPCookieAcceptPolicy = NO;
    //    config.URLCache = NSURLRequestUseProtocolCachePolicy;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSString *midiUrl = [NSString stringWithFormat:@"https://oeis.org/play?seq=%@", name];
    
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:midiUrl]];
    request.HTTPMethod = @"POST";
    request.timeoutInterval = 30;
    request.cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    request.HTTPShouldHandleCookies = NO;
    NSString *postLength = [NSString stringWithFormat:@"%lu", (unsigned long)body.length];
    [request setValue:postLength forHTTPHeaderField:@"Content-Length"];
    
    NSURLSessionUploadTask *uploadTask =
    [session uploadTaskWithRequest:request
                          fromData:body
                 completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                     NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *) response;
                     if ((httpResponse.statusCode / 100) == 2) {
                         [data writeToFile:midiPath atomically:YES];
                         dispatch_async(dispatch_get_main_queue(), ^(void){
                             [self->MIDItarget midiFileReady:midiPath];
                         });
                     } else {
                         NSCharacterSet *trim = [NSCharacterSet characterSetWithCharactersInString:@"\r\n"];
                         NSString *detail = [[[[NSString alloc]
                                               initWithData:data encoding:NSUTF8StringEncoding] componentsSeparatedByCharactersInSet:trim] componentsJoinedByString:@""];
                         NSLog(@"inconceivable: upload error from server: %ld, %@, %@",
                               (long)httpResponse.statusCode,
                               [NSHTTPURLResponse localizedStringForStatusCode: httpResponse.statusCode],
                               detail);
                         [self downloadComplete];
                     }
                 }];
    [uploadTask resume];
    return nil; // no answer available yet
}

#ifdef notdef   // debugging, to compare with David Applegate's results XXXXX
#define BPM     100
#define VOICE   ALTOSAX
#define CUTOFF  4096

- (void) fetchMIDI {
}
#endif

- (NSString *) titleToUse {
    return shortTitle ? shortTitle : title;
}

- (NSString *) subtitleToUse {
    return shortComment ? shortComment : description;
}

- (UIImage *) plotImage {
    NSData *plotImageData = [NSData dataWithContentsOfFile:[self pathToPlotData]];
    if (!plotImageData)
        return nil;
    return [UIImage imageWithData:plotImageData];
}

- (UIImage *) plotIconForWidth:(CGFloat) width {
    UIImage *plotImage = [self plotImage];
    if (!plotImage)
        return nil;
//    CGFloat aspect = plotImage.size.height/plotImage.size.width;
    UIImage *plotIcon = [UIImage imageWithCGImage:plotImage.CGImage
                        scale:width / plotImage.size.width
                  orientation:(plotImage.imageOrientation)];
    return plotIcon;
}

- (void) dump {
    NSLog(@"%@  %@  %@", name, title, description);
    NSLog(@"  (%@  %@)", shortTitle, shortComment);
//    NSLog(@"  %@", values);
}

@end
