//
//  SeqThumbView.m
//  SeqNotes
//
//  Created by ches on 12/21/18.
//  Copyright © 2018 Cheswick.com. All rights reserved.
//

#import "SeqThumbView.h"

@interface SeqThumbView ()

@property (nonatomic, strong)   Sequence *sequence;

@end

@implementation SeqThumbView

@synthesize sequence;

- (id)initWithSequence: (Sequence *)s {
    self = [super init];
    if (self) {
        sequence = s;
        self.backgroundColor = [UIColor yellowColor];
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
