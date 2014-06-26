//
//  main.m
//  Xattr
//
//  Created by Masakazu Ohtsuka on 2014/06/24.
//  Copyright (c) 2014年 maaash.jp. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <sys/xattr.h> // setxattr, getxattr

NSData* readAttributes ( const char *path, const char *attributeName ) {
    ssize_t attributeSize = getxattr(path, attributeName, NULL, 0, 0, 0);
    if (attributeSize <= 0) {
        return nil;
    }

    char *buffer = malloc(attributeSize);

    getxattr(path, attributeName, buffer, attributeSize, 0, 0);
    NSData *ret = [NSData dataWithBytes: buffer length: attributeSize];

    free(buffer);

    return ret;
}

int writeAttributes ( const char *path, const char *attributeName, NSData *data ) {
    return setxattr(path, attributeName, data.bytes, data.length, 0, 0);
}

// read: $0 com.apple.ResourceFork path/to/filename > ResourceFork.dat
// write: cat ResourceFork.dat | $0 com.apple.ResourceFork path/to/filename
int main(int argc, const char * argv[]) {
    @autoreleasepool {
        const char *programPath = argv[ 0 ];
        if (argc != 3) {
            fprintf(stderr, "usage:\n  read: %s com.apple.FinderInfo path/to/file > FinderInfo.dat\n  write: cat FinderInfo.dat | %s com.apple.FinderInfo path/to/file\n", programPath, programPath);
            exit(1);
        }
        const char *attributeName = argv[ 1 ];
        const char *path          = argv[ 2 ];
        NSData *attributesData    = readAttributes( path, attributeName );
        fwrite(attributesData.bytes, attributesData.length, 1, stdout);
    }
    return 0;
}

