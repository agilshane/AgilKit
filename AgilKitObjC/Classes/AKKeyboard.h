//
//  AKKeyboard.h
//  AgilKit
//
//  Created by Shane Meyer on 3/28/13.
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

#import <Foundation/Foundation.h>

@class AKKeyboard;

@protocol AKKeyboardDelegate <NSObject>

- (void)keyboard:(AKKeyboard *)keyboard heightDidChangeWithDuration:(NSTimeInterval)duration;

@end

@interface AKKeyboard : NSObject

// The current height of the keyboard.  The value is 0.0 if hidden.
@property (nonatomic, readonly) CGFloat height;

// Translates the given view's frame to window coordinates, taking into account the orientation.
+ (CGRect)fullScreenFrameOfView:(UIView *)view orientation:(UIInterfaceOrientation)orientation;

// Returns how high the given view should be in order to make room for the keyboard below it.
// If the current keyboard height is 0.0, the view's height is returned.
- (CGFloat)heightOfView:(UIView *)view orientation:(UIInterfaceOrientation)orientation;

- (instancetype)initWithDelegate:(id <AKKeyboardDelegate>)delegate;

// Updates the given scroll view's bottom insets based on the current state of the keyboard.
- (void)
	updateBottomInsetsOfScrollView:(UIScrollView *)scrollView
	orientation:(UIInterfaceOrientation)orientation;

@end
