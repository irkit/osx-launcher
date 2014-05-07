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

NSString * const kSignalsPath = @"~/.irkit.d/signals";

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
    NSURL *catalogPath = [self quicksilverCatalogPath];
    id catalog         = [[NSDictionary alloc] initWithContentsOfURL: catalogPath];
    ILLOG( @"catalog: %@", catalog );
}

- (void) installAction {
    if ([self isActionInstalled]) {
        return;
    }
}

- (void) uninstallCatalog {
    // TODO
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
                                      meetsBlock: ^BOOL (id obj, NSUInteger idx) {
        NSString *path = obj[ @"settings" ][ @"path" ];
        if ([path isEqualToString: kSignalsPath]) {
            return YES;
        }
        return NO;
    }];
    if (!entry) {
        return NO;
    }
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
