//
//  AGKWindowView.swift
//  AgilKit
//
//  Created by Shane Meyer on 6/17/15.
//  Copyright © 2015-2016 Agilstream, LLC. All rights reserved.
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

import UIKit

class AGKWindowView: UIView {

	let contentView: UIView
	private var didFinishLaunching: Bool

	private static let oldSDK: Bool = {
		if #available(iOS 8, *) {
			return false
		}
		return true
	}()

	init(contentView: UIView) {
		self.contentView = contentView
		let app = UIApplication.sharedApplication()
		didFinishLaunching = (app.applicationState == .Active)
		let rect = AGKWindowView.oldSDK ? CGRectZero : UIScreen.mainScreen().bounds
		super.init(frame: rect)
		addSubview(contentView)

		if AGKWindowView.oldSDK {
			layoutWithOrientation(app.statusBarOrientation)
			let nc = NSNotificationCenter.defaultCenter()
			nc.addObserver(self, selector: #selector(onDidFinishLaunching(_:)),
				name: UIApplicationDidFinishLaunchingNotification, object: nil)
			nc.addObserver(self, selector: #selector(onWillChangeStatusBarOrientation(_:)),
				name: UIApplicationWillChangeStatusBarOrientationNotification, object: nil)
		}
		else {
			contentView.frame = rect
			autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
			contentView.autoresizingMask = [.FlexibleWidth, .FlexibleHeight]
		}
	}

	required init(coder aDecoder: NSCoder) {
		fatalError("init(coder:) has not been implemented")
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	override func hitTest(point: CGPoint, withEvent event: UIEvent?) -> UIView? {
		return contentView.hitTest(point, withEvent: event)
	}

	override func layoutSubviews() {
		if !AGKWindowView.oldSDK {
			if let v = superview {
				// Setting our frame shouldn't be necessary, but if we are a subview of an iOS 9.0
				// split screen window, the window doesn't properly honor the autoresizingMask when
				// the window size changes.
				frame = v.bounds
				contentView.frame = v.bounds
			}
		}
	}

	private func layoutWithOrientation(orientation: UIInterfaceOrientation) {
		var rect = UIScreen.mainScreen().bounds
		let size = rect.size

		if UIInterfaceOrientationIsLandscape(orientation) {
			rect = CGRectMake(0, 0, size.height, size.width)
		}
		else {
			rect = CGRectMake(0, 0, size.width, size.height)
		}

		bounds = rect
		contentView.frame = rect
		var angle = CGFloat(0)

		if orientation == .LandscapeLeft {
			angle = CGFloat(-M_PI_2)
		}
		else if orientation == .LandscapeRight {
			angle = CGFloat(M_PI_2)
		}
		else if orientation == .PortraitUpsideDown {
			angle = CGFloat(M_PI)
		}

		let t = CGAffineTransformMakeTranslation(0.5 * size.width, 0.5 * size.height)
		transform = CGAffineTransformRotate(t, angle)
	}

	func onDidFinishLaunching(notification: NSNotification) {
		dispatch_async(dispatch_get_main_queue()) {
			// Let one run loop go by before declaring that we've finished launching. Otherwise the
			// animations will be wrong.
			self.didFinishLaunching = true
		}
	}

	func onWillChangeStatusBarOrientation(notification: NSNotification) {
		if let userInfo = notification.userInfo {
			if let number = userInfo[UIApplicationStatusBarOrientationUserInfoKey] as? NSNumber {
				let app = UIApplication.sharedApplication()
				let orientation0 = app.statusBarOrientation
				let orientation1 = UIInterfaceOrientation(rawValue: number.integerValue)!

				if orientation0 != orientation1 {
					var dur = app.statusBarOrientationAnimationDuration

					// Double the animation duration if rotating 180 degrees.

					if orientation0 == .LandscapeLeft {
						if orientation1 == .LandscapeRight {
							dur *= NSTimeInterval(2)
						}
					}
					else if orientation0 == .LandscapeRight {
						if orientation1 == .LandscapeLeft {
							dur *= NSTimeInterval(2)
						}
					}
					else if orientation0 == .Portrait {
						if orientation1 == .PortraitUpsideDown {
							dur *= NSTimeInterval(2)
						}
					}
					else if orientation0 == .PortraitUpsideDown {
						if orientation1 == .Portrait {
							dur *= NSTimeInterval(2)
						}
					}

					if didFinishLaunching {
						UIView.animateWithDuration(dur) {
							self.layoutWithOrientation(orientation1)
						}
					}
					else {
						// Avoid the animation if the app hasn't finished launching.
						layoutWithOrientation(orientation1)
					}
				}
			}
		}
	}

}