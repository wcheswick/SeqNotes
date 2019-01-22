//
//  PlaySeqVC.m
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/MusicPlayer.h>

#import "SeqToMIDI.h"

#import "PlaySeqVC.h"
#import "PlayOptions.h"
#import "Defines.h"

@interface PlaySeqVC ()

@property (nonatomic, strong)   Sequence *sequence;
@property (nonatomic, strong)   UIView *containerView;
@property (nonatomic, strong)   UIScrollView *scrollView;
@property (nonatomic, strong)   PositionView *positionView;
@property (nonatomic, strong)   UIProgressView *progressView;
@property (nonatomic, strong)   AVMIDIPlayer *player;
@property (nonatomic, strong)   UIButton *play;
@property (nonatomic, strong)   NSTimer *checkProgressTimer;
@property (nonatomic, strong)   NSDate *lastPlayerChange;
@property (nonatomic, strong)   NSMutableArray *instrumentList;
@property (nonatomic, strong)   NSMutableDictionary *instrumentNamesToIndex;
@property (nonatomic, strong)   UIPickerView *instrumentPicker;
@property (nonatomic, strong)   PlayOptions *playOptions;
@property (nonatomic, strong)   NSOperationQueue *playerOp;
@property (nonatomic, strong)   UISlider *rateSlider;
@property (nonatomic, strong)   NSData *MIDIFromOEIS;
@property (nonatomic, strong)   NSTimer *recallPlayerChangeTimer;
@property (nonatomic, strong)   UILabel *rateLabel;

@end

@implementation PlaySeqVC

@synthesize sequence;
@synthesize containerView, scrollView;
@synthesize progressView;
@synthesize checkProgressTimer, lastPlayerChange;
@synthesize positionView;
@synthesize recallPlayerChangeTimer;
@synthesize player, play;
@synthesize instrumentList, instrumentNamesToIndex;
@synthesize instrumentPicker;
@synthesize playOptions;
@synthesize playerOp;
@synthesize rateSlider;
@synthesize rateLabel;
@synthesize MIDIFromOEIS;

- (id)initWithSequence:(Sequence *)s width:(CGFloat) w {
    self = [super init];
    if (self) {
        sequence = s;
        playerOp = nil;
        // these must not be released until we are done with a player switch
        [self loadInstruments];
        
        playOptions = [NSKeyedUnarchiver unarchiveObjectWithFile:PLAY_OPTIONS_ARCHIVE];
        if (!playOptions) {
            playOptions = [[PlayOptions alloc] init];
            [playOptions save];
        }
        
        containerView = [[UIView alloc]
                         initWithFrame:CGRectMake(INSET, INSET, w - 2*INSET, LATER)];
        containerView.backgroundColor = [UIColor whiteColor];
        
        UIView *soundControlView = [[UIView alloc] init];
        soundControlView.frame = CGRectMake(0, 0, containerView.frame.size.width, 2*LARGE_H - 2);
        soundControlView.userInteractionEnabled = YES;
        soundControlView.backgroundColor = [UIColor whiteColor];
        
        play = [UIButton buttonWithType:UIButtonTypeRoundedRect];
        CGRect f;
        f.origin = CGPointMake(0, 0);
        f.size.height = soundControlView.frame.size.height;
        f.size.width = f.size.height*1.4;
        play.frame = f;
        f.origin.x = RIGHT(f) + 20;
        [play setTitle:@"▶️" forState:UIControlStateNormal];
        [play setTitle:@"॥" forState:UIControlStateSelected];
        play.titleLabel.font = [UIFont boldSystemFontOfSize:f.size.height - 8];
        [play addTarget:self
                 action:@selector(doPlay:)
       forControlEvents:UIControlEventTouchUpInside];
        play.backgroundColor = [UIColor whiteColor];
        play.layer.borderWidth = 1.0;
        play.layer.cornerRadius = 3.0;
        play.layer.borderColor = [UIColor whiteColor].CGColor;
        [soundControlView addSubview:play];
        
        UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]
                                                   initWithTarget:self
                                                   action:@selector(longPressPlay:)];
        longPress.minimumPressDuration = 1.0;
        [play addGestureRecognizer:longPress];

        f.size.width = soundControlView.frame.size.width - f.origin.x;
        f.size.height = play.frame.size.height;
        positionView = [[PositionView alloc] initWithFrame:f];
        positionView.target = self;
        positionView.backgroundColor = [UIColor greenColor];
        [soundControlView addSubview:positionView];

        // The picker chooses its own height
        instrumentPicker = [[UIPickerView alloc] init];
        SET_VIEW_Y(instrumentPicker, BELOW(soundControlView.frame));
        SET_VIEW_X(instrumentPicker, (containerView.frame.size.width - instrumentPicker.frame.size.width)/2.0);
        instrumentPicker.delegate = self;
        [instrumentPicker selectRow:playOptions.instrumentIndex inComponent:0 animated:NO];
