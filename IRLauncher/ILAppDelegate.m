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
#import "ILMenuProgressView.h"
#import "ILConst.h"
#import "ILMenu.h"
#import "ILUSBWatcher.h"
#import "ILUSBConnectedPeripheral.h"

const int kSignalTagOffset     = 1000;
const int kPeripheralTagOffset = 100;
const int kUSBTagOffset        = 200;
static NSString *kIRKitAPIKey  = @"E4D85D012E1B4735BC6F3EBCCCAE4100";

#define kILUSBVendorIRKit     @0x1D50
#define kILUSBProductIRKit    @0x6085

#define kILUSBVendorArduino   @0x2341
#define kILUSBProductLeonardo @0x8036

@interface ILAppDelegate ()

@property (nonatomic, strong) NSStatusItem *item;
@property (nonatomic, strong) ILMenuletView *menuletView;
@property (nonatomic, strong) ILMenu *menu;
@property (nonatomic, strong) IRSignals *signals;
@property (nonatomic, strong) NSMutableArray *usbConnectedPeripherals;

@end

@implementation ILAppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    __weak typeof(self) _self = self;
    CGFloat thickness = [[NSStatusBar systemStatusBar] thickness];

    ILFileStore *store = [[ILFileStore alloc] init];
    [IRKit setPersistentStore: store];
    [IRKit startWithAPIKey: kIRKitAPIKey];

    self.menu                  = (ILMenu*)[ILUtils loadClassFromNib: [ILMenu class]];
    self.menu.checkboxDelegate = self;
    self.menu.buttonDelegate   = self;
    self.menu.menuDelegate     = self;

    self.menuletView      = [[ILMenuletView alloc] initWithFrame: (NSRect){.size={thickness, thickness}}];
    self.menuletView.menu = self.menu;

    self.item = [[NSStatusBar systemStatusBar] statusItemWithLength: thickness];
    [self.item setView: self.menuletView];
    [self.item setHighlightMode: NO];

    self.menuletView.statusItem = self.item;

    NSString *signalsDirectory = [NSHomeDirectory() stringByAppendingPathComponent: @".irkit.d/signals"];
    NSURL *signalsURL          = [NSURL fileURLWithPath: signalsDirectory];

    self.signals = [[IRSignals alloc] init];

    [self.menu setSignalHeaderTitle: @"Signals (Searching...)" animating: YES];
    [ILSignalsDirectorySearcher findSignalsUnderDirectory: signalsURL completion:^(NSArray *foundSignals) {
        [_self.menu setSignalHeaderTitle: @"Signals" animating: NO];
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
        [self.menu setSignalHeaderTitle: @"Signals" animating: NO];
    }];

    [IRSearcher sharedInstance].delegate = self;

    [self.menu setUSBHeaderTitle: @"IRKits connected via USB (none found)" animating: NO];
    self.usbConnectedPeripherals = @[].mutableCopy;

    [[ILUSBWatcher sharedInstance] startWatchingUSB];
    [[NSNotificationCenter defaultCenter] addObserverForName: kILUSBWatcherNotificationAdded
                                                      object: nil
                                                       queue: NULL
                                                  usingBlock:^(NSNotification *note) {
        NSDictionary *info = note.userInfo;
        ILLOG( @"added USB: %@", info );

        if ( ([info[ kILUSBWatcherNotificationVendorIDKey ] isEqualToNumber: kILUSBVendorIRKit] &&
              [info[ kILUSBWatcherNotificationProductIDKey ] isEqualToNumber: kILUSBProductIRKit]) ||
             ([info [kILUSBWatcherNotificationVendorIDKey ] isEqualToNumber: kILUSBVendorArduino] &&
              [info[ kILUSBWatcherNotificationProductIDKey ] isEqualToNumber: kILUSBProductLeonardo]) ) {
            ILUSBConnectedPeripheral *peripheral = [[ILUSBConnectedPeripheral alloc] init];
            peripheral.dialinDevice = info[ kILUSBWatcherNotificationDialinDeviceKey ];
            peripheral.locationId = info[ kILUSBWatcherNotificationLocationIDKey ];
            [_self.usbConnectedPeripherals addObject: peripheral];

            NSUInteger index = [_self.usbConnectedPeripherals indexOfObject: peripheral];
            NSMenuItem *usbItem = [[NSMenuItem alloc] init];
            NSString *title = [NSString stringWithFormat: @"%@ (%@)"
                               , [ILUtils chompedString: info[ kILUSBWatcherNotificationDeviceNameKey ]]
                               , peripheral.dialinDevice];
            usbItem.title = title;
            usbItem.target = _self;
            usbItem.action = @selector(confirmUpdate:);
            usbItem.tag = kUSBTagOffset + index;
            [_self.menu addUSBMenuItem: usbItem];
            [_self.menu setUSBHeaderTitle: @"IRKits connected via USB" animating: NO];
        }
    }];
    [[NSNotificationCenter defaultCenter] addObserverForName: kILUSBWatcherNotificationRemoved
                                                      object: nil
                                                       queue: nil
                                                  usingBlock:^(NSNotification *note) {
        NSDictionary *info = note.userInfo;
        ILLOG( @"removed USB: %@", info );
        NSNumber *locationId = info[ kILUSBWatcherNotificationLocationIDKey ];
        ILUSBConnectedPeripheral *peripheral = (ILUSBConnectedPeripheral*)[ILUtils firstObjectOf: _self.usbConnectedPeripherals meetsBlock:^BOOL (id obj, NSUInteger idx) {
                ILUSBConnectedPeripheral *p = obj;
                if ([p.locationId isEqualToNumber: locationId]) {
                    return YES;
                }
                return NO;
            }];
        if (!peripheral) {
            return;
        }
        NSUInteger index = [_self.usbConnectedPeripherals indexOfObject: peripheral];
        [_self.usbConnectedPeripherals removeObject: peripheral];
        [_self.menu removeUSBMenuItemAtIndex: index];
        if (_self.usbConnectedPeripherals.count == 0) {
            [_self.menu setUSBHeaderTitle: @"IRKits connected via USB (none found)" animating: NO];
        }
    }];
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

