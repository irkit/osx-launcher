//
//  ILStatusItem.m
//  IRLauncher
//
//  Created by Masakazu Ohtsuka on 2014/06/19.
//  Copyright (c) 2014年 Masakazu Ohtsuka. All rights reserved.
//

#import "MOAnimatingStatusItem.h"
#import "ILLog.h"

@interface MOAnimatingStatusItem ()

@property (nonatomic) NSUInteger nextImageIndex;
@property (nonatomic) NSUInteger maxImageIndex;

@end

@implementation MOAnimatingStatusItem

- (instancetype) init {
    self = [super init];
    if (!self) { return nil; }

    _statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength: 30.];
    [_statusItem setHighlightMode: YES];

    return self;
}

- (void) startAnimating {
    ILLOG_CURRENT_METHOD;
    if (_isAnimating) {
        return;
    }
    if (!_animationImages.count) {
        NSAssert( 0, @"Should set animationImages before startAnimating" );
    }
    if (!_animationDuration) {
        NSAssert( 0, @"Should set animationDuration before startAnimating" );
    }

    _isAnimating    = YES;
    _nextImageIndex = 0;
    _maxImageIndex  = _animationRepeatCount * _animationImages.count;

    [self animate];
}

- (void) stopAnimating {
    ILLOG_CURRENT_METHOD;
    if (!_isAnimating) {
        return;
    }
    _isAnimating = NO;
    [_statusItem setImage: _image];
}

- (void) setImage:(NSImage *)image {
    _image = image;
    [_statusItem setImage: _image];
}

- (void) setAlternateImage:(NSImage *)alternateImage {
    _alternateImage = alternateImage;
    [_statusItem setAlternateImage: _alternateImage];
}

#pragma mark - Private

- (void) animate {
    // ILLOG_CURRENT_METHOD;

    if (!_isAnimating) {
        return;
    }

    [_statusItem setImage: _animationImages[ _nextImageIndex % _animationImages.count ]];

    _nextImageIndex++;

    if (_nextImageIndex == _maxImageIndex) {
        [self stopAnimating];
        return;
    }

    [self performSelector: @selector(animate)
               withObject: nil
               afterDelay: _animationDuration / _animationImages.count];
}

@end
