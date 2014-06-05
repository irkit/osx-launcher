//
//  ILMenuButtonView.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILMenuButtonView.h"

@interface ILMenuButtonView ()

@property (nonatomic, copy) NSString *title;
@property (nonatomic, copy) NSString *alternateTitle;
@property (nonatomic, copy) NSString *buttonTitle;
@property (nonatomic, copy) NSString *alternateButtonTitle;

@end

@implementation ILMenuButtonView

- (void)        setTitle:(NSString*)title
          alternateTitle:(NSString*)alternateTitle
             buttonTitle:(NSString*)buttonTitle
    alternateButtonTitle:(NSString*)alternateButtonTitle
                  action:(void (^)(id sender, NSCellStateValue value))action {
    self.title                = title;
    self.alternateTitle       = alternateTitle;
    self.buttonTitle          = buttonTitle;
    self.alternateButtonTitle = alternateButtonTitle;
    self.action               = action;
}

- (void) setState:(NSCellStateValue)state {
    _state        = state;
    _button.state = state;
    if (state == NSOnState) {
        [_textField setStringValue: _alternateTitle];
        _button.title = _alternateButtonTitle;
    }
    else {
        [_textField setStringValue: _title];
        _button.title = _buttonTitle;
    }
}

- (IBAction)pressed:(NSButton*)sender {
    if (self.delegate && [self.delegate respondsToSelector: @selector(menuButtonView:didPress:)]) {
        [self.delegate menuButtonView: self didPress: sender];
    }
    else if (self.action) {
        self.action( self, sender.state );
    }
}

@end
