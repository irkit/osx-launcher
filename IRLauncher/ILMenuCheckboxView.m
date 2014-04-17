//
//  ILMenuCheckboxView.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenuCheckboxView.h"

@implementation ILMenuCheckboxView

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

- (IBAction)checkboxTouched:(id)sender {
    BOOL value = self.checkbox.state == NSOnState;
    [self.delegate menuCheckboxView: self didTouchCheckbox: sender newValue: value];
}

@end
