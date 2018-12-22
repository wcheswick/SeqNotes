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

@synthesize seq, name, description;
@synthesize shortTitle, shortComment;
@synthesize values;
@synthesize plotData, midiData;
@synthesize target;

- (id)initSequence: (NSString *)s {
    self = [super init];
    if (self) {
        seq = s;
        name = description = @"";
        shortTitle = shortComment = nil;
        plotData = midiData = nil;
        values = nil;
        target = nil;
    }
    return self;
}

- (void) loadDataFromOEIS {
    NSLog(@"fetching sequence %@", seq);
    if (![self fetchFromOEIS])
        return;
    [self fetchPlots];
//    [self fetchMIDI];
}

#define kSeq    @"Seq"
#define kName   @"Name"
#define kDescription    @"Description"
#define kShortTitle     @"ShortTitle"
#define kShortComment   @"ShortComment"
#define kValues         @"Values"
#define kPlotData       @"PlotData"
#define kMidiData       @"MidiData"

- (id) initWithCoder: (NSCoder *)coder {
    self = [super init];
    if (self) {
        seq = [coder decodeObjectForKey: kSeq];
        name = [coder decodeObjectForKey: kName];
        description = [coder decodeObjectForKey: kDescription];
        shortTitle = [coder decodeObjectForKey: kShortTitle];
        shortComment = [coder decodeObjectForKey: kShortComment];
        values = [coder decodeObjectForKey:kValues];
        plotData = [coder decodeObjectForKey:kPlotData];
        midiData = [coder decodeObjectForKey:kMidiData];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:seq forKey:kSeq];
    [coder encodeObject:name forKey:kName];
    [coder encodeObject:description forKey:kDescription];
    [coder encodeObject:shortTitle forKey:kShortTitle];
    [coder encodeObject:shortComment forKey:kShortComment];
    [coder encodeObject:values forKey:kValues];
    [coder encodeObject:plotData forKey:kPlotData];
    [coder encodeObject:midiData forKey:kMidiData];
}

- (void) loadDataFromOEIS:(id<sequenceProtocol>)caller {
    target = caller;
    NSLog(@"%@ fetch from OEIS ...", seq);
    [self fetchFromOEIS];
    NSLog(@"    fetch plots ...");
    [self fetchPlots];
    NSLog(@"    ... plot size is %lu; fetch values ...", (unsigned long)plotData.length);
    [self fetchValues];
    NSLog(@"    ... number of values: %lu; fetch MIDI ...",  (unsigned long)values.count);
    [self fetchMIDI];   // calls downloadComplete when finished
}

- (void) downloadComplete {
    NSLog(@"    ... MIDI length %lu, fetch complete", (unsigned long)midiData.length);
    dispatch_async(dispatch_get_main_queue(), ^(void){
        [self->target addSequence:self];
    });
}

- (void) fetchPlots {
    NSString *plotUrl = [NSString stringWithFormat:@"https://oeis.org/%@/graph?png=1", seq];
    NSURL *URL = [NSURL URLWithString:plotUrl];
    plotData = [NSData dataWithContentsOfURL:URL];
}

- (BOOL) fetchFromOEIS {
    NSString *url = [NSString stringWithFormat:@"https://oeis.org/search?q=id:%@&fmt=text", seq];
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
        } else if ([line hasPrefix:@"%N"]) {   // name
            name = data;
        }
    }
    return YES;
}

- (void) appendNumbers: (NSString *) list {
    NSArray *numbers = [list componentsSeparatedByString:@","];
    for (NSString *number in numbers) {
        if (![number isEqualToString:@""]) {
            [values addObject:@([number integerValue])];
        }
    }
}

- (void) fetchValues {
    NSString *number = [[seq substringFromIndex:@"A".length] substringToIndex:@"000000".length];
    NSString *plotUrl = [NSString stringWithFormat:@"https://oeis.org/%@/b%@.txt", seq, number];
    NSURL *URL = [NSURL URLWithString:plotUrl];
    NSError *error;
    NSString *contents = [NSString stringWithContentsOfURL:URL
                                                  encoding:NSUTF8StringEncoding
                                                     error:&error];
    if (!contents) {
        NSLog(@"OEIS values load failed for %@: %@", seq, [error localizedDescription]);
        return;
    }
    NSArray *lines = [contents componentsSeparatedByString:@"\n"];
    //    NSLog(@" number of text lines for %@: %lu", seq, (unsigned long)lines.count);
    
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
}

- (void) fetchMIDI {
    NSMutableData *body = [NSMutableData data];
    NSString *davesParams = [NSString stringWithFormat:@"midi=1&SAVE=SAVE&seq=%@&bpm=100&vol=100&voice=%d&velon=80&veloff=80&pmod=88&poff=20&dmod=1&doff=0&cutoff=%d\n",
                             seq, VOICE, MAX_VALUES];
    NSString *appParams  = [NSString stringWithFormat:@"midi=1&SAVE=SAVE&seq=%@&bpm=%d&vol=%d&voice=%d&velon=%d&veloff=%d&pmod=%d&poff=%d&dmod=%d&doff=%d&cutoff=%d\n",
                           seq, BPM, VOL, VOICE, VELON, VELOFF, PMOD, POFF, DMOD, DOFF, MAX_VALUES];
    
    if (![davesParams isEqualToString:appParams]) {
        NSLog(@"%@", davesParams);
        NSLog(@"%@", appParams);
        NSLog(@"param generations not right yet");
    }
    [body appendData:[davesParams
                      dataUsingEncoding:NSUTF8StringEncoding]];
    
    midiData = [[NSMutableData alloc] init];

    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    config.timeoutIntervalForRequest = 30;
    config.HTTPCookieAcceptPolicy = NO;
//    config.URLCache = NSURLRequestUseProtocolCachePolicy;
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSString *midiUrl = [NSString stringWithFormat:@"https://oeis.org/play?seq=%@", seq];
    
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
                         self->midiData = data;
                         [self downloadComplete];
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
}

- (NSString *) titleToUse {
    return shortTitle ? shortTitle : name;
}

- (NSString *) subtitleToUse {
    return shortComment ? shortComment : description;
}

- (void) dump {
    NSLog(@"%@  %@  %@", seq, name, description);
    NSLog(@"  (%@  %@)", shortTitle, shortComment);
    NSLog(@"  %@", values);
}

@end
