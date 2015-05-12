//
//  AgilKitObjCTests.m
//  AgilKitObjCTests
//
//  Created by Shane Meyer on 12/5/14.
//  Copyright (c) 2014-2015 Agilstream, LLC. All rights reserved.
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

#import <UIKit/UIKit.h>
#import <XCTest/XCTest.h>
#import "AKHex.h"

@interface AgilKitObjCTests : XCTestCase

@end

@implementation AgilKitObjCTests

- (void)testHex {
	NSUInteger count = 199;
	NSMutableData *data0 = [[NSMutableData alloc] initWithCapacity:count];

	for (NSUInteger i = 0; i < count; i++) {
		UInt8 byte = arc4random() % 256;
		[data0 appendBytes:&byte length:1];
	}

	NSString *hex0 = [AKHex stringFromData:data0];
	NSData *data1 = [AKHex dataFromString:hex0];
	NSString *hex1 = [AKHex stringFromData:data1];

	XCTAssertTrue([data0 isEqualToData:data1]);
	XCTAssertTrue([hex0 isEqualToString:hex1]);
}

@end