//        instrumentPicker.layer.borderWidth = 0.5;
//        instrumentPicker.layer.borderColor = [UIColor orangeColor].CGColor;
 //       instrumentPicker.layer.cornerRadius = 5.0;
        instrumentPicker.backgroundColor = [UIColor whiteColor];
        [soundControlView addSubview:instrumentPicker];

#define RATE_LABEL_FONT_SIZE    SMALL_LABEL_FONT_SIZE
#define RATE_H          (RATE_LABEL_FONT_SIZE*3.5)
        
#define RATE_LABEL_W    ((RATE_LABEL_FONT_SIZE*0.8)*16)
        
        rateLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, BELOW(instrumentPicker.frame) + SEP,
                                                              RATE_LABEL_W, RATE_H)];
        rateLabel.attributedText = nil;
        rateLabel.font = [UIFont systemFontOfSize:RATE_LABEL_FONT_SIZE];
        rateLabel.lineBreakMode = NSLineBreakByWordWrapping;
        rateLabel.numberOfLines = 0;
        rateLabel.backgroundColor = [UIColor whiteColor];
        [self showRate];
        [soundControlView addSubview:rateLabel];

        rateSlider = [[UISlider alloc] initWithFrame:rateLabel.frame];
        SET_VIEW_X(rateSlider, RIGHT(rateLabel.frame) + SEP);
        SET_VIEW_WIDTH(rateSlider, soundControlView.frame.size.width - rateSlider.frame.origin.x);
        rateSlider.minimumValue = 24;   // Larghissimo
        rateSlider.maximumValue = 200;  // Prestissimo
        rateSlider.value = playOptions.beatsPerMinute;
        [rateSlider addTarget:self action:@selector(doChangeRate:) forControlEvents:UIControlEventValueChanged];
        rateSlider.layer.borderWidth = 0.5;
        rateSlider.layer.borderColor = [UIColor lightGrayColor].CGColor;
        rateSlider.layer.cornerRadius = 5.0;
        [soundControlView addSubview:rateSlider];

        SET_VIEW_HEIGHT(soundControlView, BELOW(rateSlider.frame) + SEP);
        [containerView addSubview:soundControlView];
        
        SET_VIEW_HEIGHT(containerView, BELOW(soundControlView.frame));

