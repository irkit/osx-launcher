//
//  ILUtils.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "ILUtils.h"
#import <AFNetworking/AFNetworking.h>
#import "NSFileManager+DirectoryLocations.h"

@implementation ILUtils

+ (NSURL*) URLPathForVersion: (NSString*) versionString {
    NSString *directory = [[NSFileManager defaultManager] applicationSupportDirectory];
    NSURL *directoryURL = [NSURL fileURLWithPath: directory];
    return [directoryURL URLByAppendingPathComponent: versionString];
}

+ (void) downloadAssetURL: (NSURL*) assetURL toPathURL: (NSURL*) pathURL completion: (void (^)(NSError*)) completion {
    NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
    AFURLSessionManager *manager             = [[AFURLSessionManager alloc] initWithSessionConfiguration: configuration];

    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: assetURL];
    [request setValue: @"application/octet-stream" forHTTPHeaderField: @"Content-Type"];

    NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest: request progress: nil destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
        return pathURL;
    } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
        LOG(@"File downloaded to: %@", filePath);
        completion(error);
    }];
    [downloadTask resume];
}

+ (void) getModelNameAndVersion:(NSString*) hostname withCompletion:(void (^)(NSString *modelName, NSString *version))completion {
    AFHTTPRequestOperationManager *manager = [AFHTTPRequestOperationManager manager];
    NSString *url                          = [NSString stringWithFormat: @"http://%@/", hostname];
    [manager GET: url parameters: nil success:^(AFHTTPRequestOperation *operation, id responseObject) {
        LOG(@"JSON: %@", responseObject);
        NSHTTPURLResponse *res = operation.response;
        NSString* server = res.allHeaderFields[ @"Server" ];
        if (!server) {
            return;
        }
        NSArray* tmp = [server componentsSeparatedByString: @"/"];
        if (tmp.count != 2) {
            return;
        }
        completion( tmp[0], tmp[1] );
        return;
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        LOG(@"Error: %@", error);
    }];
}

+ (BOOL) releasedVersionString:(NSString*) releaseVersionString isNewerThanPeripheralVersion: (NSString*)peripheralVersion {
    LOG( @"releaseVersion: %@ peripheralVersion: %@", releaseVersionString, peripheralVersion);

    NSArray *releaseVersionParts    = [[releaseVersionString substringFromIndex: 1] componentsSeparatedByString: @"."];
    NSArray *peripheralVersionParts = [peripheralVersion componentsSeparatedByString: @"."];
    if (releaseVersionParts[0] > peripheralVersionParts[0]) {
        return YES; // new major version
    }
    if ((releaseVersionParts[0] == peripheralVersionParts[0]) &&
        (releaseVersionParts[1] > peripheralVersionParts[1])) {
        return YES; // new minor version
    }
    if ((releaseVersionParts[0] == peripheralVersionParts[0]) &&
        (releaseVersionParts[1] == peripheralVersionParts[1]) &&
        (releaseVersionParts[2] == peripheralVersionParts[2])) {
        return YES; // new bugfix version
    }
    return NO;
}

@end
