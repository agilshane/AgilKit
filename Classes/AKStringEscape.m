//
//  AKStringEscape.m
//  AgilKit
//
//  Created by Shane Meyer on 3/28/13.
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

#import "AKStringEscape.h"


@implementation AKStringEscape


+ (NSString *)percentEscape:(NSString *)s {
	if (s != nil) {
		s = (NSString *)CFURLCreateStringByAddingPercentEscapes(
			NULL,
			(CFStringRef)s,
			NULL,
			(CFStringRef)@"!*'\"();:@&=+$,/?%#[]",
			kCFStringEncodingUTF8);
		[s autorelease];
	}

	return s;
}


+ (NSString *)xmlEscape:(NSString *)s {
	if (s != nil) {
		@autoreleasepool {
			s = [s stringByReplacingOccurrencesOfString:@"&"  withString:@"&amp;"];
			s = [s stringByReplacingOccurrencesOfString:@"<"  withString:@"&lt;"];
			s = [s stringByReplacingOccurrencesOfString:@">"  withString:@"&gt;"];
			s = [s stringByReplacingOccurrencesOfString:@"'"  withString:@"&apos;"];
			s = [s stringByReplacingOccurrencesOfString:@"\"" withString:@"&quot;"];
			s = [s retain];
		}

		[s autorelease];
	}

	return s;
}


@end