#ifdef notdef
        if (sequence.plotData) {
            UIImage *plotImage = [UIImage imageWithData:sequence.plotData];
            UIImageView *plotsView = [[UIImageView alloc] initWithImage:plotImage];
            plotsView.contentMode = UIViewContentModeScaleAspectFit;
            CGFloat aspect = plotImage.size.height/plotImage.size.width;
            plotsView.frame = CGRectMake(0, BELOW(soundControlView.frame) + 3*SEP,
                                         self.view.frame.size.width, self.view.frame.size.width*aspect);
            [containerView addSubview:plotsView];
            SET_VIEW_HEIGHT(containerView, BELOW(plotsView.frame));
        } else {
            SET_VIEW_HEIGHT(containerView, BELOW(soundControlView.frame));
        }
        
        scrollView = [[UIScrollView alloc] init];
        scrollView.pagingEnabled = NO;
        scrollView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        scrollView.showsVerticalScrollIndicator = YES;
        scrollView.userInteractionEnabled = YES;
        scrollView.exclusiveTouch = NO;
        scrollView.bounces = NO;
        scrollView.delaysContentTouches = YES;
        scrollView.canCancelContentTouches = YES;
        [scrollView addSubview:containerView];
        
        SET_VIEW_WIDTH(containerView, scrollView.frame.size.width);
        scrollView.contentSize = containerView.frame.size;
        
        [self.view addSubview:scrollView];
#endif
        [self.view addSubview:containerView];
        
        self.view.frame = CGRectMake(0, LATER,
                                     w, containerView.frame.size.height + INSET);

        self.view.backgroundColor = [UIColor whiteColor];
    }
    return self;
}

// table adopted from https://en.wikipedia.org/wiki/Tempo
// Not perfect, but close enough

static struct rateTable {
    char *name;
    int rate;       // fastest rate, except the last
} rateTable[] = {
    {"Larghissimo",    24},
    {"Grave",    25},
    {"Lento",    45},
    {"Larghetto",    60},
    {"Adagio",    66},
    {"Andante",    76},
    {"Andante moderato",    92},
    {"Allegretto",    112},
    {"Allegro moderato",    116},
    {"Allegro",    120},
    {"Vivace",    156},
    {"Presto",    168},
    {"Prestissimo",    200},
    {0, 1000},
};

- (void) showRate {
    UIFontDescriptor *fontDesc = [rateLabel.font.fontDescriptor
                               fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    UIFont *italicsFont = [UIFont fontWithDescriptor:fontDesc size:rateLabel.font.pointSize];
    NSDictionary *italicsAttributes = @{ NSFontAttributeName: italicsFont };
    
    NSMutableAttributedString *rateString = [[NSMutableAttributedString alloc]
                                             initWithString:[NSString stringWithFormat:@"   ♩/min: %d\n  Tempo: ",
                                                             playOptions.beatsPerMinute]];
    int i;
    for (i=0; rateTable[i].name; i++) {
        if (playOptions.beatsPerMinute < rateTable[i+1].rate)
            break;
    }
    NSMutableAttributedString *tempoName = [[NSMutableAttributedString alloc]
                                            initWithString:[NSString stringWithUTF8String:rateTable[i].name]];
    NSLog(@" name: %s", rateTable[i].name);
    [tempoName setAttributes:italicsAttributes range:(NSRange){0,tempoName.length}];
    [rateString appendAttributedString:tempoName];
    rateLabel.attributedText = rateString;
    [rateLabel setNeedsDisplay];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = NO;
//    self.navigationController.navigationBar.opaque = YES;
    self.title = sequence.name;
    player = nil;
    checkProgressTimer = nil;
    lastPlayerChange = nil;
    recallPlayerChangeTimer = nil;
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doDone:)];
    self.navigationItem.leftBarButtonItem = leftBarButton;
    SET_VIEW_Y(self.view, BELOW(self.navigationController.navigationBar.frame));
    NSLog(@"svc vdl: %@", NSStringFromCGRect(self.view.frame));
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGFloat top = self.navigationController.navigationBar.frame.size.height;
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone) {
        top += [UIApplication sharedApplication].statusBarFrame.size.height;
    }
    SET_VIEW_Y(containerView, top);
}

#define PICKER_W    200

