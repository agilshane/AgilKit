//
//  AGKHex.swift
//  AgilKit
//
//  Created by Shane Meyer on 10/30/14.
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

import Foundation

class AGKHex {

	private static let scalar0 = UInt32(UnicodeScalar("0"))
	private static let scalar9 = UInt32(UnicodeScalar("9"))
	private static let scalarA = UInt32(UnicodeScalar("A"))
	private static let scalarF = UInt32(UnicodeScalar("F"))
	private static let scalara = UInt32(UnicodeScalar("a"))
	private static let scalarf = UInt32(UnicodeScalar("f"))

	class func bytesFromString(s: String) -> [UInt8] {
		let chars = Array(s.unicodeScalars)
		let charCount = chars.count

		if charCount % 2 != 0 {
			assertionFailure("The hex string has an odd number of characters!")
			return []
		}

		var bytes = [UInt8](count: charCount / 2, repeatedValue: 0)

		for var i = 0; i < charCount; i += 2 {
			var c0 = chars[i + 0].value
			var c1 = chars[i + 1].value

			if c0 >= scalar0 && c0 <= scalar9 {
				c0 -= scalar0
			}
			else if c0 >= scalarA && c0 <= scalarF {
				c0 -= scalarA
				c0 += 10
			}
			else if c0 >= scalara && c0 <= scalarf {
				c0 -= scalara
				c0 += 10
			}
			else {
				assertionFailure("The hex string contains invalid character \(c0)!")
				return []
			}

			c0 <<= 4

			if c1 >= scalar0 && c1 <= scalar9 {
				c1 -= scalar0
			}
			else if c1 >= scalarA && c1 <= scalarF {
				c1 -= scalarA
				c1 += 10
			}
			else if c1 >= scalara && c1 <= scalarf {
				c1 -= scalara
				c1 += 10
			}
			else {
				assertionFailure("The hex string contains invalid character \(c1)!")
				return []
			}

			bytes[i / 2] = UInt8(c0 + c1)
		}

		return bytes
	}

	class func dataFromString(s: String) -> NSData {
		let bytes = AGKHex.bytesFromString(s)
		return NSData(bytes: bytes, length: bytes.count)
	}

	class func stringFromBytes(bytes: [UInt8]) -> String {
		var chars = [Character](count: 2 * bytes.count, repeatedValue: "0")
		var i = 0

		for byte in bytes {
			var char0 = UInt32(byte >> 4)
			var char1 = UInt32(byte & 0xF)
			char0 += (char0 < 10 ? scalar0 : (scalarA - 10))
			char1 += (char1 < 10 ? scalar0 : (scalarA - 10))
			chars[i + 0] = Character(UnicodeScalar(char0))
			chars[i + 1] = Character(UnicodeScalar(char1))
			i += 2
		}

		return String(chars)
	}

	class func stringFromData(data: NSData) -> String {
		var bytes = [UInt8](count: data.length, repeatedValue: 0)
		data.getBytes(&bytes, length: data.length)
		return AGKHex.stringFromBytes(bytes)
	}

}
