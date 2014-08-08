//
//  ILConst.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/02/03.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#ifndef IRLauncher_const_h
#define IRLauncher_const_h

#define IRKitModelName @"IRKit"

#pragma mark - Errors

#define IRKitErrorDomain                                      @"irkit"
#define IRKitErrorDomainHTTP                                  @"irkit.http"
#define IRLauncherErrorDomain                                 IRKitErrorDomain
#define IRLauncherErrorCodeInvalidTag                         1
#define IRLauncherErrorCodeUnsupported                        2
#define IRLauncherErrorCodeInvalidFile                        3
#define IRLauncherErrorCodeNotFound                           4
#define IRLauncherErrorCodePeripheralNotFound                 5

#define IRKitHTTPStatusCodeUnknown                            999

#pragma mark - URLs

#define STATICENDPOINT_BASE                                   @"http://getirkit.com"
#define APIENDPOINT_BASE                                      @"https://api.getirkit.com"

#pragma mark - Notifications

extern NSString * const kILWillSendSignalNotification;

#pragma mark - Make C strings into NSStrings

#define NSStringize_helper(x) #x
#define NSStringize(x) @NSStringize_helper(x)

#endif
