//
//  AKColor.m
//  AgilKit
//
//  Created by Shane Meyer on 3/29/13.
//  Copyright (c) 2013-2014 Agilstream, LLC.
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

#import "AKColor.h"
#import "AKHex.h"


@interface AKColor ()

+ (int)hexCharToInt:(unichar)hexChar;

@end


@implementation AKColor


+ (UIColor *)colorWithRRGGBB:(NSString *)rrggbb {
	if (rrggbb == nil || (rrggbb.length != 6 && rrggbb.length != 8)) {
		return nil;
	}

	unichar r0 = [rrggbb characterAtIndex:0];
	unichar r1 = [rrggbb characterAtIndex:1];
	unichar g0 = [rrggbb characterAtIndex:2];
	unichar g1 = [rrggbb characterAtIndex:3];
	unichar b0 = [rrggbb characterAtIndex:4];
	unichar b1 = [rrggbb characterAtIndex:5];

	int r = [self hexCharToInt:r0] * 16 + [self hexCharToInt:r1];
	int g = [self hexCharToInt:g0] * 16 + [self hexCharToInt:g1];
	int b = [self hexCharToInt:b0] * 16 + [self hexCharToInt:b1];
	int a = 255;

	if (rrggbb.length == 8) {
		unichar a0 = [rrggbb characterAtIndex:6];
		unichar a1 = [rrggbb characterAtIndex:7];
		a = [self hexCharToInt:a0] * 16 + [self hexCharToInt:a1];
	}

	return [UIColor colorWithRed:r/255.0 green:g/255.0 blue:b/255.0 alpha:a/255.0];
}


+ (void)
	componentsOfColor:(UIColor *)color
	r:(CGFloat *)r
	g:(CGFloat *)g
	b:(CGFloat *)b
	a:(CGFloat *)a
{
	*r = 0;
	*g = 0;
	*b = 0;
	*a = 0;

	if (color != nil) {
		size_t numComponents = CGColorGetNumberOfComponents(color.CGColor);
		const CGFloat *components = CGColorGetComponents(color.CGColor);

		if (numComponents == 2) {
			// Monochrome
			*r = components[0];
			*g = components[0];
			*b = components[0];
			*a = components[1];
		}
		else if (numComponents == 4) {
			// RGBA
			*r = components[0];
			*g = components[1];
			*b = components[2];
			*a = components[3];
		}
		else {
			NSLog(@"Got a color with %zd components!", numComponents);
		}
	}
}


+ (int)hexCharToInt:(unichar)hexChar {
	return
		hexChar >= 'A' && hexChar <= 'F' ? (hexChar - 'A' + 10) :
		hexChar >= 'a' && hexChar <= 'f' ? (hexChar - 'a' + 10) :
		(hexChar - '0');
}


+ (NSString *)rrggbbStringForColor:(UIColor *)color includeAlpha:(BOOL)includeAlpha {
	if (color == nil) {
		return nil;
	}

	NSData *data;
	CGFloat r, g, b, a;
	[self componentsOfColor:color r:&r g:&g b:&b a:&a];

	if (includeAlpha) {
		uint8_t bytes[] = {
			round(r * 255.0),
			round(g * 255.0),
			round(b * 255.0),
			round(a * 255.0)
		};

		data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
	}
	else {
		uint8_t bytes[] = {
			round(r * 255.0),
			round(g * 255.0),
			round(b * 255.0)
		};

		data = [NSData dataWithBytes:bytes length:sizeof(bytes)];
	}

	return [AKHex stringFromData:data];
}


@end
