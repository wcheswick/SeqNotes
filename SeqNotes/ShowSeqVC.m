//
//  ShowSeqVC.m
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <AudioToolbox/MusicPlayer.h>

#import "ShowSeqVC.h"
#import "Defines.h"

@interface ShowSeqVC ()

@property (nonatomic, strong)   Sequence *sequence;

@property (nonatomic, strong)   UIView *containerView;
@property (nonatomic, strong)   UIScrollView *scrollView;
@property (nonatomic, strong)   UISlider *musicSlider;
@property (nonatomic, strong)   UIProgressView *progressView;

@end

@implementation ShowSeqVC

@synthesize sequence;
@synthesize containerView, scrollView;
@synthesize progressView;
@synthesize musicSlider;

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
    
    UIButton *play = [UIButton buttonWithType:UIButtonTypeRoundedRect];
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
    f.origin.y = f.size.height/2.0;
    f.size.width = 200;
    musicSlider.frame = f;
    musicSlider.hidden = NO;
    musicSlider.minimumValue = 0.0;
    musicSlider.maximumValue = 1.0;
    musicSlider.backgroundColor = [UIColor greenColor];
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
    OSStatus rc;
    
    // Create a new music sequence
    MusicSequence s;
    // Initialise the music sequence
    NewMusicSequence(&s);

#ifdef NOTDEF
    // Get a string to the path of the MIDI file which
    // should be located in the Resources folder
    // I'm using a simple test midi file which is included in the download bundle at the end of this document
    NSString *midiFilePath = [[NSBundle mainBundle]
                              pathForResource:@"web"
                              ofType:@"midi"];
    
    // Create a new URL which points to the MIDI file
    NSURL * midiFileURL = [NSURL fileURLWithPath:midiFilePath];
    
    OSStatus rc = MusicSequenceFileLoad(s, (__bridge CFURLRef)midiFileURL, 0, 0);
    if (rc) {
        NSLog(@"MusicSequenceFileLoad failed: %d", (int)rc);
        return;
    }
#endif
    
    rc = MusicSequenceFileLoadData (s, (__bridge CFDataRef _Nonnull)(sequence.midiData), 0, 0);
    // Create a new music player
    MusicPlayer  p;
    // Initialise the music player
    rc = NewMusicPlayer(&p);
    if (rc) {
        [self musicError:@"NewMusicPlayer" err:rc];
        return;
    }

    // Load the sequence into the music player
    rc = MusicPlayerSetSequence(p, s);
    if (rc) {
        [self musicError:@"MusicPlayerSetSequence" err:rc];
        return;
    }
    
    UInt32 trackCount;
    rc = MusicSequenceGetTrackCount(s, &trackCount);
    if (rc) {
        [self musicError:@"MusicSequenceGetTrackCount" err:rc];
        return;
    } else
        NSLog(@"  track count: %u", (unsigned int)trackCount);
    if (trackCount == 0) {  //midi tracks missing
        NSLog(@"%@: Midi tracks missing: %lu", sequence.seq, sequence.midiData.length);
        return;
    }
    
    MusicTrack track;
    for (int i=0; i<trackCount; i++) {
        rc = MusicSequenceGetIndTrack(s, i, &track);
        if (rc) {
            [self musicError:@"MusicSequenceGetIndTrack" err:rc];
            return;
        } else {
            MusicTimeStamp len;
            UInt32 sz = sizeof(MusicTimeStamp);
            rc = MusicTrackGetProperty(track, kSequenceTrackProperty_TrackLength, &len, &sz);
            if (rc) {
                [self musicError:@"MusicTrackGetProperty" err:rc];
                return;
            }
            NSLog(@"  track %d is %.3f", i, len);
        }
    }

    // Called to do some MusicPlayer setup. This just
    // reduces latency when MusicPlayerStart is called
    rc = MusicPlayerPreroll(p);
    if (rc) {
        [self musicError:@"MusicPlayerPreroll" err:rc];
        return;
    }
    // Starts the music playing
    rc = MusicPlayerStart(p);
    if (rc) {
        [self musicError:@"MusicPlayerStart" err:rc];
        return;
    }

    // Get length of track so that we know how long to kill time for
    MusicTrack t;
    MusicTimeStamp len;
    UInt32 sz = sizeof(MusicTimeStamp);
    rc = MusicSequenceGetIndTrack(s, 1, &t);
    if (rc) {
        [self musicError:@"MusicSequenceGetIndTrack" err:rc];
        return;
    }
    rc = MusicTrackGetProperty(t, kSequenceTrackProperty_TrackLength, &len, &sz);
    if (rc) {
        [self musicError:@"MusicTrackGetProperty" err:rc];
        return;
    }
    NSLog(@"  len: %.3f, size:%u", len, (unsigned int)sz);
#ifdef notdef
    progressView.hidden = NO;
    progressView.progress = 0.0;
    [progressView setNeedsDisplay];
#endif
    musicSlider.value = 0.0;
    musicSlider.hidden = NO;
    [musicSlider setNeedsDisplay];
    
    NSLog(@"Music has started...");
    while (1) { // kill time until the music is over
        [[NSRunLoop currentRunLoop] runMode: NSDefaultRunLoopMode beforeDate: [NSDate distantPast]];
        usleep (3 * 1000 * 1000);
        MusicTimeStamp now = 0;
        rc = MusicPlayerGetTime (p, &now);
        if (rc) {
            [self musicError:@"MusicPlayerGetTime" err:rc];
            return;
        }
        [musicSlider setValue:now / len animated:YES];
        [musicSlider setNeedsDisplay];
        if (now >= len)
            break;
    }
    NSLog(@"... finished");

    // Stop the player and dispose of the objects
    rc = MusicPlayerStop(p);
    if (rc) {
        [self musicError:@"MusicPlayerStop" err:rc];
        return;
    }
    progressView.hidden = YES;
    [progressView setNeedsDisplay];
    DisposeMusicSequence(s);
    DisposeMusicPlayer(p);
}

- (IBAction)doSlider:(UIView *)sender {
    UISlider *view = (UISlider *)sender;
    NSLog(@"music slider changed to %.3f", view.value);
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

@end
