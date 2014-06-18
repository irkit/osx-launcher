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

@end

@implementation ILSignalNameEditViewController

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
}

- (void) loadView {
    ILLOG_CURRENT_METHOD;
    [super loadView];
}

- (IBAction) saveButtonPressed:(id)sender {
    ILLOG_CURRENT_METHOD;

    _signal.name = _textField.stringValue;

    [_delegate signalNameEditViewController: self
                          didFinishWithInfo: @{ IRViewControllerResultType : IRViewControllerResultTypeDone,
                                                IRViewControllerResultSignal : _signal,
                                                IRViewControllerResultText : _textField.stringValue }];
}

- (IBAction) cancelButtonPressed:(id)sender {
    ILLOG_CURRENT_METHOD;

    [_delegate signalNameEditViewController: self
                          didFinishWithInfo: @{ IRViewControllerResultType: IRViewControllerResultTypeCancelled }];
}

@end
