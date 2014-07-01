//
//  AUInstaller.m
//  AutoUpdater
//
//  Created by Masakazu Ohtsuka on 2014/07/01.
//  Copyright (c) 2014年 maaash.jp. All rights reserved.
//

#import "AUInstaller.h"
#include <sys/xattr.h>

@interface AUInstaller ()

@property (nonatomic) NSString *destination;
@property (nonatomic) NSString *source;

@end

@implementation AUInstaller

- (instancetype) initWithDestinationPath:(NSString*)destinationPath
                              sourcePath:(NSString*)sourcePath {
    self = [super init];
    if (!self) { return nil; }

    _destination = destinationPath;
    _source      = sourcePath;

    return self;
}

- (void) installWithCompletion: (void (^)(NSError *error))completion {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSError *error;
        NSURL *destinationURL = [NSURL fileURLWithPath: self.destination];
        BOOL success          = [[NSFileManager defaultManager] replaceItemAtURL: destinationURL
                                                                   withItemAtURL: [NSURL fileURLWithPath: self.source]
                                                                  backupItemName: nil
                                                                         options: 0
                                                                resultingItemURL: &destinationURL
                                                                           error: &error];
        if (!success) {
            // TODO error handling
            dispatch_async(dispatch_get_main_queue(), ^{
                    completion( error );
                });
            return;
        }

        [AUInstaller releaseFromQuarantine: self.destination];

        dispatch_async(dispatch_get_main_queue(), ^{
                completion( nil );
            });
    });
}

// following copied from SUPlainInstaller (MMExtendedAttributes)

+ (int)removeXAttr:(const char*)name
          fromFile:(NSString*)file
           options:(int)options {
    // *** MUST BE SAFE TO CALL ON NON-MAIN THREAD!

    const char* path = NULL;
    @try {
        path = [file fileSystemRepresentation];
    }
    @catch (id) {
        // -[NSString fileSystemRepresentation] throws an exception if it's
        // unable to convert the string to something suitable.  Map that to
        // EDOM, "argument out of domain", which sort of conveys that there
        // was a conversion failure.
        errno = EDOM;
        return -1;
    }

    return removexattr(path, name, options);
}

+ (void)releaseFromQuarantine:(NSString*)root {
    // *** MUST BE SAFE TO CALL ON NON-MAIN THREAD!

    const char* quarantineAttribute = "com.apple.quarantine";
    const int removeXAttrOptions    = XATTR_NOFOLLOW;

    [self removeXAttr: quarantineAttribute
             fromFile: root
              options: removeXAttrOptions];

    // Only recurse if it's actually a directory.  Don't recurse into a
    // root-level symbolic link.
    NSDictionary* rootAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath: root error: nil];
    NSString* rootType           = rootAttributes[NSFileType];

    if (rootType == NSFileTypeDirectory) {
        // The NSDirectoryEnumerator will avoid recursing into any contained
        // symbolic links, so no further type checks are needed.
        NSDirectoryEnumerator* directoryEnumerator = [[NSFileManager defaultManager] enumeratorAtPath: root];
        NSString* file                             = nil;
        while ((file = [directoryEnumerator nextObject])) {
            [self removeXAttr: quarantineAttribute
                     fromFile: [root stringByAppendingPathComponent: file]
                      options: removeXAttrOptions];
        }
    }
}

@end
