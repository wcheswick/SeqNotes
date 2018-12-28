//
//  MainVC.m
//  SeqNotes
//
//  Created by ches on 12/21/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import "MainVC.h"
#import "ShowSeqVC.h"
#import "SeqThumbView.h"
#import "UICircularProgressView.h"
#import "Defines.h"

#define SEQ_W   (320)

@interface MainVC ()

@property (nonatomic, strong)   NSMutableArray *sequences;
@property (nonatomic, strong)   NSMutableArray *incomingSequences;
@property (nonatomic, strong)   UICircularProgressView *progressView;
@property (nonatomic, strong)   NSString *currentSequence;
@property (nonatomic, strong)   UICollectionView *collectionView;

@property (nonatomic, strong)   NSMutableArray *seqThumbViews;

@property (assign)              long dataLoadsRunning;
@property (assign)              CGFloat thumbWidth;

@end

@implementation MainVC

@synthesize sequences, currentSequence, incomingSequences;
@synthesize dataLoadsRunning;
@synthesize progressView;
@synthesize collectionView;
@synthesize seqThumbViews;
@synthesize thumbWidth;

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];

    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    seqThumbViews = [[NSMutableArray alloc] initWithCapacity:sequences.count];

    int thumbsAcross = self.view.frame.size.width/384;
    if (thumbsAcross == 0) {    // doesn't fit, iPhone
        thumbWidth = self.view.frame.size.width - 2*INSET;
    } else {
        thumbWidth = ((self.view.frame.size.width - INSET) / thumbsAcross)
            - thumbsAcross*INSET;
    }
    NSLog(@"thumbs across: %d, thumb width: %.1f",
          thumbsAcross, thumbWidth);
    
    UICollectionViewFlowLayout *layout= [[UICollectionViewFlowLayout alloc] init];
    layout.sectionInset = UIEdgeInsetsMake(5, 5, 5, 5);
    layout.minimumLineSpacing = 5;
    layout.minimumInteritemSpacing = 5;
    
    collectionView = [[UICollectionView alloc]
                      initWithFrame:CGRectInset(self.view.frame, INSET, INSET)
                      collectionViewLayout:layout];
    [collectionView setDataSource:self];
    [collectionView setDelegate:self];
    
    [self.collectionView registerClass:[UICollectionViewCell class]
            forCellWithReuseIdentifier:reuseIdentifier];
    [collectionView setBackgroundColor:[UIColor whiteColor]];
    self.view.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:collectionView];
    
    // Register cell classes
    
    incomingSequences = nil;
    progressView = nil;
    //    setenv("CFNETWORK_DIAGNOSTICS", "1", 1);
    
    self.navigationController.navigationBar.hidden = NO;
    self.navigationController.navigationBar.opaque = YES;
    self.title = @"SeqShow";
    
    UIBarButtonItem *rightBarButton = [[UIBarButtonItem alloc]
                                       initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                       target:self action:@selector(doGotoOEIS:)];
    rightBarButton.enabled = NO;
    self.navigationItem.rightBarButtonItem = rightBarButton;
    
    sequences = [NSKeyedUnarchiver unarchiveObjectWithFile:SEQUENCES_ARCHIVE];
    if (!sequences) {
        sequences = [[NSMutableArray alloc] init];
        incomingSequences = [self initializeSequences];
        NSLog(@"loading %lu new sequences", (unsigned long)incomingSequences.count);

        CGRect f;
        f.size = CGSizeMake(50, 50);
        f.origin = CGPointMake((self.view.frame.size.width - f.size.width)/2.0,
                               (self.view.frame.size.height - f.size.height)/3.0);
        progressView = [[UICircularProgressView alloc] initWithFrame:f];
        progressView.trackTintColor = [UIColor clearColor];
        progressView.progressTintColor = [UIColor blueColor];
        progressView.progressViewStyle = UICircularProgressViewStylePie;
        progressView.backgroundColor = [UIColor clearColor];
        progressView.opaque = NO;
        progressView.progress = 0.0;
        [self.view addSubview:progressView];
        [self.view bringSubviewToFront:progressView];
        [self.view setNeedsDisplay];
        
        [self loadNextNewSequence];
    } else {
        incomingSequences = nil;
        [self showSequences];
    }
    dataLoadsRunning = 0;
    [self checkDataNeeded];
    [collectionView reloadData];
}

