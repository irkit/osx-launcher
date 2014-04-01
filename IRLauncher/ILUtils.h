//
//  ILUtils.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ILUtils : NSObject

+ (NSURL*) URLPathForVersion: (NSString*) versionString;
+ (void) downloadAssetURL: (NSURL*) assetURL toPathURL: (NSURL*) pathURL completion: (void (^)(NSError*)) completion;
+ (void) getModelNameAndVersion:(NSString*) hostname withCompletion:(void (^)(NSString *modelName, NSString *version)) completion;
+ (BOOL) releasedVersionString:(NSString*) releaseVersionString isNewerThanPeripheralVersion: (NSString*)peripheralVersion;

@end