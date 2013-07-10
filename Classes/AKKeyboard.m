//
//  AKKeyboard.m
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

#import "AKKeyboard.h"


@implementation AKKeyboard


@synthesize height = m_height;


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];

	#if !__has_feature(objc_arc)
		[super dealloc];
	#endif
}


- (CGFloat)heightOfView:(UIView *)view orientation:(UIInterfaceOrientation)orientation {
	if (view == nil) {
		return 0;
	}

	if (m_height == 0.0) {
		return view.bounds.size.height;
	}

	CGFloat f = 0;
	CGRect r = [view convertRect:view.frame toView:nil];

	if ([view isKindOfClass:[UIScrollView class]]) {
		UIScrollView *scroll = (UIScrollView *)view;
		r = CGRectOffset(r, scroll.contentOffset.x, scroll.contentOffset.y);
	}

	UIWindow *w = view.window;

	if (orientation == UIInterfaceOrientationPortrait) {
		f = CGRectGetMaxY(r) - (w.frame.size.height - m_height);
		return r.size.height - f;
	}

	if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		f = (w.frame.size.height - r.origin.y) - (w.frame.size.height - m_height);
		return r.size.height - f;
	}

	if (orientation == UIInterfaceOrientationLandscapeLeft) {
		f = CGRectGetMaxX(r) - (w.frame.size.width - m_height);
		return r.size.width - f;
	}

	if (orientation == UIInterfaceOrientationLandscapeRight) {
		return CGRectGetMaxX(r) - m_height;
	}

	NSLog(@"The orientation is unrecognized!");
	return 0;
}


- (id)initWithDelegate:(id <AKKeyboardDelegate>)delegate {
	if (self = [super init]) {
		m_delegate = delegate;
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

		[nc addObserver:self selector:@selector(onKeyboardWillHide:)
			name:UIKeyboardWillHideNotification object:nil];

		[nc addObserver:self selector:@selector(onKeyboardWillShow:)
			name:UIKeyboardWillShowNotification object:nil];
	}

	return self;
}


- (void)onKeyboardWillHide:(NSNotification *)notification {
	m_height = 0;
	NSNumber *n = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	[m_delegate keyboard:self heightDidChangeWithDuration:n.doubleValue];
}


- (void)onKeyboardWillShow:(NSNotification *)notification {
	NSValue *v = [notification.userInfo objectForKey:UIKeyboardFrameEndUserInfoKey];
	CGSize size = v.CGRectValue.size;

	if (size.width > size.height) {
		// Portrait.
		m_height = size.height;
	}
	else {
		// Landscape, which is funky because the keyboard basically stands on its side.
		m_height = size.width;
	}

	NSNumber *n = [notification.userInfo objectForKey:UIKeyboardAnimationDurationUserInfoKey];
	[m_delegate keyboard:self heightDidChangeWithDuration:n.doubleValue];
}


@end
