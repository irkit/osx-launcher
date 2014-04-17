//
//  ILMenuButtonView.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenuButtonView.h"

@implementation ILMenuButtonView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame: frame];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect: dirtyRect];

    // Drawing code here.
}

- (IBAction)pressed:(id)sender {
    [self.delegate menuButtonView: self didPress: sender];
}
@end
