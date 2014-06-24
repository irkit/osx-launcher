//
//  ILExtension.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/05/07.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ILLauncherExtension <NSObject>

@required
/// Used in various places
/// ex: Status bar, Install confirm alert title,..
- (NSString*) title;
/// Informative text in alert to confirm user we're going to install this extension (apply changes to your file system)
- (NSString*) installInformativeText;
/// Informative text in alert to confirm user we're going to uninstall this extension.
- (NSString*) uninstallInformativeText;
/// Do modify file system to install extension.
/// Launcher should somehow start to index JSON files under ~/.irkit.d/signals/ ,
/// and open IRLauncher.app passing the JSON file path as an argument.
- (void) install;
/// Do modify file system to uninstall extension.
- (void) uninstall;
/// Return if extension is installed
- (BOOL) installed;

@optional
/// Optionally called after install finished.
/// You might want to relaunch launcher app to start indexing.
- (void) didFinishInstallation;
/// Optionally called after we learned a new IR signal.
/// You might want to relaunch launcher app to start indexing.
- (void) didLearnSignal;

@end
