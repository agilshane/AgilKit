//
//  AGKKeyboard.swift
//  AgilKit
//
//  Created by Shane Meyer on 4/3/15.
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

protocol AGKKeyboardDelegate: class {
	func keyboardHeightWillChange(keyboard: AGKKeyboard, duration: Double)
}

class AGKKeyboard: NSObject {

	private weak var delegate: AGKKeyboardDelegate?
	private(set) var height = CGFloat(0)

	init(delegate: AGKKeyboardDelegate) {
		self.delegate = delegate
		super.init()
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(onKeyboardWillHide(_:)),
			name: UIKeyboardWillHideNotification, object: nil)
		nc.addObserver(self, selector: #selector(onKeyboardWillShow(_:)),
			name: UIKeyboardWillShowNotification, object: nil)
	}

	deinit {
		NSNotificationCenter.defaultCenter().removeObserver(self)
	}

	func onKeyboardWillHide(notification: NSNotification) {
		height = 0
		let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
		delegate?.keyboardHeightWillChange(self, duration: duration)
	}

	func onKeyboardWillShow(notification: NSNotification) {
		if let val = notification.userInfo?[UIKeyboardFrameEndUserInfoKey] as? NSValue {
			let size = val.CGRectValue().size
			height = size.width > size.height ? size.height : size.width
			let duration = notification.userInfo?[UIKeyboardAnimationDurationUserInfoKey] as! Double
			delegate?.keyboardHeightWillChange(self, duration: duration)
		}
	}

}