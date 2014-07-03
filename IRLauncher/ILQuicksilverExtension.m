//
//  ILQuicksilverExtension.m
//
//
//  Created by Masakazu Ohtsuka on 2014/05/07.
//
//

#import "ILQuicksilverExtension.h"
#import "ILLog.h"
#import "ILUtils.h"
#import "NSString+UUID.h" // uniqueString
#import "ILFileStore.h"

static NSString *kILQuicksilverBundleIdentifier = @"com.blacktree.Quicksilver";

@implementation ILQuicksilverExtension

- (NSString*) title {
    return @"Quicksilver";
}

- (NSString*) installInformativeText {
    return @"I will edit ~/Library/Application Support/Quicksilver/Catalog.plist and add ~/.irkit.d/signals into Quicksilver's search paths.";
}

- (NSString*) uninstallInformativeText {
    return @"I will edit ~/Library/Application Support/Quicksilver/Catalog.plist and remove IRLauncher related entries from it.";
}

- (void) install {
    ILLOG_CURRENT_METHOD;

    [self installCatalog];
}

- (void) uninstall {
    ILLOG_CURRENT_METHOD;

    [self uninstallCatalog];
}

- (BOOL) installed {
    BOOL ret = [self isCatalogInstalled] && [self isActionInstalled];
    return ret;
}

- (void) didFinishInstallation {
    NSArray *quicksilvers = [NSRunningApplication runningApplicationsWithBundleIdentifier: kILQuicksilverBundleIdentifier];
    if (quicksilvers.count) {
        [self showConfirmToRelaunchQuicksilver:^(NSInteger returnCode) {
            NSRunningApplication *q = quicksilvers[ 0 ];
            BOOL success = [q terminate];
            if (!success) {
                ILLOG( @"failed to terminate quicksilver" );
            }
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    NSArray *quicksilvers = [NSRunningApplication runningApplicationsWithBundleIdentifier: kILQuicksilverBundleIdentifier];
                    if (quicksilvers.count) {
                        ILLOG( @"failed to terminate quicksilver" );
                        return;
                    }
                    BOOL success = [[NSWorkspace sharedWorkspace] launchAppWithBundleIdentifier: kILQuicksilverBundleIdentifier
                                                                                        options: NSWorkspaceLaunchDefault
                                                                 additionalEventParamDescriptor: NULL
                                                                               launchIdentifier: NULL];
                    if (!success) {
                        ILLOG( @"failed to launch quicksilver" );
                    }
                });
        }];
    }
}

- (void) didLearnSignal {
    [self didFinishInstallation];
}

#pragma mark - Private

- (void) installCatalog {
    if ([self isCatalogInstalled]) {
        return;
    }
    NSURL *catalogPath           = [self quicksilverCatalogPath];
    NSMutableDictionary *catalog = [[NSMutableDictionary alloc] initWithContentsOfURL: catalogPath];
    ILLOG( @"catalog: %@", catalog );

    if (!catalog[ @"customEntries" ]) {
        catalog[ @"customEntries" ] = @[];
    }
    NSMutableArray *customEntries = ((NSArray*)catalog[ @"customEntries" ]).mutableCopy;
    BOOL modified                 = NO;
    for (NSUInteger i=0,len=customEntries.count; i<len; i++) {
        NSDictionary *entry = customEntries[ i ];
        if ([entry[ @"settings" ][ @"path" ] isEqualToString: [ILFileStore signalsDirectory]]) {
            NSMutableDictionary *mutableEntry = entry.mutableCopy;
            mutableEntry[ @"enabled" ] = @YES;
            customEntries[ i ]         = mutableEntry;
            modified                   = YES;
        }
    }
    if (!modified) {
        NSDictionary *entry = @{
            @"ID": [NSString uniqueString], // this is how Quicksilver sets IDs; see QSCatalogEntry.m -(NSString*)identifier
            @"enabled":  @YES,
            @"name":     [ILFileStore signalsDirectory],
            @"settings": @{
                @"parser":   @"QSDirectoryParser",
                @"path":     [ILFileStore signalsDirectory],
                @"skipItem": @YES,
            },
            @"source":   @"QSFileSystemObjectSource",
        };
        [customEntries addObject: entry];
    }
    catalog[ @"customEntries" ] = customEntries;
    BOOL success = [catalog writeToURL: catalogPath atomically: YES];
    if (!success) {
        ILLOG( @"failed to write to %@", catalogPath );
    }
}

