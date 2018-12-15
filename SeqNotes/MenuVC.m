//
//  MenuVC.m
//  SeqShow
//
//  Created by ches on 12/12/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import "MenuVC.h"
#import "ShowSeqVC.h"
#import "UICircularProgressView.h"
#import "Defines.h"

// cloned, poot

@interface MenuVC ()

@property (nonatomic, strong)   NSMutableArray *sequences;
@property (nonatomic, strong)   NSMutableArray *incomingSequences;
@property (nonatomic, strong)   UICircularProgressView *progressView;
@property (nonatomic, strong)   NSString *currentSequence;

@property (assign)              long sequencesToLoad, sequencesLoaded;

@end

#define DEBUG_SEQ_INIT  NO

@implementation MenuVC

@synthesize sequences, currentSequence, incomingSequences;
@synthesize sequencesToLoad, sequencesLoaded;
@synthesize progressView;

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
}

- (void) viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
    sequences = [NSKeyedUnarchiver unarchiveObjectWithFile:SEQUENCES_ARCHIVE];
    if (DEBUG_SEQ_INIT || !sequences) {

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
            [self.tableView reloadData];
            [self loadNextNewSequence];
       }
    }
    //    for (Sequence *s in sequences)
    //        NSLog(@"%@  samples: %lu", s.seq, (unsigned long)s.values.count);
    
    [self.tableView reloadData];
}

- (void) loadNextNewSequence {
    if (!incomingSequences || incomingSequences.count == 0) {
        if (progressView) {
            [progressView removeFromSuperview];
            progressView = nil;
        }
        incomingSequences = 0;
        [self saveSequences];
        [self.tableView reloadData];
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
    [self.tableView reloadData];
    [self loadNextNewSequence];
}

- (IBAction)doGotoOEIS:(UISwipeGestureRecognizer *)sender {
//    LogVC *lvc = [[LogVC alloc] initWithLog:log];
//    //    self.navigationController.toolbarHidden = NO;
//    [[self navigationController] pushViewController: lvc animated: YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    int statusCell = (incomingSequences && incomingSequences > 0) ? 1 : 0;
    return sequences.count + statusCell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"SeqCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle
                                      reuseIdentifier:CellIdentifier];
    }
    if (indexPath.row >= sequences.count) { // this is the loading status row
        UIActivityIndicatorView *active = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
        active.frame = cell.accessoryView.frame;
        [active startAnimating];
        cell.accessoryType = UITableViewCellAccessoryDetailButton;
        cell.accessoryView = active;
    } else {
        Sequence *seq = [sequences objectAtIndex:indexPath.row];
        cell.textLabel.text = [NSString stringWithFormat:@"%@:  %@", seq.seq,
                               [seq titleToUse]];
        cell.detailTextLabel.text = [seq subtitleToUse];
    }
    return cell;
}

- (void)tableView:(UITableView *)tableView
didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    Sequence *seq = [sequences objectAtIndex:indexPath.row];
    ShowSeqVC *svc = [[ShowSeqVC alloc] initWithSequence:seq];
    svc.view.frame = self.view.frame;
    [self.navigationController pushViewController:svc animated:YES];

}

/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

- (NSMutableArray *) initializeSequences {
    NSString *interestingListPath = [[NSBundle mainBundle]
                                  pathForResource:@"Music1"ofType:@"txt"];
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

- (void) saveSequences {
    if (![NSKeyedArchiver archiveRootObject:sequences
                                     toFile:SEQUENCES_ARCHIVE])
        NSLog(@"sequences save failed");
}

@end
