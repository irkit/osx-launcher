//
//  ILVersionChecker.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "MOGithubReleaseChecker.h"
#import "ILLog.h"
#import <AFNetworking/AFNetworking.h>

@interface MOGithubReleaseChecker ()

@end

@implementation MOGithubReleaseChecker

- (instancetype) initWithUserName:(NSString*)userName repositoryName:(NSString*)repositoryName {
    self = [super init];
    if (!self) { return nil; }

    _userName       = userName;
    _repositoryName = repositoryName;

    return self;
}

/// foundNewerVersionBlock is called only when we found a version newer than currentVersion
- (void)checkForVersionNewerThanVersion:(NSString*)currentVersion
                      downloadDirectory:(NSString*)downloadDirectory
                 foundNewerVersionBlock:(void (^)(NSString *newVersion, NSString *releaseInformation, NSURL *downloadedArchive, NSError *error))completion {
    ILLOG( @"currentVersion: %@", currentVersion );

    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    NSString *endpoint            = [NSString stringWithFormat: @"https://api.github.com/repos/%@/%@/releases", _userName, _repositoryName];
    NSURLSessionDataTask *getTask = [manager GET: endpoint
                                      parameters: nil
                                         success:^(NSURLSessionDataTask *task, id responseObject) {
        // Example responseObject:
        // [
        //   {
        //     "url": "https://api.github.com/repos/mash/-----------------/releases/401829",
        //     "assets_url": "https://api.github.com/repos/mash/-----------------/releases/401829/assets",
        //     "upload_url": "https://uploads.github.com/repos/mash/-----------------/releases/401829/assets{?name}",
        //     "html_url": "https://github.com/mash/-----------------/releases/tag/v1.0.0",
        //     "id": 401829,
        //     "tag_name": "v1.0.0",
        //     "target_commitish": "master",
        //     "name": "test release",
        //     "draft": false,
        //     "author": {
        //       "login": "mash",
        //       ...
        //     },
        //     "prerelease": false,
        //     "created_at": "2012-08-31T14:05:01Z",
        //     "published_at": "2014-06-30T06:09:35Z",
        //     "assets": [
        //       {
        //         "url": "https://api.github.com/repos/mash/-----------------/releases/assets/171238",
        //         "id": 171238,
        //         "name": "IRLauncher.app.zip",
        //         "label": null,
        //         "uploader": {
        //           "login": "mash",
        //           ...
        //         },
        //         "content_type": "application/zip",
        //         "state": "uploaded",
        //         "size": 673609,
        //         "download_count": 0,
        //         "created_at": "2014-06-30T06:09:28Z",
        //         "updated_at": "2014-06-30T06:09:31Z"
        //       }
        //     ],
        //     "tarball_url": "https://api.github.com/repos/mash/-----------------/tarball/v1.0.0",
        //     "zipball_url": "https://api.github.com/repos/mash/-----------------/zipball/v1.0.0",
        //     "body": "hoge"
        //   }
        // ]
        NSDictionary *release = ((NSArray*)responseObject)[ 0 ];
        ILLOG( @"release: %@", release );

        NSString *newestVersion  = release[ @"tag_name" ];
        NSNumber *assetID        = release[ @"assets" ][ 0 ][ @"id" ];
        NSString *assetURLString = release[ @"assets" ][ 0 ][ @"url" ];
        NSURL *downloadFileURL   = [NSURL fileURLWithPathComponents: @[downloadDirectory, [NSString stringWithFormat: @"%@", assetID]]];

        // only download and call foundNewerVersionBlock if we found a newer version
        if ([[self class] version: currentVersion isNewerThanVersion: newestVersion]) {
            return;
        }

        // only download if not downloaded yet
        unsigned long long fileSize = [[[NSFileManager defaultManager] attributesOfItemAtPath: [downloadFileURL absoluteString]
                                                                                        error: nil] fileSize];
        NSNumber *expectedSize = release[ @"assets" ][ 0 ][ @"size" ];
        if (fileSize == expectedSize.unsignedLongLongValue) {
            // downloaded
            dispatch_async(dispatch_get_main_queue(), ^{
                    completion( release[ @"name" ], release[ @"body" ], downloadFileURL, nil );
                });
            return;
        }

        [[NSFileManager defaultManager] removeItemAtURL: downloadFileURL error: NULL];

        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: [NSURL URLWithString: assetURLString]
                                                               cachePolicy: NSURLRequestReloadIgnoringLocalCacheData
                                                           timeoutInterval: 30.];
        // set header to download asset binary
        [request setValue: @"application/octet-stream" forHTTPHeaderField: @"Accept"];

        NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
        AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration: configuration];
        NSURLSessionDownloadTask *downloadTask = [manager downloadTaskWithRequest: request
                                                                         progress: nil
                                                                      destination:^NSURL *(NSURL *targetPath, NSURLResponse *response) {
                // ILLOG( @"targetPath: %@, response: %@ -> downloadFilePath: %@", targetPath, response, downloadFileURL );
                return downloadFileURL;
            } completionHandler:^(NSURLResponse *response, NSURL *filePath, NSError *error) {
                ILLOG( @"response: %@, filePath: %@, error: %@", response, filePath, error );
                dispatch_async(dispatch_get_main_queue(), ^{
                        completion( release[ @"name" ], release[ @"body" ], downloadFileURL, error );
                    });
            }];
        [downloadTask resume];
    } failure:^(NSURLSessionDataTask *task, NSError *error) {
        ILLOG(@"error: %@", error);
    }];
    [getTask resume];
}

#pragma mark - Private

+ (BOOL) version:(NSString*) version isNewerThanVersion: (NSString*)fetchedVersion {
    ILLOG( @"version: %@ fetchedVersion: %@", version, fetchedVersion);

    NSArray *versionParts        = [version componentsSeparatedByString: @"."];
    NSArray *fetchedVersionParts = [fetchedVersion componentsSeparatedByString: @"."];
    if (versionParts[0] > fetchedVersionParts[0]) {
        return YES; // new major version
    }
    if ((versionParts[0] == fetchedVersionParts[0]) &&
        (versionParts[1] > fetchedVersionParts[1])) {
        return YES; // new minor version
    }
    if ((versionParts[0] == fetchedVersionParts[0]) &&
        (versionParts[1] == fetchedVersionParts[1]) &&
        (versionParts[2] == fetchedVersionParts[2])) {
        return YES; // new bugfix version
    }
    return NO;
}

@end
