//
//  ILAppDelegate.m
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
#import "IRKit.h"
#import "ILFileStore.h"
#import "const.h"

const int kSignalTagOffset     = 1000;
const int kPeripheralTagOffset = 100;
static NSString *kIRKitAPIKey  = @"----FILLME---";

@interface ILAppDelegate ()

@property (nonatomic, strong) NSStatusItem *item;
@property (nonatomic, strong) ILMenuletView *menuletView;
@property (nonatomic, strong) ILMenu *menu;
@property (nonatomic, strong) IRSignals *signals;

@end

@implementation ILAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    __weak typeof(self) _self = self;
    CGFloat thickness = [[NSStatusBar systemStatusBar] thickness];

    ILFileStore *store = [[ILFileStore alloc] init];
    [IRKit setPersistentStore: store];
    [IRKit startWithAPIKey: kIRKitAPIKey];

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
    [self.menu setUSBHeaderTitle: @"IRKits connected via USB (Searching...)"];

    NSString *signalsDirectory = [NSHomeDirectory() stringByAppendingPathComponent: @".irkit.d/signals"];
    NSURL *signalsURL          = [NSURL fileURLWithPath: signalsDirectory];

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
                if (index < 10) {
                    signalItem.keyEquivalent = [NSString stringWithFormat: @"%lu", (unsigned long)index];
                }
                [_self.menu addSignalMenuItem: signalItem];
            }];
    }];

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
            ILVersionChecker *checker = [[ILVersionChecker alloc] init];
            [checker checkUpdateForVersion: version foundUpdateBlock:^(NSString *newVersion) {
                    [_self notifyUpdate: hostname
                             newVersion: newVersion
                         currentVersion: version];
                }];
        }
    }];
}

@end
