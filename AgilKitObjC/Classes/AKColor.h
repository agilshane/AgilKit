//
//  AKColor.h
//  AgilKit
//
//  Created by Shane Meyer on 3/29/13.
//  Copyright (c) 2013-2015 Agilstream, LLC.
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

@interface AKColor : NSObject

// Creates a color from an RRGGBB or RRGGBBAA hex string.
+ (UIColor *)colorWithRRGGBB:(NSString *)rrggbb;

// Returns the RGBA components of the given color.
+ (void)
	componentsOfColor:(UIColor *)color
	r:(CGFloat *)r
	g:(CGFloat *)g
	b:(CGFloat *)b
	a:(CGFloat *)a;

// Returns an RRGGBB or RRGGBBAA hex string representation of the given color.
+ (NSString *)rrggbbStringForColor:(UIColor *)color includeAlpha:(BOOL)includeAlpha;

@end
