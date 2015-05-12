//
//  AKDisplayLink.h
//  AgilKit
//
//  Created by Shane Meyer on 4/25/15.
//  Copyright (c) 2015 Agilstream, LLC. All rights reserved.
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
//  -------------------------------------------------------------------------------------------
//
//  The purpose of this class is simply to avoid the need to invalidate. CADisplayLink retains
//  its delegate, requiring someone to invalidate it in order for its delegate to be released.
//  Often that burden is placed on someone higher up the call chain, which isn't good
//  encapsulation and can easily be forgotten, leading to leaks.
//

#import <Foundation/Foundation.h>

@class AKDisplayLink;

@protocol AKDisplayLinkDelegate <NSObject>

- (void)displayLinkDidFire:(AKDisplayLink *)displayLink;

@end

@interface AKDisplayLink : NSObject

@property (nonatomic, readonly) CFTimeInterval duration;
@property (nonatomic, assign) BOOL paused;
@property (nonatomic, readonly) CFTimeInterval timestamp;

- (instancetype)
	initWithDelegate:(id <AKDisplayLinkDelegate>)delegate
	frameInterval:(NSInteger)frameInterval
	commonModes:(BOOL)commonModes;

@end
