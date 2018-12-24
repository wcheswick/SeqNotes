//
//  ShowSeqVC.m
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import <AudioToolbox/MusicPlayer.h>

#import "SeqToMIDI.h"

#import "ShowSeqVC.h"
#import "PlayOptions.h"
#import "Defines.h"

@interface ShowSeqVC ()

@property (nonatomic, strong)   Sequence *sequence;

@property (nonatomic, strong)   UIView *containerView;
@property (nonatomic, strong)   UIScrollView *scrollView;
@property (nonatomic, strong)   UISlider *musicSlider;
@property (nonatomic, strong)   UIProgressView *progressView;
@property (nonatomic, strong)   AVMIDIPlayer *player;
@property (nonatomic, strong)   NSData *oldMIDI, *currentMIDI;
@property (nonatomic, strong)   UIButton *play;
@property (nonatomic, strong)   NSTimer *checkProgressTimer;
@property (nonatomic, strong)   NSMutableArray *instrumentList;
@property (nonatomic, strong)   UIPickerView *instrumentPicker;
@property (nonatomic, strong)   PlayOptions *playOptions;
@property (nonatomic, strong)   NSOperationQueue *playerOp;
@property (nonatomic, strong)   UISlider *rateSlider;

@end

@implementation ShowSeqVC

@synthesize sequence;
@synthesize containerView, scrollView;
@synthesize progressView;
@synthesize checkProgressTimer;
@synthesize musicSlider;
@synthesize player, play;
@synthesize instrumentList;
@synthesize instrumentPicker;
@synthesize playOptions;
@synthesize playerOp;
@synthesize rateSlider;
@synthesize oldMIDI, currentMIDI;

