//
//  ILNewSignalWindowController.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/06.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILNewSignalWindowController.h"
#import "ILLog.h"

@implementation ILNewSignalWindowController

- (void) awakeFromNib {
    ILLOG_CURRENT_METHOD;
}

- (void) dealloc {
    ILLOG_CURRENT_METHOD;
}

- (void) windowDidLoad {
    ILLOG_CURRENT_METHOD;
}

- (void) windowDidResignKey: (NSNotification*) notification {
    ILLOG_CURRENT_METHOD;
    [_signalDelegate newSignalWindowController: self didFinishWithSignal: nil];
}

@end
