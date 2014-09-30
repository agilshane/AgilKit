//
//  AKMultipartFormData.m
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

#import "AKMultipartFormData.h"


@interface AKMultipartFormData () {
	@private NSString *m_boundary;
	@private NSMutableData *m_data;
	@private BOOL m_frozen;
}

- (void)beginDataIfNeeded;

@end


@implementation AKMultipartFormData


@synthesize boundary = m_boundary;


- (void)
	appendName:(NSString *)name
	fileData:(NSData *)fileData
	fileName:(NSString *)fileName
	fileType:(NSString *)fileType
{
	if (m_frozen) {
		NSLog(@"Cannot append form data because it's frozen!");
		return;
	}

	[self beginDataIfNeeded];
	NSString *s = [NSString stringWithFormat:@"\r\n--%@\r\n", m_boundary];
	[m_data appendData:[s dataUsingEncoding:NSUTF8StringEncoding]];
	s = [NSString stringWithFormat:
		@"Content-Disposition: form-data; name=\"%@\"; filename=\"%@\"\r\n",
		name, fileName];
	[m_data appendData:[s dataUsingEncoding:NSUTF8StringEncoding]];
	s = [NSString stringWithFormat:@"Content-Type: %@\r\n\r\n", fileType];
	[m_data appendData:[s dataUsingEncoding:NSUTF8StringEncoding]];
	[m_data appendData:fileData];
}


- (void)appendName:(NSString *)name stringValue:(NSString *)stringValue {
	if (m_frozen) {
		NSLog(@"Cannot append form data because it's frozen!");
		return;
	}

	[self beginDataIfNeeded];
	NSString *s = [NSString stringWithFormat:@"\r\n--%@\r\n", m_boundary];
	[m_data appendData:[s dataUsingEncoding:NSUTF8StringEncoding]];
	s = [NSString stringWithFormat:
		@"Content-Disposition: form-data; name=\"%@\"\r\n\r\n",
		name];
	[m_data appendData:[s dataUsingEncoding:NSUTF8StringEncoding]];
	[m_data appendData:[stringValue dataUsingEncoding:NSUTF8StringEncoding]];
}


- (void)beginDataIfNeeded {
	if (m_data == nil) {
		m_data = [[NSMutableData alloc] init];
	}
}


- (NSData *)data {
	if (!m_frozen) {
		[self beginDataIfNeeded];
		NSString *s = [NSString stringWithFormat:@"\r\n--%@--\r\n", m_boundary];
		[m_data appendData:[s dataUsingEncoding:NSUTF8StringEncoding]];
		m_frozen = YES;
	}

	return m_data;
}


- (instancetype)init {
	if (self = [super init]) {
		m_boundary = [NSString stringWithFormat:@"---------------------------%X%X",
			arc4random(), arc4random()];
	}

	return self;
}


@end
