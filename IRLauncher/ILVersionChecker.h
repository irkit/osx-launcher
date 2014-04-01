//
//  ILVersionChecker.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/01/30.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ILVersionCheckerDelegate;

@interface ILVersionChecker : NSObject

@property (nonatomic, weak) id<ILVersionCheckerDelegate> delegate;

- (void) check;

@end

@protocol ILVersionCheckerDelegate <NSObject>

@required
- (void) checker: (ILVersionChecker*)checker didFindVersion: (NSString*) versionString onURL:(NSURL*)assetURL;
- (void) checker: (ILVersionChecker*)checker didFailCheckWithError: (NSError*) error;

@end
