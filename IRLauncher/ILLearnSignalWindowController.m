//
//  ILNewSignalWindowController.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/17.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILLearnSignalWindowController.h"
#import "ILLog.h"
#import "ILSignalReceiveViewController.h"
#import "ILSignalNameEditViewController.h"

@interface ILLearnSignalWindowController ()

@property (nonatomic, strong) NSViewController *currentController;

@end

@implementation ILLearnSignalWindowController

- (id)init {
    self = [super init];
    if (self) {
        NSRect rect = {
            { 0, 0 },
            { 640, 360 }
        };
        self.window = [[NSWindow alloc] initWithContentRect: rect
                                                  styleMask: NSTitledWindowMask | NSClosableWindowMask
                                                    backing: NSBackingStoreBuffered
                                                      defer: NO];
        self.window.delegate = self;
        ILSignalReceiveViewController *c = [[ILSignalReceiveViewController alloc] initWithNibName: @"ILSignalReceiveView" bundle: nil];
        c.delegate              = self;
        _currentController      = c;
        self.window.contentView = c.view;
    }
    return self;
}

- (void)dealloc {
    ILLOG_CURRENT_METHOD;
}

- (void) windowDidResignKey: (NSNotification*) notification {
    ILLOG_CURRENT_METHOD;

    [_signalDelegate learnSignalWindowController: self
                             didFinishWithSignal: nil
                                       withError: NULL];
}

#pragma mark - ILSignalReceiveViewControllerDelegate

- (void) signalReceiveViewController:(ILSignalReceiveViewController*)c didReceiveSignal:(IRSignal*)signal withError:(NSError *)error {
    ILLOG( @"signal: %@", signal );

    if (signal) {
        ILSignalNameEditViewController *c = [[ILSignalNameEditViewController alloc] initWithNibName: @"ILSignalNameEditView" bundle: nil];
        c.delegate              = self;
        c.signal                = signal;
        _currentController      = c;
        self.window.contentView = c.view;
        return;
    }
    if (error) {
        NSString *message = error.localizedDescription;
        NSAlert *alert    = [[NSAlert alloc] init];
        [alert addButtonWithTitle: @"OK"];
        [alert setMessageText: message];
        [alert setAlertStyle: NSWarningAlertStyle];
        [alert runModal];
    }
    [self.window performClose: self];
}

#pragma mark - ILSignalNameEditViewControllerDelegate

- (void) signalNameEditViewController:(ILSignalNameEditViewController *)controller didFinishWithInfo:(NSDictionary *)info {
    ILLOG( @"info: %@", info );

    if ([info[ IRViewControllerResultType ] isEqualTo: IRViewControllerResultTypeDone]) {
        IRSignal *signal = info[ IRViewControllerResultSignal ];
        [_signalDelegate learnSignalWindowController: self
                                 didFinishWithSignal: signal
                                           withError: NULL];
        return;
    }
    ILSignalReceiveViewController *c = [[ILSignalReceiveViewController alloc] initWithNibName: @"ILSignalReceiveView" bundle: nil];
    c.delegate              = self;
    _currentController      = c;
    self.window.contentView = c.view;
}

@end
