//
//  AGKColor.swift
//  AgilKit
//
//  Created by Shane Meyer on 12/17/14.
//  Copyright © 2013-2018 Agilstream, LLC. All rights reserved.
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

class AGKColor {

	private static let scalar0 = UInt32(UnicodeScalar("0"))
	private static let scalarA = UInt32(UnicodeScalar("A"))
	private static let scalarF = UInt32(UnicodeScalar("F"))
	private static let scalara = UInt32(UnicodeScalar("a"))
	private static let scalarf = UInt32(UnicodeScalar("f"))

	class func color(rrggbb: String) -> UIColor? {
		let scalars = Array(rrggbb.unicodeScalars)
		let len = scalars.count
		guard len == 6 || len == 8 else { return nil }

		let r = hexCharToInt(scalars[0]) * 16 + hexCharToInt(scalars[1])
		let g = hexCharToInt(scalars[2]) * 16 + hexCharToInt(scalars[3])
		let b = hexCharToInt(scalars[4]) * 16 + hexCharToInt(scalars[5])
		let a = (len == 8) ? hexCharToInt(scalars[6]) * 16 + hexCharToInt(scalars[7]) : 255

		return UIColor(
			red:   CGFloat(r) / CGFloat(255),
			green: CGFloat(g) / CGFloat(255),
			blue:  CGFloat(b) / CGFloat(255),
			alpha: CGFloat(a) / CGFloat(255))
	}

	private class func hexCharToInt(_ scalar: UnicodeScalar) -> Int {
		let value = scalar.value

		if value >= scalarA && value <= scalarF {
			return Int(value - scalarA) + 10
		}

		if value >= scalara && value <= scalarf {
			return Int(value - scalara) + 10
		}

		return Int(value - scalar0)
	}

	class func hsba(color: UIColor) -> (h: CGFloat, s: CGFloat, b: CGFloat, a: CGFloat) {
		var h = CGFloat(0)
		var s = CGFloat(0)
		var b = CGFloat(0)
		var a = CGFloat(0)
		color.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
		return (h, s, b, a)
	}

	class func rgba(color: UIColor) -> (r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) {
		var r = CGFloat(0)
		var g = CGFloat(0)
		var b = CGFloat(0)
		var a = CGFloat(0)
		color.getRed(&r, green: &g, blue: &b, alpha: &a)
		return (r, g, b, a)
	}

	class func rrggbbString(color: UIColor, includeAlpha: Bool) -> String {
		let (r, g, b, a) = rgba(color: color)

		if includeAlpha {
			let floats = [
				round(r * 255),
				round(g * 255),
				round(b * 255),
				round(a * 255),
			]
			return AGKHex.string(data: Data(bytes: [
				UInt8(floats[0]),
				UInt8(floats[1]),
				UInt8(floats[2]),
				UInt8(floats[3]),
			]))
		}

		return AGKHex.string(data: Data(bytes: [
			UInt8(round(r * 255)),
			UInt8(round(g * 255)),
			UInt8(round(b * 255)),
		]))
	}

}