- (CGFloat)pickerView:(UIPickerView *)pickerView
    widthForComponent:(NSInteger)component {
    return PICKER_W;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
    return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView
numberOfRowsInComponent:(NSInteger)component {
    assert(component == 0);
    return instrumentList.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView
             titleForRow:(NSInteger)row
            forComponent:(NSInteger)component {
    NSString *pickedName = [instrumentList objectAtIndex:row];
    NSString *label = [NSString stringWithFormat:@"%3ld  %@", row+1, pickedName];
//    NSLog(@"picked instrument %@ at index %ld", pickedName, (long)row);
    return label;
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    NSString *pickedName = [instrumentList objectAtIndex:row];
    NSLog(@"Picked instrument %@ at index %ld", pickedName, (long)row);
    playOptions.instrumentIndex = (int32_t)row;
    [playOptions save];
    [self switchToNewPlayer];
}

- (IBAction)doPlay:(UIView *)sender {
    if (!play.selected) {
        if (!player) {
            player = [self makePlayer];
        }
        if (player.currentPosition >= player.duration) {
            player.currentPosition = 0;
            [self showCurrentPlayingPosition];
        }
        [self startPlayer];
    } else {
        [self pausePlayer];
    }
}

- (IBAction)doPlayOEIS:(UIView *)sender {
    if (!play.selected) {
        if (!player) {
            player = [self makePlayer];
        }
        if (player.currentPosition >= player.duration) {
            NSLog(@"reset position to start");
            player.currentPosition = 0;
            [self showCurrentPlayingPosition];
        }
        [self startPlayer];
    } else {
        [self pausePlayer];
    }
}

- (void)longPressPlay:(UILongPressGestureRecognizer*)gesture {
    if (gesture.state == UIGestureRecognizerStateEnded ) {
        NSString *path = [sequence fetchOEISMidiFor:playOptions target:self];
        if (path) { // ready for comparison, do it now
            NSLog(@"OEIS file for %@ already present", sequence.name);
            [self midiFileReady:path];
        }   // else await download
        NSLog(@"fetching OEIS MIDI");
    }
    return;
}

// returns here when ready

- (void) midiFileReady:(NSString *) OEISMidiPath {
    NSLog(@"OEIS file for %@ fetched", sequence.name);
    [self CheckMIDIMatches:OEISMidiPath];
}

- (void) CheckMIDIMatches:(NSString *)OEISMidiPath {
    MIDIFromOEIS = [NSData dataWithContentsOfFile:OEISMidiPath];
    if (!MIDIFromOEIS)
        return;
    NSString *ourMIDIFile = [self genMIDIToFile];
    NSData *ourMIDI = [NSData dataWithContentsOfFile:ourMIDIFile];
    
    if (MIDIFromOEIS.length != ourMIDI.length || ![ourMIDI isEqualToData:MIDIFromOEIS]) {
        NSLog(@" *** MIDIs do not match ***");
        //            if (sequence.midiData.length != myMIDI.length) {
        //                NSLog(@"midi data length mismatch");
        //                NSLog(@"David's midi: %lu", (unsigned long)sequence.midiData.length);
        //                NSLog(@"     My midi: %lu", (unsigned long)myMIDI.length);
        //           } else {
        NSString *errors = [NSString stringWithFormat:@"OEIS len: %lu\n"
                            @" our len: %lu\n"
                            @"%@\n", (unsigned long)MIDIFromOEIS.length, (unsigned long)ourMIDI.length,
                            MIDIFromOEIS.length != ourMIDI.length ? @"  ** length mismatch\n" : @""];
        
        const u_char *a = ourMIDI.bytes;
        const u_char *b = MIDIFromOEIS.bytes;
        NSString *firstMismatch = nil;
        size_t errCount = 0;
        for (size_t i=0; i<MIN(ourMIDI.length, MIDIFromOEIS.length); i++)
            if (a[i] != b[i]) {
                if (!firstMismatch) {
                    firstMismatch = [NSString
                                     stringWithFormat:@"first difference at byte %zul (%zx) of %zul: %02x %02x",
                                     i, i, ourMIDI.length, b[i], a[i]];
                    NSLog(@"first difference at byte %zul of %zul", i, ourMIDI.length);
                }
                errCount++;
            }
        errors = [NSString stringWithFormat:@"%@\n%@\n%zu bytes different\n",
                  errors, firstMismatch, errCount];
        
        for (NSString *line in [errors componentsSeparatedByString:@"\n"])
            NSLog(@"%@", line);
        
        UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"App/OEIS MIDI mismatch"
                                                                       message:errors
                                                                preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction* mailAction = [UIAlertAction actionWithTitle:@"Mail MIDI files"
                                                             style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  [self mail:OEISMidiPath and:ourMIDIFile errors:errors];
                                                              }
                                     ];
        [alert addAction:mailAction];

        UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Dismiss"
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * action) {
                                                                  ;
                                                              }
                                        ];
        [alert addAction:defaultAction];
        [self presentViewController:alert animated:YES completion:nil];
        play.layer.borderColor = [UIColor redColor].CGColor;
        return;
    }
    NSLog(@"App and Dave agree on MIDI");
    play.layer.borderColor = [UIColor blueColor].CGColor;
    return;
}

