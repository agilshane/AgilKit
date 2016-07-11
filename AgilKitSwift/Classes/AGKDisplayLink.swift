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

class AGKDisplayLink {

	private weak var delegate: AGKDisplayLinkDelegate?
	private var didFire = false
	private var impl: AGKDisplayLinkImpl?
	private var originalTimestamp = CFTimeInterval(0)

	var duration: CFTimeInterval {
		return impl?.displayLink?.duration ?? CFTimeInterval(0)
	}

	var paused: Bool {
		get {
			return impl?.displayLink?.paused ?? false
		}
		set {
			impl?.displayLink?.paused = newValue
		}
	}

	var timestamp: CFTimeInterval {
		let t = impl?.displayLink?.timestamp ?? CFTimeInterval(0)
		return didFire ? t - originalTimestamp : CFTimeInterval(0)
	}

	init(delegate: AGKDisplayLinkDelegate, frameInterval: Int, commonModes: Bool = false) {
		self.delegate = delegate
		impl = AGKDisplayLinkImpl(parent: self, frameInterval: frameInterval,
			commonModes: commonModes)
	}

	deinit {
		impl?.invalidate()
		impl = nil
	}

	private func implDidFire() {
		if !didFire {
			didFire = true
			originalTimestamp = impl?.displayLink?.timestamp ?? CFTimeInterval(0)
		}
		delegate?.displayLinkDidFire(self)
	}

}

private class AGKDisplayLinkImpl {

	var displayLink: CADisplayLink?
	weak var parent: AGKDisplayLink?

	init(parent: AGKDisplayLink, frameInterval: Int, commonModes: Bool) {
		self.parent = parent
		displayLink = CADisplayLink(target: self, selector: #selector(onTimer))
		displayLink?.frameInterval = frameInterval
		displayLink?.addToRunLoop(NSRunLoop.mainRunLoop(), forMode: commonModes ?
			NSRunLoopCommonModes : NSDefaultRunLoopMode)
	}

	func invalidate() {
		parent = nil
		displayLink?.invalidate()
		displayLink = nil
	}

	@objc
	func onTimer() {
		parent?.implDidFire()
	}

}