- (void) checkDataNeeded {
    if (dataLoadsRunning)
        return; // busy, for now
    for (SeqThumbView *stv in seqThumbViews) {
        Sequence *seq = stv.sequence;
        if (seq.valuesUnavailable)
            continue;   // don't try
        if (seq.values)
            continue;   // already have it
        dataLoadsRunning++;
        dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
        dispatch_async(aQueue, ^{
            seq.target = self;
            [seq fetchValues];
        });
        break;  // only do one
    }
    if (dataLoadsRunning == 0)
        [self save];    // save our results
}

- (void) valuesFetchedForSequence:(Sequence *)sequence {
    dataLoadsRunning--;
    [self checkDataNeeded]; // start next load, if needed
    for (int i=0; i<seqThumbViews.count; i++) {
        SeqThumbView *stv = [seqThumbViews objectAtIndex:i];
        Sequence *s = stv.sequence;
        if ([s.seq isEqualToString:sequence.seq]) {   // found our slot
            s.target = self;
            [stv adjustThumb];
            return;
        }
    }
}

- (void) addThumbView:(Sequence *) sequence {
    SeqThumbView *thumbView = [[SeqThumbView alloc]
                               initWithSequence:sequence
                               width:thumbWidth];
    [seqThumbViews addObject:thumbView];
    UIButton *audioButton = [thumbView viewWithTag:SOUND_VIEW_TAG];
    if (audioButton) {
        [audioButton addTarget:self
                        action:@selector(showAudio:)
              forControlEvents:UIControlEventTouchUpInside];
        audioButton.tag = THUMB_INDEX_BIAS + seqThumbViews.count - 1;
    }
    [collectionView reloadData];
}

- (IBAction)showAudio:(UIButton *)sender {
//    UIView *tv = [but superview];
    
    if (sender.tag < THUMB_INDEX_BIAS) {
        NSLog(@"button touch, not audio");
        return;
    }
    size_t index = sender.tag - THUMB_INDEX_BIAS;
    if (index >= sequences.count) {
        NSLog(@"button touch, index out of range: %ld", (long)sender.tag);
        return;
    }
    Sequence *sequence = [sequences objectAtIndex:index];
    assert(sequence);
    NSLog(@"sequence selected: #%zu, %@", index, sequence.seq);
    
    SeqThumbView *stv = [seqThumbViews objectAtIndex:index];
    UIView *thumbView = [stv superview];
    ShowSeqVC *svc = [[ShowSeqVC alloc] initWithSequence:sequence];
    svc.modalPresentationStyle = UIModalPresentationPopover;
    
    UINavigationController *nav = [[UINavigationController alloc]
                                   initWithRootViewController:svc];
    nav.modalPresentationStyle = UIModalPresentationPopover;
    nav.popoverPresentationController.sourceView = thumbView;
    nav.popoverPresentationController.sourceRect = thumbView.bounds;
    CGRect f = svc.view.frame;
    f.origin.y = nav.navigationBar.frame.size.height;
    f.size.height += f.origin.y;
    svc.view.frame = f;
    nav.preferredContentSize = svc.view.frame.size;
    [self presentViewController:nav animated:YES completion:nil];
}

- (void) updateThumbAt:(int) index {
    [self.collectionView reloadData];
#ifdef broken
    [self.collectionView reloadItemsAtIndexPaths:@[[NSIndexPath
                                                    indexPathForRow:index
                                                    inSection:0]]];
#endif
}

- (void) showSequences {
    for (int i=0; i<sequences.count; i++) {
        Sequence *s = [sequences objectAtIndex:i];
        [self addThumbView:s];
        [self updateThumbAt:i];
    }
}

- (void) loadNextNewSequence {
    if (!incomingSequences || incomingSequences.count == 0) {
        if (progressView) {
            [progressView removeFromSuperview];
            progressView = nil;
        }
        incomingSequences = nil;
        [self save];
        [self.collectionView reloadData];
        return;
    }
    Sequence *s = [incomingSequences objectAtIndex:0];
    [incomingSequences removeObjectAtIndex:0];
    
    dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(aQueue, ^{
        [s loadBasicDataFromOEIS: self];     // read data asynchronously
    });
}

- (void) addSequence: (Sequence *)sequence {
    [sequences addObject:sequence];
    [self save];
    [self addThumbView:sequence];
    [self loadNextNewSequence];
    [self checkDataNeeded];
}

- (IBAction)doGotoOEIS:(UISwipeGestureRecognizer *)sender {
    //    LogVC *lvc = [[LogVC alloc] initWithLog:log];
    //    //    self.navigationController.toolbarHidden = NO;
    //    [[self navigationController] pushViewController: lvc animated: YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

#pragma mark <UICollectionViewDataSource>

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
    return 1;
}

