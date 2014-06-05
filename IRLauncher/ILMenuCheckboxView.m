//
//  ILMenuCheckboxView.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenuCheckboxView.h"

@interface ILMenuCheckboxView ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *alternateTitle;

@end

@implementation ILMenuCheckboxView

- (void)  setTitle:(NSString*)title
    alternateTitle:(NSString*)alternateTitle
            action:(void (^)(id sender, NSCellStateValue value))action {
    self.title          = title;
    self.alternateTitle = alternateTitle;
    self.action         = action;
}

- (void) setState:(NSCellStateValue)state {
    _state          = state;
    _checkbox.state = state;
    if (state == NSOnState) {
        [_textField setStringValue: _alternateTitle];
    }
    else {
        [_textField setStringValue: _title];
    }
}

- (IBAction)checkboxTouched:(id)sender {
    BOOL value = self.checkbox.state == NSOnState;
    [self.delegate menuCheckboxView: self didTouchCheckbox: sender newValue: value];

    if (self.delegate && [self.delegate respondsToSelector: @selector(menuCheckboxView:didTouchCheckbox:newValue:)]) {
        [self.delegate menuCheckboxView: self didTouchCheckbox: sender newValue: value];
    }
    else if (self.action) {
        self.action( self, value );
    }
}

@end
