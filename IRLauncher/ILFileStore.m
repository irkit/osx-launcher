//
//  ILSignalsDirectoryStore.m
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
                                 userInfo: @{ NSLocalizedDescriptionKey: @"name is required"}];
        return NO;
    }
    if ([signal.name rangeOfString: @"/"].location != NSNotFound) {
        *error = [NSError errorWithDomain: IRLauncherErrorDomain
                                     code: IRLauncherErrorCodeInvalidFile
                                 userInfo: @{ NSLocalizedDescriptionKey: [NSString stringWithFormat: @"Choose a file directly under %@",[self signalsDirectory]] }];
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
                                 userInfo: @{ NSLocalizedDescriptionKey: [NSString stringWithFormat: @"Choose a file directly under %@",[self signalsDirectory]] }];
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

#pragma mark - Private

+ (int)setSignalExtendedAttributesToFile:(NSString*)file {
    NSString *finderInfoFile   = [[NSBundle mainBundle] pathForResource: @"FinderInfo"   ofType: @"dat"];
    NSString *resourceForkFile = [[NSBundle mainBundle] pathForResource: @"ResourceFork" ofType: @"dat"];
    NSData *finderInfo         = [NSData dataWithContentsOfFile: finderInfoFile];
    NSData *resourceFork       = [NSData dataWithContentsOfFile: resourceForkFile];

    int result;
    result = setxattr([file fileSystemRepresentation], XATTR_FINDERINFO_NAME, finderInfo.bytes, finderInfo.length, 0, 0);
    if (result != 0) {
        perror("setxattr finderinfo");
        return result;
    }
    result = setxattr([file fileSystemRepresentation], XATTR_RESOURCEFORK_NAME, resourceFork.bytes, resourceFork.length, 0, 0);
    if (result != 0) {
        perror("setxattr resourcefork");
        return result;
    }

    return result;
}

@end
