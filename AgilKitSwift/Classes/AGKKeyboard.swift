//
//  AGKKeyboard.swift
//  AgilKit
//
//  Created by Shane Meyer on 4/3/15.
//  Copyright © 2015-2021 Agilstream, LLC. All rights reserved.
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

protocol AGKKeyboardDelegate: AnyObject {
	func keyboardHeightWillChange(_ keyboard: AGKKeyboard, duration: Double)
}

class AGKKeyboard {

	weak var delegate: AGKKeyboardDelegate?
	private(set) var height: CGFloat = 0

	init(delegate: AGKKeyboardDelegate?) {
		self.delegate = delegate
		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(onKeyboardWillHide(_:)),
			name: UIResponder.keyboardWillHideNotification, object: nil)
		nc.addObserver(self, selector: #selector(onKeyboardWillShow(_:)),
			name: UIResponder.keyboardWillShowNotification, object: nil)
	}

	func calculateAdditionalBottomInset(viewController: UIViewController) -> CGFloat {
		guard height > 0 else { return 0 }
		var inset = height
		guard let view = viewController.viewIfLoaded, let window = view.window else { return 0 }
		let windowHeight = window.bounds.maxY
		let point = view.convert(CGPoint(x: 0, y: view.bounds.maxY), to: nil)
		let delta = windowHeight - point.y
		if delta == 0 {
			inset -= window.safeAreaInsets.bottom
		}
		inset -= delta
		if let nav = viewController.navigationController, !nav.isToolbarHidden {
			inset -= nav.toolbar.bounds.height
		}
		return max(0, inset)
	}

	@objc
	private func onKeyboardWillHide(_ notification: Notification) {
		height = 0
		let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]
		delegate?.keyboardHeightWillChange(self, duration: duration as! Double)
	}

	@objc
	private func onKeyboardWillShow(_ notification: Notification) {
		if let val = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
			let size = val.cgRectValue.size
			height = size.width > size.height ? size.height : size.width
			let duration = notification.userInfo![UIResponder.keyboardAnimationDurationUserInfoKey]
			delegate?.keyboardHeightWillChange(self, duration: duration as! Double)
		}
	}

}
