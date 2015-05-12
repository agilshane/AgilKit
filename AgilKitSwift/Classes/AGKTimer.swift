//
//  AGKTimer.swift
//  AgilKit
//
//  Created by Shane Meyer on 12/18/14.
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
//  -------------------------------------------------------------------------------------------
//
//  The purpose of this class is simply to avoid the need to invalidate. An NSTimer retains
//  its delegate, requiring someone to invalidate the timer in order for its delegate to be
//  released. Often that burden is placed on someone higher up the call chain, which isn't
//  good encapsulation and can easily be forgotten, leading to leaks.
//

import Foundation

protocol AGKTimerDelegate: class {
	func timerDidFire(timer: AGKTimer)
}

class AGKTimer {

	private weak var delegate: AGKTimerDelegate?
	private var timerPrivate: AGKTimerPrivate?

	init(delegate: AGKTimerDelegate,
		timeInterval: NSTimeInterval,
		repeats: Bool = true,
		commonModes: Bool = false)
	{
		self.delegate = delegate

		timerPrivate = AGKTimerPrivate(
			timer: self,
			timeInterval: timeInterval,
			repeats: repeats,
			commonModes: commonModes)
	}

	deinit {
		delegate = nil
		timerPrivate?.invalidate()
		timerPrivate = nil
	}

	private func timerDidFire() {
		delegate?.timerDidFire(self)
	}

}

class AGKTimerPrivate: NSObject {

	private var nstimer: NSTimer?
	private weak var timer: AGKTimer?

	private init(timer: AGKTimer,
		timeInterval: NSTimeInterval,
		repeats: Bool,
		commonModes: Bool)
	{
		self.timer = timer
		super.init()

		nstimer = NSTimer(
			timeInterval: timeInterval,
			target: self,
			selector: "onTimer",
			userInfo: nil,
			repeats: repeats)

		NSRunLoop.currentRunLoop().addTimer(nstimer!, forMode: commonModes ?
			NSRunLoopCommonModes : NSDefaultRunLoopMode)
	}

	private func invalidate() {
		timer = nil
		nstimer?.invalidate()
		nstimer = nil
	}

	func onTimer() {
		timer?.timerDidFire()
	}

}
