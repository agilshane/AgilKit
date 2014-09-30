//
//  AKQueryString.m
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

#import "AKQueryString.h"
#import "AKStringEscape.h"


@interface AKQueryString () {
	@private NSMutableString *m_string;
}

@end


@implementation AKQueryString


@synthesize string = m_string;


- (void)appendKey:(NSString *)key value:(NSString *)value {
	if (m_string.length > 0) {
		[m_string appendString:@"&"];
	}

	[m_string appendString:[AKStringEscape percentEscape:key]];
	[m_string appendString:@"="];
	[m_string appendString:[AKStringEscape percentEscape:value]];
}


- (instancetype)init {
	if (self = [super init]) {
		m_string = [[NSMutableString alloc] init];
	}

	return self;
}


+ (NSString *)stringFromKeyValuePairs:(NSDictionary *)keyValuePairs {
	NSMutableString *ms = [NSMutableString stringWithCapacity:64];

	if (keyValuePairs != nil) {
		[keyValuePairs enumerateKeysAndObjectsUsingBlock:
			^(NSString *key, NSString *value, BOOL *stop) {
				if (ms.length > 0) {
					[ms appendString:@"&"];
				}

				[ms appendString:[AKStringEscape percentEscape:key]];
				[ms appendString:@"="];
				[ms appendString:[AKStringEscape percentEscape:value]];
			}
		];
	}

	return ms;
}


@end
