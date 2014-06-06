//
//  ILNewSignalWindowController.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/06.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILNewSignalWindowController.h"
#import "ILLog.h"
#import "IRHTTPClient.h"

@interface ILNewSignalWindowController ()

@property (nonatomic,strong) IRHTTPClient *waiter;

@end

@implementation ILNewSignalWindowController

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
    [_waiter cancel];
}

- (void) windowDidLoad {
    ILLOG_CURRENT_METHOD;

    __weak typeof(self) _self = self;
    _waiter                   = [IRHTTPClient waitForSignalWithCompletion:^(NSHTTPURLResponse *res, IRSignal *signal, NSError *error) {
        if (signal) {
            [_self didReceiveSignal: signal];
            return;
        }
        [_self.signalDelegate newSignalWindowController: _self didFinishWithSignal: nil];
    }];

}

- (void) windowDidResignKey: (NSNotification*) notification {
    ILLOG_CURRENT_METHOD;
    [_signalDelegate newSignalWindowController: self didFinishWithSignal: nil];
}

- (void) didReceiveSignal: (IRSignal*)signal {
    ILLOG_CURRENT_METHOD;

    // TODO set name (after design comes)

    [_signalDelegate newSignalWindowController: self didFinishWithSignal: signal];
}

@end