- (void) mail:(NSString *) officialMIDIFile and:(NSString *)appMIDIFile errors:(NSString *)errors {
    NSString *emailTitle = [NSString stringWithFormat:@"Mismatching MIDI files for %@",
                            sequence.name];
    NSString *messageBody = [@"The app's generated MIDI doesn't match David Applegate's MIDI from OEIS.\n"
                             stringByAppendingString:errors];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setToRecipients:[NSArray arrayWithObjects:@"bc@cheswick.com", nil]];
    [mc setMessageBody:messageBody isHTML:NO];
    
    NSString *officialName = [[[officialMIDIFile lastPathComponent]
                               stringByDeletingPathExtension]
                              stringByAppendingPathExtension:@"dat"];
    [mc addAttachmentData:[NSData dataWithContentsOfFile:officialMIDIFile]
                 mimeType:@"text/plain"
                 fileName:officialName];
    
    NSString *ourName = [@"ShowSeq-" stringByAppendingString: officialName];
    [mc addAttachmentData:[NSData dataWithContentsOfFile:appMIDIFile]
                 mimeType:@"text/plain"
                 fileName:ourName];
    
    // Present mail view controller on screen
    [self presentViewController:mc animated:YES completion:NULL];
}

- (void) mailComposeController:(MFMailComposeViewController *)controller
           didFinishWithResult:(MFMailComposeResult)result
                         error:(NSError *)error {
    if (error)
        NSLog(@"mail error %@", [error localizedDescription]);
    switch (result) {
        case MFMailComposeResultCancelled:
            break;
        case MFMailComposeResultSaved:
            break;
        case MFMailComposeResultSent:
            break;
        case MFMailComposeResultFailed: {
            NSLog(@"Mail sent failure: %@", [error localizedDescription]);
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Mail failed"
                                                                           message:nil
                                                                    preferredStyle:UIAlertControllerStyleAlert];
            
            UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault
                                                                  handler:^(UIAlertAction * action) {}];
            
            [alert addAction:defaultAction];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
        default:
            NSLog(@"inconceivable: unknown mail result %ld", (long)result);
            break;
    }
    
    // Close the Mail Interface
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (void) pausePlayer {
    if (player) {
        NSLog(@" paused at %.3f", player.currentPosition);
        [player stop];
    }
    [checkProgressTimer invalidate];
    checkProgressTimer = nil;
    play.selected = NO;
    [play setNeedsDisplay];
}

- (void) discardPlayer {
    [self pausePlayer];
    NSLog(@"player discarded");
    player = nil;
}

- (void) newPosition:(float) newPosition {
    if (player.currentPosition == newPosition)
        return;
    player.currentPosition = newPosition;
    NSLog(@"current position set to %.3f", player.currentPosition);
    [self showCurrentPlayingPosition];
}

