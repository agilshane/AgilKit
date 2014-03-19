//
//  AKImage.h
//  AgilKit
//
//  Created by Shane Meyer on 3/29/13.
//  Copyright (c) 2013 Agilstream, LLC.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy of this
//  software and associated documentation files (the "Software"), to deal in the Software
//  without restriction, including without limitation the rights to use, copy, modify, merge,
//  publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons
//  to whom the Software is furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all copies or
//  substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,
//  INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
//  PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE
//  FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR
//  OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
//  DEALINGS IN THE SOFTWARE.
//

#import <Foundation/Foundation.h>

@interface AKImage : NSObject

// Works like [AKImage imageNamed:] but doesn't autorelease.
+ (UIImage *)createImageNamed:(NSString *)imageName;

// Returns a cropped image.
+ (UIImage *)croppedImageWithImage:(UIImage *)image rect:(CGRect)rect;

// Converts a view to an image.
+ (UIImage *)imageFromView:(UIView *)view;

// Works like [UIImage imageNamed:] but doesn't cache.
+ (UIImage *)imageNamed:(NSString *)imageName;

// Returns an image oriented up, if it isn't already.
+ (UIImage *)normalizeOrientationOfImage:(UIImage *)image;

// Returns a resizable image with a 1x1 point that is not capped.  The point is centered
// vertically and horizontally.
+ (UIImage *)resizableImageWithImage:(UIImage *)image;

// Returns a resizable image with a 1x1 point that is not capped.  The point is centered
// vertically and uses the given left inset.
+ (UIImage *)resizableImageWithImage:(UIImage *)image insetLeft:(CGFloat)insetLeft;

// Returns a resizable image with a 1x1 point that is not capped.  The point is centered
// vertically and uses the given right inset.
+ (UIImage *)resizableImageWithImage:(UIImage *)image insetRight:(CGFloat)insetRight;

// Returns a resized image.
+ (UIImage *)resizedImageWithImage:(UIImage *)image size:(CGSize)size;

// Replaces all pixels with the given color, preserving the alpha channel.
+ (UIImage *)tintImage:(UIImage *)image color:(UIColor *)color;

@end
