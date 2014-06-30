//
//  MOApplicationUpdater.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/28.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MOApplicationUpdater : NSObject

- (instancetype) initWithArchiveURL: (NSURL*)archiveURL;
- (void) run;

@end