- (NSInteger)collectionView:(UICollectionView *)collectionView
     numberOfItemsInSection:(NSInteger)section {
    return seqThumbViews.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView
                                  dequeueReusableCellWithReuseIdentifier:reuseIdentifier
                                  forIndexPath:indexPath];
    SeqThumbView *thumbView = [seqThumbViews objectAtIndex:indexPath.row];
    [cell addSubview:thumbView];
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    SeqThumbView *thumbView = [seqThumbViews objectAtIndex:indexPath.row];
    return thumbView.frame.size;
}

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView
                        layout:(UICollectionViewLayout*)collectionViewLayout
        insetForSectionAtIndex:(NSInteger)section {
    return UIEdgeInsetsMake(0, 0, 0, 0);
}

#pragma mark <UICollectionViewDelegate>
    
#ifdef notdef
    // Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}
 */

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return YES;
}
#endif

- (void)collectionView:(UICollectionView *)collectionView
         performAction:(SEL)action
    forItemAtIndexPath:(NSIndexPath *)indexPath
            withSender:(id)sender {
#ifdef notused
    Sequence *seq = [sequences objectAtIndex:indexPath.row];
    ShowSeqVC *svc = [[ShowSeqVC alloc] initWithSequence:seq];
    svc.view.frame = self.view.frame;
    [self.navigationController pushViewController:svc animated:YES];
#endif
}

- (NSMutableArray *) initializeSequences {
    NSString *interestingListPath = [[NSBundle mainBundle]
                                     pathForResource:@"Music"ofType:@"txt"];
    if (!interestingListPath) {
        NSLog(@"Neil's list of interesting sequences missing");
        return nil;
    }
    
    NSError *error;
    NSString *interestingList = [NSString stringWithContentsOfFile:interestingListPath encoding:NSUTF8StringEncoding error:&error];
    if (!interestingList || [interestingList isEqualToString:@""] || error) {
        NSLog(@"interesting list error: %@", [error localizedDescription]);
        return nil;
    }
    
    // Entries look like this:
    
    // A000010
    // Title: Euler totient function
    // Terms; 1, 1, 2, 2, 4, 2, 6, 4, 6, 4, 10, 4, 12, 6, 8, 8, 16, 6, 18, 8, 12, 10, 22, 8, ...
    // Comment: Number of numbers <= n and relatively prime to n.
    // Music: Two midi files, the standard one, and one using Rate=40, Release Velocity=20, Duration offset=1, Instrument = 103 (FX7)
    // entries are separated by one or more blank lines. We assume at least one blank line at the end.
    
    NSArray *lines = [interestingList componentsSeparatedByString:@"\n"];
    NSLog(@" number of interesting lines: %lu", (unsigned long)lines.count);
    if (lines.count == 0) {
        NSLog(@"interesting list is empty");
        return nil;
    }
    
    NSMutableArray *newSequences = [[NSMutableArray alloc] init];
    NSString *seq = nil;
    NSString *shortTitle = nil;
    NSString *shortComment = nil;
    
    for (NSString *line in lines) {
        if (line.length == 0) { // entry separator
            if (seq) { // end of an entry
                Sequence *s = [[Sequence alloc] initSequence:seq];
                if (!s) {
                    NSLog(@"default sequence %@ failed", seq);
                    continue;
                }
                s.shortTitle = shortTitle;
                s.shortComment = shortComment;
                seq = nil;
                shortTitle = shortComment = nil;
                [newSequences addObject:s];
            }
            continue;
        }
        if ([line hasPrefix:@"A"]) {
            seq = line;
        } else if ([line hasPrefix:@"Title: "]) {
            if (line.length <= @"Title: ".length)
                NSLog(@"title missing at %@", line);
            else
                shortTitle = [line substringFromIndex:@"Title: ".length];
        } else if ([line hasPrefix:@"Terms"]) {
            ;
        } else if ([line hasPrefix:@"Comment: "]) {
            if (line.length <= @"Title: ".length)
                NSLog(@"comment missing at %@", line);
            else
                shortComment = [line substringFromIndex:@"Comment: ".length];
        } else if ([line hasPrefix:@"Music"]) {
            ;
        }
    }
    if (seq)
        NSLog(@"*** unterminated entry: %@", seq);
    return newSequences;
}

- (void) save {
    if (![NSKeyedArchiver archiveRootObject:sequences
                                     toFile:SEQUENCES_ARCHIVE])
        NSLog(@"sequences save failed");
}

@end
