//
//  ILFileStore.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/15.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILFileStore.h"
#import "IRPeripheral.h"

#define ILLOG_DISABLED 1

#import "ILLog.h"
#import "ILConst.h"
#import <sys/xattr.h>

static NSString * const kILConfigDirectory     = @".irkit.d/";
static NSString * const kILSignalsSubDirectory = @"signals/";

@interface ILFileStore ()

@property (nonatomic) NSMutableDictionary *entity;

@end

@implementation ILFileStore

#pragma mark - Class methods

+ (NSString*) configDirectory {
    return [NSHomeDirectory() stringByAppendingFormat: @"/%@", kILConfigDirectory];
}

+ (NSString*) signalsDirectory {
    return [[self configDirectory] stringByAppendingString: kILSignalsSubDirectory];
}

+ (BOOL) saveSignal:(IRSignal *)signal error:(NSError**) error {
    if (!signal.name) {
        // name is required
        *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                     code: IRLauncherErrorCodeInvalidFile
                                 userInfo: @{ NSLocalizedDescriptionKey: NSLocalizedString( @"name is required", @"ILFileStore error description of signal without name" )}];
        return NO;
    }
    if (![signal.name isEqualToString: signal.name.lastPathComponent]) {
        // name includes "/" equivalent
        *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                     code: IRLauncherErrorCodeInvalidFile
                                 userInfo: @{ NSLocalizedDescriptionKey: [NSString stringWithFormat: NSLocalizedString(@"Choose a file directly under %@", @"ILFileStore error description of signal including /"),[self signalsDirectory]] }];
        return NO;
    }

    NSData *json = [NSJSONSerialization dataWithJSONObject: signal.asSendableDictionary
                                                   options: NSJSONWritingPrettyPrinted
                                                     error: error];
    if (*error) {
        ILLOG( @"failed to serialize: %@, error: %@", signal.asSendableDictionary, *error );
        return NO;
    }

    // We'll deal with errors when write fails
    BOOL created = [[NSFileManager defaultManager] createDirectoryAtPath: [self signalsDirectory]
                                             withIntermediateDirectories: YES
                                                              attributes: nil
                                                                   error: error];
    if (!created) {
        ILLOG( @"createDirectoryAtPath:... failed with error: %@", error );
        return NO;
    }

    NSString *basename    = [NSString stringWithFormat: @"%@.json", signal.name];
    NSString *file        = [[self signalsDirectory] stringByAppendingPathComponent: basename];
    NSString *cleanedFile = [file stringByStandardizingPath];
    if (![file isEqualToString: cleanedFile]) {
        *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                     code: IRLauncherErrorCodeInvalidFile
                                 userInfo: @{ NSLocalizedDescriptionKey: [NSString stringWithFormat: NSLocalizedString(@"Choose a file directly under %@", @"ILFileStore error description of signal including /"),[self signalsDirectory]] }];
        return NO;
    }
    // overwrites file
    BOOL success = [json writeToURL: [NSURL fileURLWithPath: file]
                            options: NSDataWritingAtomic
                              error: error];
    if (!success) {
        return NO;
    }

    [self setSignalExtendedAttributesToFile: file];
    return YES;
}

// How to create ResourceFork.dat:
// 1. Use Finder.app to set custom application against ~/.irkit.d/signals/open-in-customapp.json
// 2. DeRez -only usro ~/.irkit.d/signals/open-in-customapp.json > open-in-customapp.usro
// 3. xattr -c ~/.irkit.d/signals/temp.json
// 4. Rez open-in-customapp.usro -append -o ~/.irkit.d/signals/temp.json
// 5. Products/Xattr com.apple.ResourceFork ~/.irkit.d/signals/temp.json > ../IRLauncher/Attributes/ResourceFork.dat
+ (int)setSignalExtendedAttributesToFile:(NSString*)file {
    // `bundleForClass:[self class]` to make this work in tests
    NSString *resourceForkFile = [[NSBundle bundleForClass: [self class]] pathForResource: @"ResourceFork" ofType: @"dat"];
    NSData *resourceFork       = [NSData dataWithContentsOfFile: resourceForkFile];

    int result;
    result = setxattr([file fileSystemRepresentation], XATTR_RESOURCEFORK_NAME, resourceFork.bytes, resourceFork.length, 0, 0);
    if (result != 0) {
        perror("setxattr resourcefork");
        return result;
    }

    // 512x512
    NSString *path = [[NSBundle bundleForClass: [self class]] pathForResource: @"IRSignalIcon" ofType: @"png"];
    NSImage *image = [[NSImage alloc] initWithContentsOfFile: path];
    [[NSWorkspace sharedWorkspace] setIcon: image
                                   forFile: file
                                   options: NSExcludeQuickDrawElementsIconCreationOption];

    return result;
}

@end
