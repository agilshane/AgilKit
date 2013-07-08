//
//  AKLocStr.m
//  AgilKit
//
//  Created by Shane Meyer on 3/27/13.
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

#import "AKLocStr.h"


NSString *AKLocStr(NSString *key, ...) {
	if (key == nil) {
		NSLog(@"Got a nil key!");
	}
	else {
		NSString *s = [[NSBundle mainBundle] localizedStringForKey:key value:nil table:nil];

		if (s == nil) {
			NSLog(@"Key '%@' has a nil value!", key);
		}
		else if ([s isEqualToString:key]) {
			NSLog(@"Key '%@' not found!", key);
		}
		else {
			va_list list;
			va_start(list, key);
			s = [[[NSString alloc] initWithFormat:s arguments:list] autorelease];
			va_end(list);
			return s;
		}
	}

	return @"NOT FOUND";
}


NSError *AKLocStrError(NSString *key, ...) {
	NSString *locStr = @"NOT FOUND";

	if (key == nil) {
		NSLog(@"Got a nil key!");
	}
	else {
		NSString *s = [[NSBundle mainBundle] localizedStringForKey:key value:nil table:nil];

		if (s == nil) {
			NSLog(@"Key '%@' has a nil value!", key);
		}
		else if ([s isEqualToString:key]) {
			NSLog(@"Key '%@' not found!", key);
		}
		else {
			va_list list;
			va_start(list, key);
			s = [[[NSString alloc] initWithFormat:s arguments:list] autorelease];
			va_end(list);
			locStr = s;
		}
	}

	NSDictionary *userInfo = @{ NSLocalizedDescriptionKey : locStr };
	return [NSError errorWithDomain:@"AKLocStrErrorDomain" code:0 userInfo:userInfo];
}