- (IBAction)doChangeRate:(UIView *)sender {
    UISlider *slider = (UISlider *)sender;
    playOptions.beatsPerMinute = slider.value;
    [playOptions save];
    NSLog(@"new rate: %d bpm", playOptions.beatsPerMinute);
    [self switchToNewPlayer];
    [self showRate];
}

- (AVMIDIPlayer *) makePlayer { // from current instrument and rate settings
    OSStatus rc;
    
    NSString *bankPath = [[NSBundle mainBundle]
                          pathForResource:@"GeneralUser GS MuseScore v1.442"
                          ofType:@"sf2"];
    if (!bankPath) {
        NSLog(@"inconceivable, soundsfont file is missing");
        return nil;
    }
    NSURL *bankURL = [NSURL fileURLWithPath:bankPath];
    
    MusicSequence s;
    NewMusicSequence(&s);
    
    NSString *midiTmp = [self genMIDIToFile];
    NSData *newMIDI = [NSData dataWithContentsOfFile:midiTmp];
    [[NSFileManager defaultManager] removeItemAtPath:midiTmp error:nil];

    rc = MusicSequenceFileLoadData (s, (__bridge CFDataRef _Nonnull)(newMIDI),
                                    0, 0);
    if (rc) {
        [self musicError:@"MusicSequenceFileLoadData" err:rc];
        return nil;
    }
    
    NSError *error;
    
    // This uses some 80 MB:
    AVMIDIPlayer *newPlayer = [[AVMIDIPlayer alloc] initWithData:newMIDI
                                                    soundBankURL:bankURL
                                                           error:&error];
    if (error) {
        NSLog(@"player initialization error: %@", [error localizedDescription]);
        return nil;
    }
    NSLog(@"New player ...");
    return newPlayer;
}

// Generate a new player from current play settings, turn of the old, if any, and
// fire up the new one in the same place.  Regen the MIDI if necessary.
//
// If we do this too fast, the kernel gets upset, so limit the update rate.

#define MIN_UPDATE_TIME 0.25     // seconds

- (void) switchToNewPlayer {
    NSTimeInterval dt = -[lastPlayerChange timeIntervalSinceNow];
    if (lastPlayerChange && dt < MIN_UPDATE_TIME) {    // wait a bit
        NSLog(@"player change too fast, need %.3f seconds", MIN_UPDATE_TIME - dt);
        recallPlayerChangeTimer = [NSTimer timerWithTimeInterval:MIN_UPDATE_TIME - dt
                                                                  repeats:NO
                                                                    block:^(NSTimer * _Nonnull timer) {
                                                                        [self switchToNewPlayer];
                                                                    }
                                            ];
        return;
    }
    recallPlayerChangeTimer = nil;
    
    float currentPosition = -1;   // >= 0 if we are playing
    if (player) {   // Do we have a current player?
        if (player.playing) {   // if it is playing, stop it
            currentPosition = player.currentPosition;
            [self pausePlayer];
            [player stop];
        }
    }
    
    player = [self makePlayer];
    if (!player) {
        NSLog(@" ** inconceivable, player creation error");
        return;
    }
    lastPlayerChange = [NSDate date];
    player.currentPosition = currentPosition >= 0 ? currentPosition : 0;
    [self startPlayer];
}

- (IBAction)playerUpdateOK:(id)sender {
    NSTimer *caller = (NSTimer *)sender;
    NSLog(@"delayed switch to new player");
    [caller invalidate];
    [self switchToNewPlayer];
}

- (void) startPlayer {
    positionView.duration = player.duration;
    positionView.position = player.currentPosition;
    playerOp = [[NSOperationQueue alloc] init];
    [playerOp addOperationWithBlock: ^{
        NSLog(@"start/resume playing at %.3f", self.player.currentPosition);
        [self.player play:^(void) {
            //            NSLog(@"playing complete");
            //            dispatch_async(dispatch_get_main_queue(), ^(void) {
            //                [self pausePlayer];
        }];
    }];
    
    [self showCurrentPlayingPosition];
    self.play.selected = YES;
    [self.play setNeedsDisplay];
    self.checkProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                                               target:self
                                                             selector:@selector(tick)
                                                             userInfo:nil
                                                              repeats:YES];
}

