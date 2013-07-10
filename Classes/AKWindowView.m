//
//  AKWindowView.m
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

#import "AKWindowView.h"


@interface AKWindowView ()

- (void)layoutWithOrientation:(UIInterfaceOrientation)orientation;

@end


@implementation AKWindowView


@synthesize contentView = m_contentView;


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	#if !__has_feature(objc_arc)
		[super dealloc];
	#endif
}


- (id)initWithContentView:(UIView *)contentView {
	UIApplication *app = [UIApplication sharedApplication];
	m_didFinishLaunching = (app.applicationState == UIApplicationStateActive);

	if (contentView == nil) {
		#if !__has_feature(objc_arc)
			[self release];
		#endif

		return nil;
	}

	if (self = [super initWithFrame:CGRectZero]) {
		m_contentView = contentView;
		[self addSubview:contentView];
		[self layoutWithOrientation:app.statusBarOrientation];

		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

		[nc addObserver:self selector:@selector(onDidFinishLaunching:)
			name:UIApplicationDidFinishLaunchingNotification object:nil];

		[nc addObserver:self selector:@selector(onWillChangeStatusBarOrientation:)
			name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
	}

	return self;
}


- (void)layoutWithOrientation:(UIInterfaceOrientation)orientation {
	CGRect bounds = [UIScreen mainScreen].bounds;
	CGSize size = bounds.size;

	if (UIInterfaceOrientationIsLandscape(orientation)) {
		bounds = CGRectMake(0, 0, size.height, size.width);
	}
	else {
		bounds = CGRectMake(0, 0, size.width, size.height);
	}

	self.bounds = bounds;
	m_contentView.frame = bounds;

	CGFloat angle = 0;

	if (orientation == UIInterfaceOrientationLandscapeLeft) {
		angle = -M_PI_2;
	}
	else if (orientation == UIInterfaceOrientationLandscapeRight) {
		angle = M_PI_2;
	}
	else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		angle = M_PI;
	}

	CGAffineTransform t = CGAffineTransformMakeTranslation(0.5 * size.width, 0.5 * size.height);
	t = CGAffineTransformRotate(t, angle);
	self.transform = t;
}


- (void)onDidFinishLaunching:(NSNotification *)notification {
	[self performSelector:@selector(onDidFinishLaunching2) withObject:nil afterDelay:0];
}


- (void)onDidFinishLaunching2 {
	// Let one run loop go by before declaring that we've finished launching.  Otherwise the
	// animations will be wrong.
	m_didFinishLaunching = YES;
}


- (void)onWillChangeStatusBarOrientation:(NSNotification *)notification {
	UIApplication *app = [UIApplication sharedApplication];
	NSNumber *number = [notification.userInfo objectForKey:
		UIApplicationStatusBarOrientationUserInfoKey];
	UIInterfaceOrientation orientation0 = app.statusBarOrientation;
	UIInterfaceOrientation orientation1 = number.intValue;
	NSTimeInterval dur = app.statusBarOrientationAnimationDuration;

	if (orientation0 == orientation1) {
		return;
	}

	// Double the animation duration if rotating 180 degrees.

	if (orientation0 == UIInterfaceOrientationLandscapeLeft) {
		if (orientation1 == UIInterfaceOrientationLandscapeRight) {
			dur *= 2.0;
		}
	}
	else if (orientation0 == UIInterfaceOrientationLandscapeRight) {
		if (orientation1 == UIInterfaceOrientationLandscapeLeft) {
			dur *= 2.0;
		}
	}
	else if (orientation0 == UIInterfaceOrientationPortrait) {
		if (orientation1 == UIInterfaceOrientationPortraitUpsideDown) {
			dur *= 2.0;
		}
	}
	else if (orientation0 == UIInterfaceOrientationPortraitUpsideDown) {
		if (orientation1 == UIInterfaceOrientationPortrait) {
			dur *= 2.0;
		}
	}

	if (m_didFinishLaunching) {
		[UIView animateWithDuration:dur animations:^{
			[self layoutWithOrientation:orientation1];
		}];
	}
	else {
		// Avoid the animation if the app hasn't finished launching.
		[self layoutWithOrientation:orientation1];
	}
}


@end
