//
//  ILSignalsDirectorySearcher.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/04/04.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILSignalsDirectorySearcher.h"
#import "ILLog.h"

@implementation ILSignalsDirectorySearcher

+ (void) findSignalsUnderDirectory: (NSURL*)signalsURL completion: (void (^)(NSArray *foundSignals, NSError *error)) completion {
    ILLOG( @"signalsURL: %@", signalsURL );

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *ret = @[].mutableCopy;

        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error;
        // Enumerate the directory (specified elsewhere in your code)
        // Request the two properties the method uses, name and isDirectory
        // Ignore hidden files
        NSArray *fileURLs = [manager contentsOfDirectoryAtURL: signalsURL
                                   includingPropertiesForKeys: @[ NSURLNameKey, NSURLIsDirectoryKey ]
                                                      options: NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsPackageDescendants
                                                        error: &error];
        if (error) {
            completion( nil, error );
            return;
        }

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
                completion( ret, nil );
            });
    });
}

@end
