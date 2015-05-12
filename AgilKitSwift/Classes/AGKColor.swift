//
//  AGKColor.swift
//  AgilKit
//
//  Created by Shane Meyer on 12/17/14.
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

import UIKit

class AGKColor {

	class func colorWithRRGGBB(rrggbb: String) -> UIColor? {
		let scalars = Array(rrggbb.unicodeScalars)
		let len = scalars.count

		if len != 6 && len != 8 {
			return nil
		}

		let r = hexCharToInt(scalars[0]) * 16 + hexCharToInt(scalars[1])
		let g = hexCharToInt(scalars[2]) * 16 + hexCharToInt(scalars[3])
		let b = hexCharToInt(scalars[4]) * 16 + hexCharToInt(scalars[5])
		var a = (len == 8) ? hexCharToInt(scalars[6]) * 16 + hexCharToInt(scalars[7]) : 255

		return UIColor(
			red:   CGFloat(r) / CGFloat(255),
			green: CGFloat(g) / CGFloat(255),
			blue:  CGFloat(b) / CGFloat(255),
			alpha: CGFloat(a) / CGFloat(255))
	}

	class func componentsOfColor(color: UIColor) ->
		(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat)
	{
		var r = CGFloat(0)
		var g = CGFloat(0)
		var b = CGFloat(0)
		var a = CGFloat(0)

		let len = CGColorGetNumberOfComponents(color.CGColor)
		let components = CGColorGetComponents(color.CGColor)

		if len == 2 {
			r = components[0]
			g = components[0]
			b = components[0]
			a = components[1]
		}
		else if len == 4 {
			r = components[0]
			g = components[1]
			b = components[2]
			a = components[3]
		}
		else {
			assertionFailure("Got a color with \(len) components!")
		}

		return (r, g, b, a)
	}

	private class func hexCharToInt(scalar: UnicodeScalar) -> Int {
		let value = scalar.value

		if value >= UInt32("A") && value <= UInt32("F") {
			return Int(value - UInt32("A")) + 10
		}

		if value >= UInt32("a") && value <= UInt32("f") {
			return Int(value - UInt32("a")) + 10
		}

		return Int(value - UInt32("0"))
	}

	class func rrggbbStringForColor(color: UIColor, includeAlpha: Bool) -> String {
		let (r, g, b, a) = componentsOfColor(color)

		if includeAlpha {
			return AGKHex.stringFromBytes([
				UInt8(round(r * CGFloat(255))),
				UInt8(round(g * CGFloat(255))),
				UInt8(round(b * CGFloat(255))),
				UInt8(round(a * CGFloat(255)))])
		}

		return AGKHex.stringFromBytes([
			UInt8(round(r * CGFloat(255))),
			UInt8(round(g * CGFloat(255))),
			UInt8(round(b * CGFloat(255)))])
	}

}
