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
#import "Defines.h"

@interface ShowSeqVC ()

@property (nonatomic, strong)   Sequence *sequence;

@property (nonatomic, strong)   UIView *containerView;
@property (nonatomic, strong)   UIScrollView *scrollView;
@property (nonatomic, strong)   UISlider *musicSlider;
@property (nonatomic, strong)   UIProgressView *progressView;
@property (nonatomic, strong)   AVMIDIPlayer *player;
@property (nonatomic, strong)   UIButton *play;
@property (nonatomic, strong)   NSTimer *checkProgressTimer;
@property (nonatomic, strong)   NSData *currentMIDI;

@end

@implementation ShowSeqVC

@synthesize sequence;
@synthesize containerView, scrollView;
@synthesize progressView;
@synthesize checkProgressTimer;
@synthesize musicSlider;
@synthesize player, play;
@synthesize currentMIDI;

- (id)initWithSequence: (Sequence *)s {
    self = [super init];
    if (self) {
        sequence = s;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.opaque = YES;
    self.title = sequence.seq;
    player = nil;
    checkProgressTimer = nil;
    currentMIDI = nil;
    
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
                                        self.view.frame.size.width, 2*LARGE_H);
    
    play = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    CGRect f;
    f.origin.x = 0;
    f.size.height = soundControlView.frame.size.height - 2;
    f.origin.y = 2;
    f.size.width = f.size.height*1.4;
    play.frame = f;
    [play setTitle:@"▶️" forState:UIControlStateNormal];
    [play setTitle:@"॥" forState:UIControlStateSelected];
    play.titleLabel.font = [UIFont boldSystemFontOfSize:soundControlView.frame.size.height - 8];
    [play addTarget:self
             action:@selector(doPlay:)
    forControlEvents:UIControlEventTouchUpInside];
    [soundControlView addSubview:play];

#ifdef notdef
    progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    f.origin.x = RIGHT(f) + 20;
    f.origin.y = f.size.height/2.0;
    f.size.width = 200;
    progressView.frame = f;
    progressView.hidden = NO;
    progressView.backgroundColor = [UIColor greenColor];
    [soundControlView addSubview:progressView];
#endif
    
    musicSlider = [[UISlider alloc] init];
    f.origin.x = RIGHT(f) + 20;
    f.origin.y = 0;
    f.size.width = 200;
    f.size.height = play.frame.size.height;
    musicSlider.frame = f;
    musicSlider.hidden = NO;
    musicSlider.minimumValue = 0.0;
    musicSlider.maximumValue = 1.0;
    [musicSlider addTarget:self action:@selector(doSlider:) forControlEvents:UIControlEventValueChanged];
    [soundControlView addSubview:musicSlider];

    [containerView addSubview:soundControlView];
    
    f = containerView.frame;
    if (sequence.plotData) {
        UIImage *plotImage = [UIImage imageWithData:sequence.plotData];
        UIImageView *plotsView = [[UIImageView alloc] initWithImage:plotImage];
        plotsView.contentMode = UIViewContentModeScaleAspectFit;
        CGFloat aspect = plotImage.size.height/plotImage.size.width;
        plotsView.frame = CGRectMake(0, BELOW(soundControlView.frame) + SEP,
                                     self.view.frame.size.width, self.view.frame.size.width*aspect);
        [containerView addSubview:plotsView];
        f.size.height = BELOW(plotsView.frame);
    } else {
        f.size.height = BELOW(soundControlView.frame);
    }
    containerView.frame = f;

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


- (IBAction)doPlay:(UIView *)sender {
    if (!play.selected)
        [self doPlayer];
    else {
        [self stopPlayer];
    }
}

- (void) stopPlayer {
    if (player) {
        [player stop];
    }
    play.selected = NO;
    [play setNeedsDisplay];
    [checkProgressTimer invalidate];
    checkProgressTimer = nil;
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

- (void) doPlayer {
    OSStatus rc;
    NSError *error;

    NSString *midiTmp = [NSTemporaryDirectory() stringByAppendingPathComponent:@"midi.tmp"];
    NSFileManager *mgr = [NSFileManager defaultManager];
    if (![mgr fileExistsAtPath:midiTmp])
        [mgr createFileAtPath:midiTmp contents:nil attributes:nil];
    NSFileHandle *midiFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:midiTmp];
    
    NSLog(@"generate MIDI...");
    seqToMidi(midiFileHandle.fileDescriptor, [self makeArray], sequence.values.count,
              1, 1, 1, BPM, 0, VOL, VOICE, VELON, VELOFF, PMOD, POFF, DMOD, DOFF, CUTOFF);
    [midiFileHandle closeFile];
    
    NSData *myMIDI = [NSData dataWithContentsOfFile:midiTmp];
    [mgr removeItemAtPath:midiTmp error:nil];
    
    if (sequence.midiData) {
        if (![myMIDI isEqualToData:sequence.midiData]) {
        NSLog(@"David's midi: %lu", (unsigned long)sequence.midiData.length);
        NSLog(@"     My midi: %lu", (unsigned long)myMIDI.length);
        }
    }
    currentMIDI = myMIDI;

    if (!player) {  // initialize
        NSString *bankPath = [[NSBundle mainBundle]
                              pathForResource:@"GeneralUser GS MuseScore v1.442"
                              ofType:@"sf2"];
#ifdef notdef
        NSString *bankPath = [[NSBundle mainBundle]
                              pathForResource:@"Acoustic Guitars JNv2.4"
                              ofType:@"sf2"];
#endif
        if (!bankPath) {
            NSLog(@"inconceivable, soundsfont file is missing");
            return;
        }
        NSURL *bankURL = [NSURL fileURLWithPath:bankPath];
        
        MusicSequence s;
        // Initialise the music sequence
        NewMusicSequence(&s);
        rc = MusicSequenceFileLoadData (s, (__bridge CFDataRef _Nonnull)(currentMIDI), 0, 0);
        if (rc) {
            [self musicError:@"MusicSequenceFileLoadData" err:rc];
            return;
        }
        player = [[AVMIDIPlayer alloc] initWithData:currentMIDI soundBankURL:bankURL error:&error];
        if (error) {
            NSLog(@"player initialization error: %@", [error localizedDescription]);
            return;
        }
        
        NSLog(@"preparing %@, data length: %lu duration %.1fs",
              sequence.seq, (unsigned long)currentMIDI.length, player.duration);
        
        [player prepareToPlay];
        NSLog(@"start playing");
    } else {
        NSLog(@"resume playing");
    }
    
    [player play:^(void) {
        NSLog(@"playing complete");
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            [self stopPlayer];
        });
    }];
    
    play.selected = YES;
    [play setNeedsDisplay];
    
    musicSlider.value = 0.0;
    musicSlider.hidden = NO;
    [musicSlider setNeedsDisplay];

    checkProgressTimer = [NSTimer timerWithTimeInterval:1 repeats:YES block:^(NSTimer *timer) {
        dispatch_async(dispatch_get_main_queue(), ^(void) {
            float fracDone = self.player.currentPosition/self.player.duration;
            NSLog(@"tick %.2f", fracDone);
            [self.musicSlider setValue:fracDone animated:YES];
            [self.musicSlider setNeedsDisplay];
        });
    }];
}

- (IBAction)doSlider:(UIView *)sender {
    UISlider *view = (UISlider *)sender;
    player.currentPosition = view.value * player.duration;
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
    scrollView.frame = CGRectInset(f, INDENT, INDENT);
    
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
                 fileName:[@"mystuff" stringByAppendingPathExtension:@"dat"]];
    [mc addAttachmentData:[NSData dataWithData:sequence.midiData] mimeType:@"text/plain"
                 fileName:[@"daves" stringByAppendingPathExtension:@"dat"]];

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
