//
//  AKTimer.m
//  AgilKit
//
//  Created by Shane Meyer on 5/10/13.
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

#import "AKTimer.h"


//
// AKTimerPrivate
//


@class AKTimerPrivate;

@protocol AKTimerPrivateDelegate <NSObject>

- (void)timerPrivateDidFire:(AKTimerPrivate *)timerPrivate;

@end

@interface AKTimerPrivate : NSObject {
	@private __weak id <AKTimerPrivateDelegate> m_delegate;
	@private NSTimer *m_timer;
}

- (instancetype)
	initWithDelegate:(id <AKTimerPrivateDelegate>)delegate
	timeInterval:(NSTimeInterval)timeInterval
	commonModes:(BOOL)commonModes;

- (void)invalidate;

@end


@implementation AKTimerPrivate


- (instancetype)
	initWithDelegate:(id <AKTimerPrivateDelegate>)delegate
	timeInterval:(NSTimeInterval)timeInterval
	commonModes:(BOOL)commonModes
{
	if (self = [super init]) {
		m_delegate = delegate;
		m_timer = [NSTimer
			timerWithTimeInterval:timeInterval
			target:self
			selector:@selector(onTimer:)
			userInfo:nil
			repeats:YES];

		[[NSRunLoop currentRunLoop] addTimer:m_timer forMode:commonModes ?
			NSRunLoopCommonModes : NSDefaultRunLoopMode];
	}

	return self;
}


- (void)invalidate {
	m_delegate = nil;
	[m_timer invalidate];
	m_timer = nil;
}


- (void)onTimer:(NSTimer *)timer {
	[m_delegate timerPrivateDidFire:self];
}


@end


//
// AKTimer
//


@interface AKTimer () <AKTimerPrivateDelegate> {
	@private __weak id <AKTimerDelegate> m_delegate;
	@private AKTimerPrivate *m_timerPrivate;
}

@end


@implementation AKTimer


- (void)dealloc {
	m_delegate = nil;
	[m_timerPrivate invalidate];
	m_timerPrivate = nil;
}


- (instancetype)
	initWithDelegate:(id <AKTimerDelegate>)delegate
	timeInterval:(NSTimeInterval)timeInterval
{
	return [self initWithDelegate:delegate timeInterval:timeInterval commonModes:NO];
}


- (instancetype)
	initWithDelegate:(id <AKTimerDelegate>)delegate
	timeInterval:(NSTimeInterval)timeInterval
	commonModes:(BOOL)commonModes
{
	if (self = [super init]) {
		m_delegate = delegate;
		m_timerPrivate = [[AKTimerPrivate alloc]
			initWithDelegate:self
			timeInterval:timeInterval
			commonModes:commonModes];
	}

	return self;
}


- (void)timerPrivateDidFire:(AKTimerPrivate *)timerPrivate {
	[m_delegate timerDidFire:self];
}


@end