- (void) uninstallCatalog {
    if (![self isCatalogInstalled]) {
        return;
    }
    NSURL *catalogPath            = [self quicksilverCatalogPath];
    NSMutableDictionary *catalog  = [[NSMutableDictionary alloc] initWithContentsOfURL: catalogPath];
    BOOL modified                 = NO;
    NSMutableArray *customEntries = ((NSArray*)catalog[ @"customEntries" ]).mutableCopy;
    for (NSUInteger i=0,len=customEntries.count; i<len; i++) {
        NSDictionary *entry = customEntries[ i ];
        if ([entry[ @"settings" ][ @"path" ] isEqualToString: [ILFileStore signalsDirectory]] &&
            [entry[ @"enabled" ] boolValue]) {
            NSMutableDictionary *mutableEntry = entry.mutableCopy;
            mutableEntry[ @"enabled" ] = @NO;
            customEntries[ i ]         = mutableEntry;
            modified                   = YES;
        }
    }
    if (modified) {
        catalog[ @"customEntries" ] = customEntries;
        BOOL success = [catalog writeToURL: catalogPath atomically: YES];
        if (!success) {
            ILLOG( @"failed to write to %@", catalogPath );
        }
    }
}

- (BOOL) isCatalogInstalled {
    NSURL *catalogPath = [self quicksilverCatalogPath];
    id catalog         = [[NSDictionary alloc] initWithContentsOfURL: catalogPath];
    if (!catalog) {
        return NO;
    }
    NSDictionary *entry = [ILUtils firstObjectOf: catalog[ @"customEntries" ]
                                      meetsBlock: ^BOOL (NSDictionary *obj, NSUInteger idx) {
        NSString *path = obj[ @"settings" ][ @"path" ];
        if ([path isEqualToString: [ILFileStore signalsDirectory]]) {
            return YES;
        }
        return NO;
    }];
    if ([entry[ @"enabled" ] boolValue]) {
        return YES;
    }
    return NO;
}

- (BOOL) isActionInstalled {
    NSURL *senderPath = [self senderPath];
    return [senderPath checkResourceIsReachableAndReturnError: NULL];
}

- (NSURL*) quicksilverCatalogPath {
    NSURL *applicationSupportDirectory = [[NSFileManager defaultManager] URLsForDirectory: NSApplicationSupportDirectory
                                                                                inDomains: NSUserDomainMask][ 0 ];
    return [applicationSupportDirectory URLByAppendingPathComponent: @"Quicksilver/Catalog.plist"];
}

- (NSURL*) senderPath {
    NSURL *applicationSupportDirectory = [[NSFileManager defaultManager] URLsForDirectory: NSApplicationSupportDirectory
                                                                                inDomains: NSUserDomainMask][ 0 ];
    return [applicationSupportDirectory URLByAppendingPathComponent: @"Quicksilver/Actions/IRSender.scpt"];
}

- (void) showConfirmToRelaunchQuicksilver:(void (^)(NSInteger returnCode))callback {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle: @"OK"];
    [alert addButtonWithTitle: @"Cancel"];
    [alert setMessageText: @"Relaunch Quicksilver?"];
    [alert setAlertStyle: NSWarningAlertStyle];
    [[NSRunningApplication currentApplication] activateWithOptions: NSApplicationActivateIgnoringOtherApps];
    NSInteger ret = [alert runModal];
    callback( ret );
}

@end
