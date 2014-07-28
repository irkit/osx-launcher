//
//  IRSignals+FileStore.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/27.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "IRSignals+FileStore.h"

@implementation IRSignals (FileStore)

- (void) loadFromFilesUnderDirectory: (NSString*)signalsDirectory completion:(void (^)(NSError *error))completion {
    [self findSignalsUnderDirectory: [NSURL fileURLWithPath: signalsDirectory]
                         completion: ^(NSArray *foundSignals, NSError *error) {
        if (error) {
            completion(error);
            return;
        }

        [foundSignals enumerateObjectsUsingBlock: ^(NSDictionary *signalInfo, NSUInteger idx, BOOL *stop) {
                IRSignal *signal = [[IRSignal alloc] initWithDictionary: signalInfo];
                [self addSignalsObject: signal];
            }];
        completion(nil);
    }];
}

#pragma mark - Private

- (void) findSignalsUnderDirectory: (NSURL*)signalsURL completion: (void (^)(NSArray *foundSignals, NSError *error)) completion {
    // ILLOG( @"signalsURL: %@", signalsURL );

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *ret = @[].mutableCopy;

        NSFileManager *manager = [NSFileManager defaultManager];
        NSError *error;
        // Enumerate the directory (specified elsewhere in your code)
        // Request the two properties the method uses, name and isDirectory
        // Ignore hidden files
        NSArray *fileURLs = [manager contentsOfDirectoryAtURL: signalsURL
                                   includingPropertiesForKeys: @[ NSURLNameKey, NSURLIsDirectoryKey, NSURLContentModificationDateKey ]
                                                      options: NSDirectoryEnumerationSkipsHiddenFiles|NSDirectoryEnumerationSkipsSubdirectoryDescendants|NSDirectoryEnumerationSkipsPackageDescendants
                                                        error: &error];
        if (error) {
            completion( nil, error );
            return;
        }

        fileURLs = [[fileURLs filteredArrayUsingPredicate: [NSPredicate predicateWithBlock:^BOOL (NSURL *evaluatedObject, NSDictionary *bindings) {
                        NSError *error;
                        NSNumber *isDirectory;
                        [evaluatedObject getResourceValue: &isDirectory forKey: NSURLIsDirectoryKey error: &error];
                        if (error || [isDirectory boolValue]) {
                            return NO;
                        }
                        return YES;
                    }]] sortedArrayUsingComparator:^NSComparisonResult (NSURL *obj1, NSURL *obj2) {
                NSDate *modifiedDate1, *modifiedDate2;
                NSError *error;
                // modified date is cached during the enumeration.
                [obj1 getResourceValue: &modifiedDate1 forKey: NSURLAttributeModificationDateKey error: &error];
                if (error) {
                    return (NSComparisonResult)NSOrderedAscending;
                }
                [obj2 getResourceValue: &modifiedDate2 forKey: NSURLAttributeModificationDateKey error: &error];
                if (error) {
                    return (NSComparisonResult)NSOrderedDescending;
                }
                return [modifiedDate1 compare: modifiedDate2];
            }];

        // Enumerate the dirEnumerator results, each value is stored in allURLs
        for (NSURL *fileURL in fileURLs) {

            // Retrieve the file name. From NSURLNameKey, cached during the enumeration.
            NSString *fileName;
            [fileURL getResourceValue: &fileName forKey: NSURLNameKey error: NULL];

            NSData *content = [manager contentsAtPath: [fileURL path]];
            NSMutableDictionary *object = [NSJSONSerialization JSONObjectWithData: content
                                                                          options: NSJSONReadingMutableContainers
                                                                            error: &error];
            object[ @"name" ] = [[fileURL URLByDeletingPathExtension] lastPathComponent];
            [ret addObject: object];
        }

        dispatch_async( dispatch_get_main_queue(), ^{
                completion( ret, nil );
            });
    });
}

@end
