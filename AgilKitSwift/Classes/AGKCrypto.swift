//
//  AGKCrypto.swift
//  AgilKit
//
//  Created by Shane Meyer on 6/2/15.
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

import Foundation

class AGKCrypto {

	class func sha1(data: NSData) -> NSData {
		var bytes = [UInt8](count: Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
		CC_SHA1(data.bytes, CC_LONG(data.length), &bytes)
		return NSData(bytes: bytes, length: bytes.count)
	}

	class func sha1(data: NSData, hmacKey: NSData) -> NSData {
		var bytes = [UInt8](count: Int(CC_SHA1_DIGEST_LENGTH), repeatedValue: 0)
		CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1), hmacKey.bytes, hmacKey.length,
			data.bytes, data.length, &bytes)
		return NSData(bytes: bytes, length: bytes.count)
	}

	class func sha256(data: NSData) -> NSData {
		var bytes = [UInt8](count: Int(CC_SHA256_DIGEST_LENGTH), repeatedValue: 0)
		CC_SHA256(data.bytes, CC_LONG(data.length), &bytes)
		return NSData(bytes: bytes, length: bytes.count)
	}

}