- (id)initWithSequence: (Sequence *)s {
    self = [super init];
    if (self) {
        sequence = s;
        playerOp = nil;
        // these must not be released until we are done with a player switch
        oldMIDI = currentMIDI = nil;
        [self loadInstruments];
        
        playOptions = [NSKeyedUnarchiver unarchiveObjectWithFile:PLAY_OPTIONS_ARCHIVE];
        if (!playOptions) {
            playOptions = [[PlayOptions alloc] init];
            [playOptions save];
        }
    }
    return self;
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
    

    // Entries look like this:
    //    # from echo "inst 1" | fluidsynth "GeneralUser GS MuseScore v1.442.sf2"
    //    000-000 Stereo Grand
    //    000-001 Bright Grand
    
    NSArray *lines = [instrumentFileContents componentsSeparatedByString:@"\n"];
    if (lines.count == 0) {
        NSLog(@"instrumentFileContents list is empty");
        return;
    }
    for (NSString *line in lines) {
        if ([line hasPrefix:@"#"] || line.length == 0)
            continue;
        NSString *bank = [line substringWithRange:NSMakeRange(0, 3)];
        if (![bank isEqualToString:@"000"])
            continue;
        // assume all present, and sequential
        NSString *name = [line substringFromIndex:@"000-000 ".length];
        [instrumentList addObject:name];
    }
    NSLog(@"Instruments read: %lu", (unsigned long)instrumentList.count);
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.opaque = YES;
    self.title = sequence.seq;
    player = nil;
    checkProgressTimer = nil;
    
    UIBarButtonItem *leftBarButton = [[UIBarButtonItem alloc]
                                      initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                      target:self action:@selector(doDone:)];
    self.navigationItem.leftBarButtonItem = leftBarButton;
    
    containerView = [[UIView alloc] init];
    containerView.frame = CGRectMake(0, 0, LATER, LATER);

    UILabel *titleView = [[UILabel alloc] init];
    titleView.text = [sequence titleToUse];
    titleView.font = [UIFont systemFontOfSize:LARGE_FONT_SIZE];
    titleView.numberOfLines = 0;
    titleView.lineBreakMode = NSLineBreakByWordWrapping;
    titleView.frame = CGRectMake(0, 0, self.view.frame.size.width, 3*LARGE_H);
    [containerView addSubview:titleView];

    UILabel *descriptionView = [[UILabel alloc] init];
    descriptionView.text = [sequence subtitleToUse];
    descriptionView.lineBreakMode = NSLineBreakByWordWrapping;
    descriptionView.font = [UIFont systemFontOfSize:LABEL_FONT_SIZE];
    descriptionView.numberOfLines = 0;
    descriptionView.lineBreakMode = NSLineBreakByWordWrapping;
    descriptionView.frame = CGRectMake(0, BELOW(titleView.frame) + SEP,
                                       self.view.frame.size.width, 4*LABEL_H);
    [containerView addSubview:descriptionView];
    
    UIView *soundControlView = [[UIView alloc] init];
    soundControlView.frame = CGRectMake(0, BELOW(descriptionView.frame) + SEP,
                                        self.view.frame.size.width, LATER);
    
    play = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    CGRect f;
    f.origin.x = 0;
    f.size.height = 2*LARGE_H - 2;
    f.origin.y = 2;
    f.size.width = f.size.height*1.4;
    play.frame = f;
    [play setTitle:@"▶️" forState:UIControlStateNormal];
    [play setTitle:@"॥" forState:UIControlStateSelected];
    play.titleLabel.font = [UIFont boldSystemFontOfSize:f.size.height - 8];
    [play addTarget:self
             action:@selector(doPlay:)
    forControlEvents:UIControlEventTouchUpInside];
    [soundControlView addSubview:play];
    
    musicSlider = [[UISlider alloc] init];
    f.origin.x = RIGHT(f) + 20;
    f.origin.y = 0;
    f.size.width = 250;
    f.size.height = play.frame.size.height;
    musicSlider.frame = f;
    musicSlider.hidden = NO;
    musicSlider.minimumValue = 0.0;
    musicSlider.maximumValue = 1.0;
    [musicSlider addTarget:self action:@selector(doChangePosition:) forControlEvents:UIControlEventValueChanged];
    UIImage *smallNote = [UIImage imageWithContentsOfFile:[[NSBundle mainBundle]
                                          pathForResource:@"smallnote"
                                                   ofType:@"png"]];
    UIImage *scaledImage = [UIImage imageWithCGImage:smallNote.CGImage
                        scale:10 //(smallNote.scale * f.size.height/smallNote.size.height)
                  orientation:(smallNote.imageOrientation)];
    [musicSlider setThumbImage:scaledImage forState:UIControlStateNormal];
    [soundControlView addSubview:musicSlider];

    instrumentPicker = [[UIPickerView alloc] init];
    instrumentPicker.frame = CGRectMake(0, BELOW(musicSlider.frame),
                                        RIGHT(musicSlider.frame), 100);
    instrumentPicker.delegate = self;
    [instrumentPicker selectRow:playOptions.instrumentIndex inComponent:0 animated:NO];
#ifdef notdef
    instrumentPicker.layer.borderWidth = 0.5;
    instrumentPicker.layer.borderColor = [UIColor lightGrayColor].CGColor;
    instrumentPicker.layer.cornerRadius = 5.0;
#endif
    [soundControlView addSubview:instrumentPicker];
    
    rateSlider = [[UISlider alloc] init];
    f = instrumentPicker.frame;
    f.origin.y = BELOW(f) + SEP;
    f.size.height = musicSlider.frame.size.height;
    rateSlider.frame = f;
    rateSlider.minimumValue = 24;   // Larghissimo
    rateSlider.maximumValue = 200;  // Prestissimo
    rateSlider.value = playOptions.beatsPerMinute;
    [rateSlider addTarget:self action:@selector(doChangeRate:) forControlEvents:UIControlEventValueChanged];
    [soundControlView addSubview:rateSlider];

    SET_VIEW_HEIGHT(soundControlView, BELOW(rateSlider.frame));
    [containerView addSubview:soundControlView];
    
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

    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:scrollView];
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
    return [instrumentList objectAtIndex:row];
}

