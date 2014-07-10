//
//  ILSignalNameEditViewController.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILSignalNameEditViewController.h"
#import "ILLog.h"
#import "IRConst.h"

@interface ILSignalNameEditViewController ()

@property (nonatomic) id textObserver;

@end

@implementation ILSignalNameEditViewController

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;

    __weak typeof(self) _self = self;
    _textObserver             = [[NSNotificationCenter defaultCenter] addObserverForName: NSControlTextDidChangeNotification
                                                                                  object: _inputTextField
                                                                                   queue: nil
                                                                              usingBlock:^(NSNotification *note) {
        NSString *input = _self.inputTextField.stringValue;
        NSString *format = @"リモコン信号を以下に保存します。\n~/.irkit.d/signals/%@.json\nQuicksilverでは \"%@\" と検索してください。";
        NSString *guideMessage = [NSString stringWithFormat: format, input, input ];
        _self.guideTextField.stringValue = guideMessage;
    }];
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
    [[NSNotificationCenter defaultCenter] removeObserver: _textObserver];
}

- (void)animationDidFinish {
    // activate and show blinking carret
    [self.view.window makeFirstResponder: _inputTextField];

    // we can make the carret blinking calling setString: ,
    // but this makes the blue border blink once, which looks weird.
    // I prefer not showing the carret blinking than the border blinking.
    // [[_inputTextField currentEditor] setString: @""];
}

- (IBAction) returnKeyPressed:(id)sender {
    ILLOG_CURRENT_METHOD;

    [self saveButtonPressed: sender];
}

- (IBAction) saveButtonPressed:(id)sender {
    ILLOG_CURRENT_METHOD;

    _signal.name = _inputTextField.stringValue;

    [_delegate signalNameEditViewController: self
                          didFinishWithInfo: @{ IRViewControllerResultType : IRViewControllerResultTypeDone,
                                                IRViewControllerResultSignal : _signal,
                                                IRViewControllerResultText : _inputTextField.stringValue }];
}

- (IBAction) cancelButtonPressed:(id)sender {
    ILLOG_CURRENT_METHOD;

    [_delegate signalNameEditViewController: self
                          didFinishWithInfo: @{ IRViewControllerResultType: IRViewControllerResultTypeCancelled }];
}

@end
