//
//  AKImage.m
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

#import "AKImage.h"
#import <QuartzCore/QuartzCore.h>


@implementation AKImage


+ (UIImage *)createImageNamed:(NSString *)imageName {
	if (imageName == nil || imageName.length == 0) {
		return nil;
	}

	NSString *ext = imageName.pathExtension;

	if (ext == nil || ext.length == 0) {
		return nil;
	}

	NSString *name = [imageName substringToIndex:imageName.length - ext.length - 1];

	if ([UIScreen mainScreen].scale == 1.0) {
		if ([name hasSuffix:@"@2x"]) {
			name = [name substringToIndex:name.length - 3];
		}
	}
	else if ([name hasSuffix:@"@2x"]) {
		NSString *s = [[NSBundle mainBundle] pathForResource:name ofType:ext];

		if (s == nil) {
			name = [name substringToIndex:name.length - 3];
		}
	}
	else {
		name = [name stringByAppendingString:@"@2x"];
		NSString *s = [[NSBundle mainBundle] pathForResource:name ofType:ext];

		if (s == nil) {
			name = [name substringToIndex:name.length - 3];
		}
	}

	NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:ext];
	return [[UIImage alloc] initWithContentsOfFile:path];
}


+ (UIImage *)croppedImageWithImage:(UIImage *)image rect:(CGRect)rect {
	if (image != nil) {
		if (image.imageOrientation == UIImageOrientationDown) {
			rect.origin.x = image.size.width - CGRectGetMaxX(rect);
			rect.origin.y = image.size.height - CGRectGetMaxY(rect);
		}
		else if (image.imageOrientation == UIImageOrientationLeft) {
			CGRect r;
			r.origin.x = image.size.height - CGRectGetMaxY(rect);
			r.origin.y = rect.origin.x;
			r.size.width = rect.size.height;
			r.size.height = rect.size.width;
			rect = r;
		}
		else if (image.imageOrientation == UIImageOrientationRight) {
			CGRect r;
			r.origin.x = rect.origin.y;
			r.origin.y = image.size.width - CGRectGetMaxX(rect);
			r.size.width = rect.size.height;
			r.size.height = rect.size.width;
			rect = r;
		}

		CGFloat scale = image.scale;

		rect.origin.x *= scale;
		rect.origin.y *= scale;
		rect.size.width *= scale;
		rect.size.height *= scale;

		CGImageRef imageRef = CGImageCreateWithImageInRect(image.CGImage, rect);
		image = [UIImage imageWithCGImage:imageRef scale:scale
			orientation:image.imageOrientation];
		CGImageRelease(imageRef);
	}

	return image;
}


+ (UIImage *)imageFromView:(UIView *)view {
	UIImage *image = nil;

	if (view != nil) {
		UIGraphicsBeginImageContextWithOptions(view.frame.size, NO, 0);
		[view.layer renderInContext:UIGraphicsGetCurrentContext()];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}

	return image;
}


+ (UIImage *)imageNamed:(NSString *)imageName {
	UIImage *image = [self createImageNamed:imageName];

	#if !__has_feature(objc_arc)
		[image autorelease];
	#endif

	return image;
}


+ (UIImage *)normalizeOrientationOfImage:(UIImage *)image {
	if (image != nil && image.imageOrientation != UIImageOrientationUp) {
		UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
		[image drawAtPoint:CGPointZero];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}

	return image;
}


+ (UIImage *)resizableImageWithImage:(UIImage *)image {
	return [self resizableImageWithImage:image insetLeft:round(0.5 * image.size.width) - 1.0];
}


+ (UIImage *)resizableImageWithImage:(UIImage *)image insetLeft:(CGFloat)insetLeft {
	if (image != nil) {
		CGSize size = image.size;
		CGFloat top = round(0.5 * size.height) - 1.0;
		image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(
			top, insetLeft,
			size.height - top - 1.0, size.width - insetLeft - 1.0)];
	}

	return image;
}


+ (UIImage *)resizableImageWithImage:(UIImage *)image insetRight:(CGFloat)insetRight {
	if (image != nil) {
		CGSize size = image.size;
		CGFloat top = round(0.5 * size.height) - 1.0;
		image = [image resizableImageWithCapInsets:UIEdgeInsetsMake(
			top, size.width - insetRight - 1.0,
			size.height - top - 1.0, insetRight)];
	}

	return image;
}


+ (UIImage *)resizedImageWithImage:(UIImage *)image size:(CGSize)size {
	if (image != nil) {
		UIGraphicsBeginImageContextWithOptions(size, NO, image.scale);
		CGContextSetInterpolationQuality(UIGraphicsGetCurrentContext(), kCGInterpolationHigh);
		[image drawInRect:CGRectMake(0, 0, size.width, size.height)];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}

	return image;
}


+ (UIImage *)tintImage:(UIImage *)image color:(UIColor *)color {
	if (image != nil && color != nil) {
		UIGraphicsBeginImageContextWithOptions(image.size, NO, image.scale);
		[color setFill];
		CGContextFillRect(UIGraphicsGetCurrentContext(),
			CGRectMake(0, 0, image.size.width, image.size.height));
		[image drawAtPoint:CGPointZero blendMode:kCGBlendModeDestinationIn alpha:1];
		image = UIGraphicsGetImageFromCurrentImageContext();
		UIGraphicsEndImageContext();
	}

	return image;
}


@end