- (void)pickerView:(UIPickerView *)pickerView
      didSelectRow:(NSInteger)row
       inComponent:(NSInteger)component {
    NSLog(@"pickerview selected %ld, %@", (long)row,
          [instrumentList objectAtIndex:row]);
    playOptions.instrumentIndex = row;
    [playOptions save];
    [self switchToNewPlayer];
}

- (IBAction)doChangePosition:(UIView *)sender {
    UISlider *view = (UISlider *)sender;
    player.currentPosition = view.value * player.duration;
}

- (IBAction)doChangeRate:(UIView *)sender {
    UISlider *slider = (UISlider *)sender;
    playOptions.beatsPerMinute = slider.value;
    [playOptions save];
    [self switchToNewPlayer];
}

- (IBAction)doPlay:(UIView *)sender {
    if (!play.selected) {
        if (!player) {
            player = [self makePlayer];
        }
        [self startPlayer];
    } else {
        [self pausePlayer];
    }
}

- (void) pausePlayer {
    if (player) {
        [player stop];
    }
    [checkProgressTimer invalidate];
    checkProgressTimer = nil;
    play.selected = NO;
    [play setNeedsDisplay];
}

- (void) stopPlayer {
    [self pausePlayer];
    if (player) {
        [player stop];
    }
    player = nil;
}

- (AVMIDIPlayer *) makePlayer { // from current instrument and rate settings
    OSStatus rc;
    NSData *newMIDI = [self genMIDI];
    
    NSString *bankPath = [[NSBundle mainBundle]
                          pathForResource:@"GeneralUser GS MuseScore v1.442"
                          ofType:@"sf2"];
    if (!bankPath) {
        NSLog(@"inconceivable, soundsfont file is missing");
        return nil;
    }
    NSURL *bankURL = [NSURL fileURLWithPath:bankPath];
    
    MusicSequence s;
    // Initialise the music sequence
    NewMusicSequence(&s);
    
    oldMIDI = currentMIDI;  // keep the old point around for current player
    currentMIDI = newMIDI;
    rc = MusicSequenceFileLoadData (s, (__bridge CFDataRef _Nonnull)(currentMIDI), 0, 0);
    if (rc) {
        [self musicError:@"MusicSequenceFileLoadData" err:rc];
        return nil;
    }
    
    NSError *error;
    
    AVMIDIPlayer *newPlayer = [[AVMIDIPlayer alloc] initWithData:currentMIDI soundBankURL:bankURL error:&error];
    if (error) {
        NSLog(@"player initialization error: %@", [error localizedDescription]);
        return nil;
    }
    return newPlayer;
}

// Generate a new player from current play settings, turn of the old, if any, and
// fire up the new one in the same place.  Regen the MIDI if necessary.

- (void) switchToNewPlayer {
    AVMIDIPlayer *newPlayer = [self makePlayer];
    if (!newPlayer) {
        NSLog(@" ** inconceivable, player creation error");
        return;
    }
    
    int currentPosition = -1;   // >= 0 if we are playing
    if (player) {   // Do we have a current player?
        if (player.playing) {   // if it is playing, stop it
            currentPosition = player.currentPosition;
            [self pausePlayer];
            [player stop];
        }
    }
    player = newPlayer;
    player.currentPosition = currentPosition >= 0 ? currentPosition : 0;
    [self pausePlayer];
#ifdef notyet
    [player prepareToPlay];
    if (currentPosition >= 0) {
        [self startPlayer];
    }
#endif
}

- (void) startPlayer {
    playerOp = [[NSOperationQueue alloc] init];
    [playerOp addOperationWithBlock: ^{
        NSLog(@"start playing: %@, %d", self.player, self.player.playing);
        [self.player play:^(void) {
            NSLog(@"playing complete");
            dispatch_async(dispatch_get_main_queue(), ^(void) {
                [self stopPlayer];
            });
        }];
    }];

    play.selected = YES;
    [play setNeedsDisplay];
    
    musicSlider.value = self.player.currentPosition/self.player.duration;
    musicSlider.hidden = NO;
    [musicSlider setNeedsDisplay];

    checkProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0
                                     target:self
                                   selector:@selector(tick)
                                   userInfo:nil
                                    repeats:YES];
}

