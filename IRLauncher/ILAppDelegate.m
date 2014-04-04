//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILAppDelegate.h"
#import "ILMenuletView.h"
#import "ILVersionChecker.h"
#import "ILUtils.h"
#import "ILSignalsDirectorySearcher.h"
#import "IRSignals.h"
#import "const.h"

const int kSignalTagOffset     = 1000;
const int kPeripheralTagOffset = 100;

@interface ILAppDelegate ()

@property (nonatomic, strong) NSStatusItem *item;
@property (nonatomic, strong) ILMenuletView *menuletView;
@property (nonatomic, strong) ILMenu *menu;
@property (nonatomic, strong) ILVersionChecker *versionChecker;
@property (nonatomic, strong) NSString *newestVersionString;
@property (nonatomic, strong) NSTimer *checkTimer;
@property (nonatomic, strong) IRSignals *signals;

@end

@implementation ILAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    __weak typeof(self) _self = self;
    CGFloat thickness = [[NSStatusBar systemStatusBar] thickness];

    self.menuletView             = [[ILMenuletView alloc] initWithFrame: (NSRect){.size={thickness, thickness}}];
    self.menuletView.onMouseDown = (ILEventBlock)^(NSEvent *event) {
        [_self.item popUpStatusItemMenu: _self.menu];
    };

    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength: thickness];
    [self.item setView: self.menuletView];
    [self.item setHighlightMode: NO];

    NSArray *nibEntries = @[];
    [[NSBundle mainBundle] loadNibNamed: @"MainMenu" owner: self topLevelObjects: &nibEntries];
    self.menu = (ILMenu*)[ILUtils firstObjectOf: nibEntries meetsBlock:^BOOL (id obj, NSUInteger idx) {
        if ([obj isKindOfClass: [ILMenu class]]) {
            return YES;
        }
        return NO;
    }];
    [self.menu setSignalHeaderTitle: @"Signals (Searching...)"];
    [self.menu setPeripheralHeaderTitle: @"IRKits (Searching...)"];

    NSString *signalsPath = [NSHomeDirectory() stringByAppendingPathComponent: @".irkit.d/signals"];
    NSURL *signalsURL     = [NSURL fileURLWithPath: signalsPath];

    self.signals = [[IRSignals alloc] init];

    [ILSignalsDirectorySearcher findSignalsUnderDirectory: signalsURL completion:^(NSArray *foundSignals) {
        [_self.menu setSignalHeaderTitle: @"Signals"];
        [foundSignals enumerateObjectsUsingBlock:^(NSDictionary *signalInfo, NSUInteger idx, BOOL *stop) {
                IRSignal *signal = [[IRSignal alloc] initWithDictionary: signalInfo];
                [_self.signals addSignalsObject: signal];

                NSUInteger index = [_self.signals indexOfSignal: signal];
                NSMenuItem *signalItem = [[NSMenuItem alloc] init];
                signalItem.title  = signal.name;
                signalItem.target = _self;
                signalItem.action = @selector(send:);
                signalItem.tag    = kSignalTagOffset + index;
                [_self.menu addSignalMenuItem: signalItem];
            }];
    }];

    self.versionChecker          = [[ILVersionChecker alloc] init];
    self.versionChecker.delegate = self;

    // check every 24 hours
    [self checkWithInterval: 24. * 60. * 60.];
}

- (void)checkWithInterval:(NSTimeInterval)intervalSeconds {
    ILLOG_CURRENT_METHOD;

    if (_checkTimer) {
        [_checkTimer invalidate];
    }
    _checkTimer = [NSTimer timerWithTimeInterval: intervalSeconds
                                          target: self
                                        selector: @selector(checkReleasedVersion:)
                                        userInfo: nil
                                         repeats: YES];
    [_checkTimer fire];
}

- (void) checkReleasedVersion: (NSTimer*) timer {
    // TODO
    // [_versionChecker check];
}

- (void) checkIfIRKitUpdated {
    ILLOG( @"version: %@", _newestVersionString );

    [IRSearcher sharedInstance].delegate = self;
    [[IRSearcher sharedInstance] startSearching];
}

- (void) notifyUpdate:(NSString*)hostname newVersion:(NSString*)newVersion currentVersion:(NSString*)currentVersion {
    ILLOG( @"hostname: %@ newVersion: %@ currentVersion: %@", hostname, newVersion, currentVersion);

}

#pragma mark - NSMenuItem actions

- (void) send: (id)sender {
    ILLOG( @"sender: %@", sender );

    NSUInteger signalIndex = ((NSMenuItem*)sender).tag - kSignalTagOffset;
    IRSignal *signal       = (IRSignal*)[self.signals objectInSignalsAtIndex: signalIndex];
    [signal sendWithCompletion:^(NSError *error) {
        ILLOG( @"sent: %@", error );
    }];
}

- (void) showHelp: (id)sender {
    ILLOG_CURRENT_METHOD;
}

- (void) terminate: (id)sender {
    [[NSApplication sharedApplication] terminate: sender];
}

#pragma mark - IRSearcherDelegate

- (void) searcher:(IRSearcher *)searcher didResolveService:(NSNetService *)service {
    ILLOG( @"service: %@", service );

    __weak ILAppDelegate *_self = self;
    NSString *hostname          = service.hostName;
    [ILUtils getModelNameAndVersion: hostname withCompletion:^(NSString *modelName, NSString *version) {
        ILLOG(@"modelName: %@, version: %@", modelName, version);
        if ([modelName isEqualToString: IRKitModelName]) {
            if ([ILUtils releasedVersionString: _self.newestVersionString
                  isNewerThanPeripheralVersion: version]) {
                [_self notifyUpdate: hostname
                         newVersion: _self.newestVersionString
                     currentVersion: version];
            }
        }
    }];
}

#pragma mark - ILVersionCheckerDelegate

- (void) checker:(ILVersionChecker *)checker didFindVersion:(NSString *)versionString onURL:(NSURL *)assetURL {
    ILLOG( @"checker: %@", checker );

    _newestVersionString = versionString;

    NSURL *pathURL = [ILUtils URLPathForVersion: versionString];
    if ([[NSFileManager defaultManager] fileExistsAtPath: pathURL.absoluteString]) {
        // already downloaded
        [self checkIfIRKitUpdated];
    }
    else {
        __weak ILAppDelegate *_self = self;
        [ILUtils downloadAssetURL: assetURL toPathURL: pathURL completion:^(NSError* error) {
            if (!error) {
                [_self checkIfIRKitUpdated];
            }
        }];
    }
}

- (void) checker:(ILVersionChecker *)checker didFailCheckWithError:(NSError *)error {
    ILLOG( @"error: %@", error );
    // we can check on next timer, ignore errors
}

@end
