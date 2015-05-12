//
//  AKDisplayLink.m
//  AgilKit
//
//  Created by Shane Meyer on 4/25/15.
//  Copyright (c) 2015 Agilstream, LLC. All rights reserved.
//

#import "AKDisplayLink.h"

//
// AKDisplayLinkPrivate
//

@class AKDisplayLinkPrivate;

@protocol AKDisplayLinkPrivateDelegate <NSObject>

- (void)displayLinkPrivateDidFire:(AKDisplayLinkPrivate *)displayLinkPrivate;

@end

@interface AKDisplayLinkPrivate : NSObject {
	@private __weak id <AKDisplayLinkPrivateDelegate> m_delegate;
	@private CADisplayLink *m_displayLink;
}

@property (nonatomic, readonly) CADisplayLink *displayLink;

@end

@implementation AKDisplayLinkPrivate

@synthesize displayLink = m_displayLink;

- (instancetype)
	initWithDelegate:(id <AKDisplayLinkPrivateDelegate>)delegate
	frameInterval:(NSInteger)frameInterval
	commonModes:(BOOL)commonModes
{
	if (self = [super init]) {
		m_delegate = delegate;
		m_displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(onTimer)];
		m_displayLink.frameInterval = frameInterval;
		[m_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:commonModes ?
			NSRunLoopCommonModes : NSDefaultRunLoopMode];
	}

	return self;
}

- (void)invalidate {
	m_delegate = nil;
	[m_displayLink invalidate];
	m_displayLink = nil;
}

- (void)onTimer {
	[m_delegate displayLinkPrivateDidFire:self];
}

@end

//
// AKDisplayLink
//

@interface AKDisplayLink () <AKDisplayLinkPrivateDelegate> {
	@private __weak id <AKDisplayLinkDelegate> m_delegate;
	@private BOOL m_didFire;
	@private AKDisplayLinkPrivate *m_displayLinkPrivate;
	@private CFTimeInterval m_originalTimestamp;
}

@end

@implementation AKDisplayLink

- (void)dealloc {
	m_delegate = nil;
	[m_displayLinkPrivate invalidate];
	m_displayLinkPrivate = nil;
}

- (void)displayLinkPrivateDidFire:(AKDisplayLinkPrivate *)displayLinkPrivate {
	if (!m_didFire) {
		m_didFire = YES;
		m_originalTimestamp = displayLinkPrivate.displayLink.timestamp;
	}
	[m_delegate displayLinkDidFire:self];
}

- (CFTimeInterval)duration {
	return m_displayLinkPrivate.displayLink.duration;
}

- (instancetype)
	initWithDelegate:(id <AKDisplayLinkDelegate>)delegate
	frameInterval:(NSInteger)frameInterval
	commonModes:(BOOL)commonModes
{
	if (self = [super init]) {
		m_delegate = delegate;
		m_displayLinkPrivate = [[AKDisplayLinkPrivate alloc] initWithDelegate:self
			frameInterval:frameInterval commonModes:commonModes];
	}

	return self;
}

- (BOOL)paused {
	return m_displayLinkPrivate.displayLink.paused;
}

- (void)setPaused:(BOOL)paused {
	m_displayLinkPrivate.displayLink.paused = paused;
}

- (CFTimeInterval)timestamp {
	return m_didFire ? (m_displayLinkPrivate.displayLink.timestamp - m_originalTimestamp) : 0.0;
}

@end
