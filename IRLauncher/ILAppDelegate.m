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
@property (nonatomic, strong) IRSearcher *searcher;

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
    NSString *signalsPath = [NSHomeDirectory() stringByAppendingPathComponent: @".irkit.d/signals"];
    NSURL *signalsURL     = [NSURL fileURLWithPath: signalsPath];

    [self findSignalsUnderDirectory: signalsURL completion:^(NSArray *foundSignals) {
        [foundSignals enumerateObjectsUsingBlock:^(NSDictionary *signal, NSUInteger idx, BOOL *stop) {
                NSMenuItem *signalItem = [[NSMenuItem alloc] init];
                signalItem.title  = signal[ @"name" ];
                signalItem.target = _self;
                signalItem.action = @selector(send:);
                signalItem.tag    = kSignalTagOffset + idx;
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
    [_versionChecker check];
}

- (void) checkIfIRKitUpdated {
    ILLOG( @"version: %@", _newestVersionString );

    [IRSearcher sharedInstance].delegate = self;
    // [[IRSearcher sharedInstance] startSearchingForInterval:60.]; // 1min.
}

- (void) notifyUpdate:(NSString*)hostname newVersion:(NSString*)newVersion currentVersion:(NSString*)currentVersion {
    ILLOG( @"hostname: %@ newVersion: %@ currentVersion: %@", hostname, newVersion, currentVersion);

}

- (void) findSignalsUnderDirectory: (NSURL*)signalsURL completion: (void (^)(NSArray *foundSignals)) completion {
    ILLOG( @"signalsURL: %@", signalsURL );

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *ret = @[].mutableCopy;

        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error;
        // Enumerate the directory (specified elsewhere in your code)
        // Request the two properties the method uses, name and isDirectory
        // Ignore hidden files
        // The errorHandler: parameter is set to nil. Typically you'd want to present a panel
        NSArray *fileURLs = [manager contentsOfDirectoryAtURL: signalsURL
                                   includingPropertiesForKeys: @[ NSURLNameKey, NSURLIsDirectoryKey ]
                                                      options: NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsPackageDescendants
                                                        error: &error];

        // Enumerate the dirEnumerator results, each value is stored in allURLs
        for (NSURL *fileURL in fileURLs) {

            // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
            NSString *fileName;
            [fileURL getResourceValue: &fileName forKey: NSURLNameKey error: NULL];

            // Retrieve whether a directory. From NSURLIsDirectoryKey, also
            // cached during the enumeration.
            NSNumber *isDirectory;
            [fileURL getResourceValue: &isDirectory forKey: NSURLIsDirectoryKey error: NULL];

            // Ignore files under the _extras directory
            if ([isDirectory boolValue]==NO) {
                NSData *content = [manager contentsAtPath: [fileURL path]];
                NSMutableDictionary *object = [NSJSONSerialization JSONObjectWithData: content
                                                                              options: NSJSONReadingMutableContainers
                                                                                error: &error];
                object[ @"name" ] = [[fileURL URLByDeletingPathExtension] lastPathComponent];
                [ret addObject: object];
            }
        }

        dispatch_async( dispatch_get_main_queue(), ^{
                completion( ret );
            });
    });
}

#pragma mark - NSMenuItem actions

- (void) send: (id)sender {
    ILLOG( @"sender: %@", sender );
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

    __weak ILAppDelegate *_self   = self;
    __weak NSNetService *_service = service;
    [ILUtils getModelNameAndVersion: service.hostName withCompletion:^(NSString *modelName, NSString *version) {
        ILLOG(@"modelName: %@, version: %@", modelName, version);
        if ([modelName isEqualToString: IRKitModelName]) {
            if ([ILUtils releasedVersionString: _self.newestVersionString isNewerThanPeripheralVersion: version]) {
                [_self notifyUpdate: _service.hostName newVersion: _self.newestVersionString currentVersion: version];
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
