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


@interface AKWindowView () {
	@private UIView *m_contentView;
	@private BOOL m_didFinishLaunching;
	@private BOOL m_orientationLocked;
}

- (void)layoutWithOrientation:(UIInterfaceOrientation)orientation;

@end


@implementation AKWindowView


@synthesize contentView = m_contentView;
@synthesize orientationLocked = m_orientationLocked;


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


- (id)initWithContentView:(UIView *)contentView {
	if (contentView == nil) {
		return nil;
	}

	BOOL oldSDK = ![UIScreen instancesRespondToSelector:@selector(fixedCoordinateSpace)];
	CGRect bounds = oldSDK ? CGRectZero : [UIScreen mainScreen].bounds;
	UIApplication *app = [UIApplication sharedApplication];

	if (self = [super initWithFrame:bounds]) {
		m_didFinishLaunching = (app.applicationState == UIApplicationStateActive);
		m_contentView = contentView;
		[self addSubview:contentView];

		if (oldSDK) {
			[self layoutWithOrientation:app.statusBarOrientation];

			NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

			[nc addObserver:self selector:@selector(onDidFinishLaunching:)
				name:UIApplicationDidFinishLaunchingNotification object:nil];

			[nc addObserver:self selector:@selector(onWillChangeStatusBarOrientation:)
				name:UIApplicationWillChangeStatusBarOrientationNotification object:nil];
		}
		else {

			// iOS 8 makes our job much easier.

			contentView.frame = bounds;

			self.autoresizingMask =
				UIViewAutoresizingFlexibleWidth |
				UIViewAutoresizingFlexibleHeight;

			contentView.autoresizingMask =
				UIViewAutoresizingFlexibleWidth |
				UIViewAutoresizingFlexibleHeight;
		}
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
	dispatch_async(dispatch_get_main_queue(), ^{
		// Let one run loop go by before declaring that we've finished launching.  Otherwise the
		// animations will be wrong.
		m_didFinishLaunching = YES;
	});
}


- (void)onWillChangeStatusBarOrientation:(NSNotification *)notification {
	if (m_orientationLocked) {
		return;
	}

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
