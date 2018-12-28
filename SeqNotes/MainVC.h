//
//  MainVC.h
//  SeqNotes
//
//  Created by ches on 12/21/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Sequence.h"

NS_ASSUME_NONNULL_BEGIN

@interface MainVC : UIViewController
    <sequenceProtocol,
    UICollectionViewDelegate,
    UICollectionViewDataSource,
    UICollectionViewDelegateFlowLayout,
    UIPopoverPresentationControllerDelegate>
@end

NS_ASSUME_NONNULL_END
