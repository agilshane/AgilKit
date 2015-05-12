//
//  AKHex.m
//  AgilKit
//
//  Created by Shane Meyer on 3/27/13.
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

#import "AKHex.h"


@implementation AKHex


+ (NSData *)dataFromString:(NSString *)s {
	if (s == nil || s.length % 2 != 0) {
		return nil;
	}

	NSMutableData *data = [NSMutableData dataWithCapacity:s.length / 2];

	for (int i = 0; i < s.length; i += 2) {
		unichar c0 = [s characterAtIndex:i + 0];
		unichar c1 = [s characterAtIndex:i + 1];

		if (c0 >= '0' && c0 <= '9') {
			c0 -= '0';
		}
		else if (c0 >= 'A' && c0 <= 'F') {
			c0 -= 'A';
			c0 += 10;
		}
		else if (c0 >= 'a' && c0 <= 'f') {
			c0 -= 'a';
			c0 += 10;
		}
		else {
			return nil;
		}

		c0 <<= 4;

		if (c1 >= '0' && c1 <= '9') {
			c1 -= '0';
		}
		else if (c1 >= 'A' && c1 <= 'F') {
			c1 -= 'A';
			c1 += 10;
		}
		else if (c1 >= 'a' && c1 <= 'f') {
			c1 -= 'a';
			c1 += 10;
		}
		else {
			return nil;
		}

		UInt8 byte = ((UInt8)c0) + ((UInt8)c1);
		[data appendBytes:&byte length:1];
	}

	return data;
}


+ (NSString *)stringFromData:(NSData *)data {
	if (data == nil) {
		return nil;
	}

	UInt8 *bytes = (UInt8 *)data.bytes;
	NSMutableString *ms = [NSMutableString stringWithCapacity:data.length * 2];

	for (int i = 0; i < data.length; i++) {
		unichar chars[] = { bytes[i] >> 4, bytes[i] & 0xF };
		chars[0] += (chars[0] < 10 ? '0' : ('A' - 10));
		chars[1] += (chars[1] < 10 ? '0' : ('A' - 10));
		[ms appendString:[NSString stringWithCharacters:chars length:2]];
	}

	return ms;
}


@end