- (void) confirmUpdate: (id)sender {
    ILLOG( @"sender: %@", sender );

    NSUInteger peripheralIndex           = ((NSMenuItem*)sender).tag - kUSBTagOffset;
    ILUSBConnectedPeripheral *peripheral = (ILUSBConnectedPeripheral*)[self.usbConnectedPeripherals objectAtIndex: peripheralIndex];
    // TODO confirm
}

- (IBAction) showHelp: (id)sender {
    ILLOG_CURRENT_METHOD;
}

- (IBAction) terminate: (id)sender {
    [[NSApplication sharedApplication] terminate: sender];
}

#pragma mark - ILMenuCheckboxViewDelegate

- (void) menuCheckboxView:(ILMenuCheckboxView *)view didTouchCheckbox:(id)sender newValue:(BOOL)onoff {
    ILLOG( @"value: %d", onoff );
}

#pragma mark - ILMenuButtonViewDelegate

- (void) menuButtonView:(ILMenuButtonView *)view didPress: (id)sender {
    ILLOG_CURRENT_METHOD;
}

#pragma mark - ILMenuDelegate

- (void) menuWillOpen:(ILMenu *)menu {
    ILLOG_CURRENT_METHOD;
    [[IRSearcher sharedInstance] startSearchingForTimeInterval: 5.];
}

- (void) menuDidClose:(ILMenu *)menu {
    ILLOG_CURRENT_METHOD;

    [[IRSearcher sharedInstance] stop];
}

#pragma mark - IRSearcherDelegate

- (void) searcherWillStartSearching:(IRSearcher *)searcher {
    ILLOG_CURRENT_METHOD;

    [_menu setPeripheralHeaderTitle: @"IRKits (Searching...)" animating: YES];
}

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

- (void) searcherDidTimeout:(IRSearcher *)searcher {
    ILLOG_CURRENT_METHOD;
    [self.menu setPeripheralHeaderTitle: @"IRKits" animating: NO];
    [[IRSearcher sharedInstance] startSearchingAfterTimeInterval: 5. forTimeInterval: 5.];
}

@end
