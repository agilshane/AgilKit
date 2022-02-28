//
//  AGKTimer.swift
//  AgilKit
//
//  Created by Shane Meyer on 12/18/14.
//  Copyright © 2013-2021 Agilstream, LLC. All rights reserved.
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
//  -------------------------------------------------------------------------------------------
//
//  The purpose of this class is simply to avoid the need to invalidate. A Timer retains
//  its delegate, requiring someone to invalidate the timer in order for its delegate to be
//  released. Often that burden is placed on someone higher up the call chain, which isn't
//  good encapsulation and can easily be forgotten, leading to leaks.
//

import Foundation

protocol AGKTimerDelegate: AnyObject {
	func timerDidFire(_ timer: AGKTimer)
}

class AGKTimer {

	private weak var delegate: AGKTimerDelegate?
	private var impl: AGKTimerImpl?

	init(delegate: AGKTimerDelegate, timeInterval: TimeInterval,
		repeats: Bool, commonModes: Bool = false)
	{
		self.delegate = delegate
		impl = AGKTimerImpl(parent: self, timeInterval: timeInterval,
			repeats: repeats, commonModes: commonModes)
	}

	deinit {
		delegate = nil
		impl?.invalidate()
		impl = nil
	}

	fileprivate func implDidFire() {
		delegate?.timerDidFire(self)
	}

}

private class AGKTimerImpl {

	weak var parent: AGKTimer?
	var timer: Timer?

	init(parent: AGKTimer, timeInterval: TimeInterval, repeats: Bool, commonModes: Bool) {
		self.parent = parent
		timer = Timer(timeInterval: timeInterval, target: self, selector: #selector(onTimer),
			userInfo: nil, repeats: repeats)
		if let t = timer {
			RunLoop.current.add(t, forMode: commonModes ? .common : .default)
		}
		else {
			assertionFailure("The Timer is nil!")
		}
	}

	func invalidate() {
		parent = nil
		timer?.invalidate()
		timer = nil
	}

	@objc
	private func onTimer() {
		parent?.implDidFire()
	}

}
