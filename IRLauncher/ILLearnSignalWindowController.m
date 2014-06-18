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

- (id)initWithWindow:(NSWindow *)window {
    ILLOG_CURRENT_METHOD;
    self = [super initWithWindow: window];
    if (self) {
        window.delegate = self;
        [window.contentView addSubview: [[NSView alloc] initWithFrame: NSMakeRect(0, 0, 0, 0)]];
        ILSignalReceiveViewController *c = [[ILSignalReceiveViewController alloc] initWithNibName: @"ILSignalReceiveView" bundle: nil];
        c.delegate = self;
        [self animateToViewController: c];
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

#pragma mark - Private

- (void) animateToViewController:(NSViewController*)c {
    _currentController = c;

    NSView *contentView = self.window.contentView;
    NSView *currentView = contentView.subviews[ 0 ];
    NSView *nextView    = c.view;

    NSRect nextFrame = [self.window frameRectForContentRect: nextView.frame];

    NSRect frame = [self.window frame];
    frame.origin.y -= (nextFrame.size.height - frame.size.height);
    frame.size      = nextFrame.size;

    [NSAnimationContext beginGrouping];

    // Call the animator instead of the view / window directly
    [[contentView animator] replaceSubview: currentView with: nextView];
    [[self.window animator] setFrame: frame display: YES];

    [NSAnimationContext endGrouping];
}

#pragma mark - ILSignalReceiveViewControllerDelegate

- (void) signalReceiveViewController:(ILSignalReceiveViewController*)c didReceiveSignal:(IRSignal*)signal withError:(NSError *)error {
    ILLOG( @"signal: %@", signal );

    if (signal || 1) {
        ILSignalNameEditViewController *c = [[ILSignalNameEditViewController alloc] initWithNibName: @"ILSignalNameEditView" bundle: nil];
        c.delegate = self;
        c.signal   = signal;
        [self animateToViewController: c];
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
    c.delegate = self;
    [self animateToViewController: c];
}

@end
