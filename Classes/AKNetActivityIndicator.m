//
//  AKNetActivityIndicator.m
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

#import "AKNetActivityIndicator.h"


static int m_count = 0;


@implementation AKNetActivityIndicator


+ (void)hide {
	m_count--;

	if (m_count < 0) {
		NSLog(@"AKNetActivityIndicator has been hidden too many times!");
		m_count = 0;
	}

	if (m_count == 0) {
		[UIApplication sharedApplication].networkActivityIndicatorVisible = NO;
	}
}


+ (void)show {
	m_count++;
	[UIApplication sharedApplication].networkActivityIndicatorVisible = YES;
}


@end
