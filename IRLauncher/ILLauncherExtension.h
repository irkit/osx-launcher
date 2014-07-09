//
//  ILExtension.h
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/05/07.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ILLauncherExtension <NSObject>

// Since Alfred 2 can move it's preferences directory to a user defined place,
// even if we can read ~/Library/Preferences and detect that,
// I feel the "Uninstall Quicksilver/Alfred Extension" feature too hacky/dangerous
// and too hard to support for a long period,
// thus decided not to implement it.
// Installing Quicksilver extension already seems going too far.

@required
/// Used in various places
/// ex: Status bar, Install confirm alert title,..
- (NSString*) title;
/// Informative text in alert to confirm user we're going to install this extension (apply changes to your file system)
- (NSString*) installInformativeText;
/// Do modify file system to install extension.
/// Launcher should somehow start to index JSON files under ~/.irkit.d/signals/ ,
/// and open IRLauncher.app passing the JSON file path as an argument.
- (void) install;

@optional
/// Return if extension is installed
- (BOOL) installed;
/// Optionally called after install finished.
/// You might want to relaunch launcher app to start indexing.
- (void) didFinishInstallation;
/// Optionally called after we learned a new IR signal.
/// You might want to relaunch launcher app to start indexing.
- (void) didLearnSignal;

@end
