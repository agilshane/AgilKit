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


static BOOL m_modern = NO;


@interface AKKeyboard () {
	@private __weak id <AKKeyboardDelegate> m_delegate;
	@private CGFloat m_height;
}

@end


@implementation AKKeyboard


@synthesize height = m_height;


- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
}


+ (CGRect)fullScreenFrameOfView:(UIView *)view orientation:(UIInterfaceOrientation)orientation {
	if (view == nil || view.window == nil) {
		return CGRectZero;
	}

	CGRect frame = [view convertRect:view.bounds toView:nil];
	CGSize windowSize = view.window.bounds.size;

	if (orientation == UIInterfaceOrientationPortrait || m_modern) {
		// The easy case.
	}
	else if (orientation == UIInterfaceOrientationPortraitUpsideDown) {
		frame = CGRectMake(
			windowSize.width - CGRectGetMaxX(frame),
			windowSize.height - CGRectGetMaxY(frame),
			frame.size.width,
			frame.size.height);
	}
	else if (orientation == UIInterfaceOrientationLandscapeLeft) {
		frame = CGRectMake(
			windowSize.height - CGRectGetMaxY(frame),
			frame.origin.x,
			frame.size.height,
			frame.size.width);
	}
	else if (orientation == UIInterfaceOrientationLandscapeRight) {
		frame = CGRectMake(
			frame.origin.y,
			windowSize.width - CGRectGetMaxX(frame),
			frame.size.height,
			frame.size.width);
	}
	else {
		NSLog(@"The orientation is unrecognized!");
	}

	return frame;
}


- (CGFloat)heightOfView:(UIView *)view orientation:(UIInterfaceOrientation)orientation {
	if (view == nil || view.window == nil) {
		return 0;
	}

	CGFloat windowHeight = m_modern || UIInterfaceOrientationIsPortrait(orientation) ?
		view.window.bounds.size.height : view.window.bounds.size.width;
	CGFloat keyboardOrigin = windowHeight - m_height;
	CGRect frame = [AKKeyboard fullScreenFrameOfView:view orientation:orientation];
	CGFloat height = frame.size.height - (CGRectGetMaxY(frame) - keyboardOrigin);
	return MIN(height, frame.size.height);
}


+ (void)initialize {
	m_modern = [UIScreen instancesRespondToSelector:@selector(fixedCoordinateSpace)];
}


- (instancetype)initWithDelegate:(id <AKKeyboardDelegate>)delegate {
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


- (void)
	updateBottomInsetsOfScrollView:(UIScrollView *)scrollView
	orientation:(UIInterfaceOrientation)orientation
{
	if (scrollView == nil || scrollView.window == nil) {
		return;
	}

	CGFloat bottom = 0;

	if (m_height > 0.0) {
		CGRect rect = [AKKeyboard fullScreenFrameOfView:scrollView orientation:orientation];
		CGFloat windowHeight = m_modern || UIInterfaceOrientationIsPortrait(orientation) ?
			scrollView.window.bounds.size.height : scrollView.window.bounds.size.width;
		bottom = CGRectGetMaxY(rect) - windowHeight + m_height;
	}

	UIEdgeInsets contentInset = scrollView.contentInset;
	UIEdgeInsets scrollIndicatorInsets = scrollView.scrollIndicatorInsets;

	contentInset.bottom = bottom;
	scrollIndicatorInsets.bottom = bottom;

	scrollView.contentInset = contentInset;
	scrollView.scrollIndicatorInsets = scrollIndicatorInsets;
}


@end