- (void) tick {
    float fracDone = self.player.currentPosition/self.player.duration;
    [self.musicSlider setValue:fracDone animated:YES];
    [self.musicSlider setNeedsDisplay];
}

long *sequenceArray = 0;

- (long *) makeArray {
    sequenceArray = (long *)malloc(sizeof(long)*sequence.values.count);
    assert (sequenceArray);
    for (size_t i=0; i<sequence.values.count; i++) {
        NSNumber *n = [sequence.values objectAtIndex:i];
        sequenceArray[i] = [n longValue];
    }
    return sequenceArray;
}

- (NSData *) genMIDI {
    NSString *midiTmp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"midi.tmp"];
    NSFileManager *mgr = [NSFileManager defaultManager];
    if (![mgr fileExistsAtPath:midiTmp])
        [mgr createFileAtPath:midiTmp contents:nil attributes:nil];
    NSFileHandle *midiFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:midiTmp];
    
    NSLog(@"generate MIDI...");
    seqToMidi(midiFileHandle.fileDescriptor, [self makeArray], sequence.values.count,
              1, 1, 1,
              (int)playOptions.beatsPerMinute,
              0, VOL,
              (int)playOptions.instrumentIndex + 1, // midi is 1-based
              VELON, VELOFF,
              PMOD, POFF, DMOD, DOFF, MAX_VALUES);
    [midiFileHandle closeFile];
    free(sequenceArray);    // crude
    sequenceArray = 0;
    
    //    [self mail:midiTmp];
    
    NSData *myMIDI = [NSData dataWithContentsOfFile:midiTmp];
    [mgr removeItemAtPath:midiTmp error:nil];

#ifdef DEBUGGING_MIDI
    if (sequence.midiData) {
        if (![myMIDI isEqualToData:sequence.midiData]) {
            NSLog(@" *** midis do not match ***");
//            if (sequence.midiData.length != myMIDI.length) {
//                NSLog(@"midi data length mismatch");
//                NSLog(@"David's midi: %lu", (unsigned long)sequence.midiData.length);
//                NSLog(@"     My midi: %lu", (unsigned long)myMIDI.length);
 //           } else {
                const u_char *a = myMIDI.bytes;
                const u_char *b = sequence.midiData.bytes;
                for (size_t i=0; i<myMIDI.length; i++)
                    if (a[i] != b[i]) {
                        NSLog(@"first difference at byte %zul of %zul", i, myMIDI.length);
                        break;
                    }
 //           }
        }
    }
#endif
    return myMIDI;
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
    [self stopPlayer];
    [self.navigationController popViewControllerAnimated:YES];
}

- (IBAction)swipeLeft:(UISwipeGestureRecognizer *)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

- (void) viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    CGRect f = self.view.frame;
    f.origin.y = self.navigationController.navigationBar.frame.size.height;
    f.size.height -= f.origin.y;
    scrollView.frame = CGRectInset(f, INSET, INSET);
    
    SET_VIEW_WIDTH(containerView, scrollView.frame.size.width);
    scrollView.contentSize = containerView.frame.size;
}

- (void) mail:(NSString *) filePath {
    NSString *emailTitle = [NSString
                            stringWithFormat:@"my MIDI file"];
    
    NSString *messageBody = [NSString stringWithFormat:@"My midi file"];
    
    MFMailComposeViewController *mc = [[MFMailComposeViewController alloc] init];
    mc.mailComposeDelegate = self;
    [mc setSubject:emailTitle];
    [mc setToRecipients:[NSArray arrayWithObjects:@"bc@cheswick.com", nil]];
    [mc setMessageBody:messageBody isHTML:NO];
    
    // Add attachments
    [mc addAttachmentData:[NSData dataWithContentsOfFile:filePath] mimeType:@"text/plain"
                 fileName:[filePath lastPathComponent]];

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

@end
