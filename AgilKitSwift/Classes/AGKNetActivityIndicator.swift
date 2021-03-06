//
//  AGKNetActivityIndicator.swift
//  AgilKit
//
//  Created by Shane Meyer on 12/5/14.
//  Copyright © 2013-2017 Agilstream, LLC. All rights reserved.
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

class AGKNetActivityIndicator {

	private static var i = 0

	class func hide() {
		i -= 1

		if i < 0 {
			assertionFailure("AGKNetActivityIndicator has been hidden too many times!")
			i = 0
		}

		if i == 0 {
			#if !NO_NETWORK_ACTIVITY_INDICATOR
				UIApplication.shared.isNetworkActivityIndicatorVisible = false
			#endif
		}
	}

	class func show() {
		i += 1
		#if !NO_NETWORK_ACTIVITY_INDICATOR
			UIApplication.shared.isNetworkActivityIndicatorVisible = true
		#endif
	}

}
