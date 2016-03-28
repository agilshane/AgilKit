//
//  AGKDisplayLink.swift
//  AgilKit
//
//  Created by Shane Meyer on 4/25/15.
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
//  -------------------------------------------------------------------------------------------
//
//  The purpose of this class is simply to avoid the need to invalidate. CADisplayLink retains
//  its delegate, requiring someone to invalidate it in order for its delegate to be released.
//  Often that burden is placed on someone higher up the call chain, which isn't good
//  encapsulation and can easily be forgotten, leading to leaks.
//

import Foundation
import QuartzCore

protocol AGKDisplayLinkDelegate: class {
	func displayLinkDidFire(displayLink: AGKDisplayLink)
}

class AGKDisplayLink: AGKDisplayLinkImplDelegate {

	private weak var delegate: AGKDisplayLinkDelegate?
	private var didFire = false
	private var displayLinkImpl: AGKDisplayLinkImpl?
	private var originalTimestamp = CFTimeInterval(0)

	var duration: CFTimeInterval {
		return displayLinkImpl?.displayLink?.duration ?? 0
	}

	var paused: Bool {
		get {
			return displayLinkImpl?.displayLink?.paused ?? false
		}
		set {
			displayLinkImpl?.displayLink?.paused = newValue
		}
	}

	var timestamp: CFTimeInterval {
		let zero = CFTimeInterval(0)
		let t = displayLinkImpl?.displayLink?.timestamp ?? zero
		return didFire ? t - originalTimestamp : zero
	}

	init(delegate: AGKDisplayLinkDelegate, frameInterval: Int, commonModes: Bool) {
		self.delegate = delegate
		displayLinkImpl = AGKDisplayLinkImpl(delegate: self,
			frameInterval: frameInterval, commonModes: commonModes)
	}

	deinit {
		displayLinkImpl?.invalidate()
		displayLinkImpl = nil
	}

	func displayLinkImplDidFire(displayLink: AGKDisplayLinkImpl) {
		if !didFire {
			didFire = true
			originalTimestamp = displayLinkImpl?.displayLink?.timestamp ?? 0
		}
		delegate?.displayLinkDidFire(self)
	}

}

//
// AGKDisplayLinkImpl
//

private protocol AGKDisplayLinkImplDelegate: class {
	func displayLinkImplDidFire(displayLinkImpl: AGKDisplayLinkImpl)
}

class AGKDisplayLinkImpl: NSObject {

	private weak var delegate: AGKDisplayLinkImplDelegate?
	private var displayLink: CADisplayLink?

	private init(delegate: AGKDisplayLinkImplDelegate, frameInterval: Int, commonModes: Bool) {
		self.delegate = delegate
		super.init()
		displayLink = CADisplayLink(target: self, selector: #selector(onTimer))
		displayLink?.frameInterval = frameInterval
		displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: commonModes ?
			NSRunLoopCommonModes : NSDefaultRunLoopMode)
	}

	private func invalidate() {
		delegate = nil
		displayLink?.invalidate()
		displayLink = nil
	}

	func onTimer() {
		delegate?.displayLinkImplDidFire(self)
	}

}