- (void) tick {
    [self showCurrentPlayingPosition];
}

- (void) showCurrentPlayingPosition {
    positionView.position = self.player.currentPosition;
}

- (long *) makeArray {
    static long *sequenceArray = 0;
    NSArray *values = [sequence values];
    sequenceArray = (long *)malloc(sizeof(long)*values.count);
    assert (sequenceArray);
    for (size_t i=0; i<values.count; i++) {
        NSNumber *n = [values objectAtIndex:i];
        sequenceArray[i] = [n longValue];
    }
    return sequenceArray;
}

- (NSString *) genMIDIToFile {
    NSString *midiTmp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"midi.tmp"];
    NSFileManager *mgr = [NSFileManager defaultManager];
    if (![mgr fileExistsAtPath:midiTmp])
        [mgr createFileAtPath:midiTmp contents:nil attributes:nil];
    NSFileHandle *midiFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:midiTmp];
    
    long *valueArray = [self makeArray];
    [playOptions dump:@"generate MIDI with options"];
    seqToMidi(midiFileHandle.fileDescriptor, valueArray, sequence.values.count,
              1, 1, 1,
              (int)playOptions.beatsPerMinute,
              0, VOL,
              (int)playOptions.instrumentIndex,
              VELON, VELOFF,
              PMOD, POFF, DMOD, DOFF, MAX_VALUES);
    [midiFileHandle closeFile];
    free(valueArray);
    valueArray = 0;
    return midiTmp;
}

- (void) musicError:(NSString *) mesg err:(OSStatus) rc {
    switch (rc) {
        case kAudioToolboxErr_InvalidPlayerState:
            NSLog(@"%@ failed: bad player state", mesg);
            break;
        default:
            NSLog(@"%@ failed: %d", mesg, (int)rc);
    }
}

- (IBAction)doDone:(UISwipeGestureRecognizer *)sender {
    [self discardPlayer];
    [self dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) loadInstruments {
    NSString *instrumentPath = [[NSBundle mainBundle]
                                pathForResource:@"InstrumentList"ofType:@""];
    if (!instrumentPath) {
        NSLog(@"Instrument list missing, inconceivable");
        return;
    }
    
    NSError *error;
    NSString *instrumentFileContents = [NSString stringWithContentsOfFile:instrumentPath
                                                                 encoding:NSUTF8StringEncoding
                                                                    error:&error];
    if (!instrumentFileContents || [instrumentFileContents isEqualToString:@""] || error) {
        NSLog(@"instrumentFileContents list error: %@", [error localizedDescription]);
        return;
    }
    instrumentList = [[NSMutableArray alloc] init];
    instrumentNamesToIndex = [[NSMutableDictionary alloc] init];
    
    // Entries look like this:
    //    # from echo "inst 1" | fluidsynth "GeneralUser GS MuseScore v1.442.sf2"
    //    000-000 Stereo Grand
    //    000-001 Bright Grand
    
    NSArray *lines = [instrumentFileContents componentsSeparatedByString:@"\n"];
    if (lines.count == 0) {
        NSLog(@"instrumentFileContents list is empty");
        return;
    }
    size_t index = 0;
    for (NSString *line in lines) {
        if ([line hasPrefix:@"#"] || line.length == 0)
            continue;
        NSString *bank = [line substringWithRange:NSMakeRange(0, 3)];
        if (![bank isEqualToString:@"000"])
            continue;
        // assume all present, and sequential
        NSString *name = [line substringFromIndex:@"000-000 ".length];
        [instrumentList addObject:[line substringFromIndex:@"000-000 ".length]];
        [instrumentNamesToIndex setObject:[NSNumber numberWithLong:index++] forKey:name];
    }
    NSLog(@"Instruments read: %lu", (unsigned long)instrumentList.count);
}

@end
