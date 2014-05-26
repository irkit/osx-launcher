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
#import "NSString+UUID.h"
#import "ILFileStore.h"

@implementation ILQuicksilverExtension

- (void) install {
    ILLOG_CURRENT_METHOD;

    [self installCatalog];
    [self installAction];
}

- (void) uninstall {
    ILLOG_CURRENT_METHOD;

    [self uninstallCatalog];
    [self uninstallAction];
}

- (BOOL) installed {
    return [self isCatalogInstalled] && [self isActionInstalled];
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

- (void) installAction {
    if ([self isActionInstalled]) {
        return;
    }
}

- (void) uninstallAction {
    // TODO
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

@end
