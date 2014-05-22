//
//  ILExtension.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/05/07.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ILExtension <NSObject>

@required
- (void) install;
- (void) uninstall;
- (BOOL) installed;

@end
