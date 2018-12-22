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

@interface MainVC ()

@property (nonatomic, strong)   NSMutableArray *sequences;
@property (nonatomic, strong)   NSMutableArray *incomingSequences;
@property (nonatomic, strong)   UICircularProgressView *progressView;
@property (nonatomic, strong)   NSString *currentSequence;

@property (assign)              long sequencesToLoad, sequencesLoaded;

@end

@implementation MainVC

@synthesize sequences, currentSequence, incomingSequences;
@synthesize sequencesToLoad, sequencesLoaded;
@synthesize progressView;

static NSString * const reuseIdentifier = @"Cell";

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations
    self.clearsSelectionOnViewWillAppear = YES;
    
    // Register cell classes
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:reuseIdentifier];
    
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
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    sequences = [NSKeyedUnarchiver unarchiveObjectWithFile:SEQUENCES_ARCHIVE];
    if (!sequences) {
        sequences = [[NSMutableArray alloc] init];
        incomingSequences = [self initializeSequences];
        NSLog(@"loading %lu new sequences", (unsigned long)incomingSequences.count);
        sequencesLoaded = 0;
        sequencesToLoad = incomingSequences.count;
        if (incomingSequences && incomingSequences.count > 0) {
#ifdef PROGVIEW
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
#endif
            [self.collectionView reloadData];
            [self loadNextNewSequence];
        }
    }
}

- (void) loadNextNewSequence {
    if (!incomingSequences || incomingSequences.count == 0) {
        if (progressView) {
            [progressView removeFromSuperview];
            progressView = nil;
        }
        incomingSequences = 0;
        [self save];
        [self.collectionView reloadData];
        return;
    }
    Sequence *s = [incomingSequences objectAtIndex:0];
    [incomingSequences removeObjectAtIndex:0];
    
    dispatch_queue_t aQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    dispatch_async(aQueue, ^{
        [s loadDataFromOEIS: self];     // read data asynchronously
    });
}

- (void) addSequence: (Sequence *)sequence {
    [sequences addObject:sequence];
    sequencesLoaded++;
    //    CGPoint offset = CGPointMake(0, self.tableView.contentSize.height - self.tableView.frame.size.height);
    //    [self.tableView setContentOffset:offset];
    [self.collectionView reloadData];
    [self loadNextNewSequence];
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


- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    int statusCell = (incomingSequences && incomingSequences > 0) ? 1 : 0;
    return sequences.count + statusCell;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView
                  cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:reuseIdentifier forIndexPath:indexPath];
    
    if (indexPath.row >= sequences.count) { // this is the loading status row
        UIActivityIndicatorView *active = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        active.frame = cell.frame;
        [active startAnimating];
    } else {
        Sequence *seq = [sequences objectAtIndex:indexPath.row];
        SeqThumbView *stv = [[SeqThumbView alloc] initWithSequence:seq];
        stv.frame = cell.frame;
        [cell addSubview:stv];
    }
    return cell;
}


- (CGSize)collectionView:(UICollectionView *)collectionView
                  layout:(UICollectionViewLayout *)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    return CGSizeMake(SEQ_W, SEQ_H);
}
#pragma mark <UICollectionViewDelegate>

- (BOOL)collectionView:(UICollectionView *)collectionView shouldHighlightItemAtIndexPath:(NSIndexPath *)indexPath {
	return YES;
}

- (BOOL)collectionView:(UICollectionView *)collectionView shouldSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    return YES;
}

/*
// Uncomment these methods to specify if an action menu should be displayed for the specified item, and react to actions performed on the item
- (BOOL)collectionView:(UICollectionView *)collectionView shouldShowMenuForItemAtIndexPath:(NSIndexPath *)indexPath {
	return NO;
}
 */

- (BOOL)collectionView:(UICollectionView *)collectionView canPerformAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
	return YES;
}

- (void)collectionView:(UICollectionView *)collectionView performAction:(SEL)action forItemAtIndexPath:(NSIndexPath *)indexPath withSender:(id)sender {
    Sequence *seq = [sequences objectAtIndex:indexPath.row];
    ShowSeqVC *svc = [[ShowSeqVC alloc] initWithSequence:seq];
    svc.view.frame = self.view.frame;
    [self.navigationController pushViewController:svc animated:YES];
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
