//
//  AKBase64.m
//  AgilKit
//
//  Created by Shane Meyer on 4/4/13.
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

#import "AKBase64.h"


@implementation AKBase64


+ (NSData *)dataFromString:(NSString *)string {
	if (string == nil) {
		return nil;
	}

	if ([NSData instancesRespondToSelector:@selector(initWithBase64EncodedString:options:)]) {
		return [[NSData alloc] initWithBase64EncodedString:string
			options:NSDataBase64DecodingIgnoreUnknownCharacters];
	}

	// Use property list serialization to do the base64 work for us.

	NSMutableString *ms = [[NSMutableString alloc] initWithCapacity:string.length + 40];
	[ms appendString:@"<dict><key>a</key><data>"];
	[ms appendString:string];
	[ms appendString:@"</data></dict>"];

	NSError *error = nil;

	NSDictionary *dict = [NSPropertyListSerialization
		propertyListWithData:[ms dataUsingEncoding:NSUTF8StringEncoding]
		options:NSPropertyListImmutable
		format:NULL
		error:&error];

	return (dict == nil ? nil : [dict objectForKey:@"a"]);
}


+ (NSString *)stringFromData:(NSData *)data {
	if (data == nil) {
		return nil;
	}

	if ([data respondsToSelector:@selector(base64EncodedStringWithOptions:)]) {
		return [data base64EncodedStringWithOptions:0];
	}

	// Use property list serialization to do the base64 work for us.

	NSError *error = nil;

	NSData *xmlData = [NSPropertyListSerialization
		dataWithPropertyList:@{ @"a" : data }
		format:NSPropertyListXMLFormat_v1_0
		options:0
		error:&error];

	if (xmlData == nil) {
		return nil;
	}

	NSString *xml = [[NSString alloc] initWithData:xmlData encoding:NSUTF8StringEncoding];
	NSRange range0 = [xml rangeOfString:@"<data>"];
	NSRange range1 = [xml rangeOfString:@"</data>" options:NSBackwardsSearch];

	if (range0.location == NSNotFound || range1.location == NSNotFound) {
		return nil;
	}

	NSUInteger start = NSMaxRange(range0);
	NSMutableData *md = [NSMutableData dataWithCapacity:range1.location - start];

	for (NSUInteger i = start; i < range1.location; i++) {
		unichar ch = [xml characterAtIndex:i];

		if (ch != ' ' && ch != '\n' && ch != '\r' && ch != '\t') {
			[md appendBytes:&ch length:1];
		}
	}

	return [[NSString alloc] initWithData:md encoding:NSUTF8StringEncoding];
}


@end
