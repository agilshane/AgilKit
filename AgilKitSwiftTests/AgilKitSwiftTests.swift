//
//  AgilKitSwiftTests.swift
//  AgilKitSwiftTests
//
//  Created by Shane Meyer on 12/5/14.
//  Copyright © 2014-2017 Agilstream, LLC. All rights reserved.
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
import XCTest

class AgilKitSwiftTests: XCTestCase {

	func testColor() {
		let (r0, g0, b0, a0) = AGKColor.rgba(color: UIColor.white)
		XCTAssertTrue(r0 == 1.0 && g0 == 1.0 && b0 == 1.0 && a0 == 1.0)

		let (r1, g1, b1, a1) = AGKColor.rgba(color: UIColor.black)
		XCTAssertTrue(r1 == 0.0 && g1 == 0.0 && b1 == 0.0 && a1 == 1.0)

		XCTAssertTrue(AGKColor.color(rrggbb: "1234567") == nil)

		let c0 = AGKColor.color(rrggbb: "05A9cE")!
		let (r2, g2, b2, a2) = AGKColor.rgba(color: c0)

		XCTAssertTrue(
			r2 == CGFloat(  5) / CGFloat(255) &&
			g2 == CGFloat(169) / CGFloat(255) &&
			b2 == CGFloat(206) / CGFloat(255) &&
			a2 == 1.0)

		XCTAssertTrue(AGKColor.rrggbbString(color: c0, includeAlpha: true) == "05A9CEFF")
		XCTAssertTrue(AGKColor.rrggbbString(color: c0, includeAlpha: false) == "05A9CE")

		let c1 = UIColor(
			red:   CGFloat(  5) / CGFloat(255),
			green: CGFloat(169) / CGFloat(255),
			blue:  CGFloat(206) / CGFloat(255),
			alpha: CGFloat(1))

		XCTAssertTrue(c0 == c1)
		XCTAssertTrue(c0 != UIColor.red)
	}

	func testCrypto() {
		let data = "abcdefghijklmnopqrstuvwxyz".data(using: String.Encoding.utf8)!
		let key = "this is the key".data(using: String.Encoding.utf8)!

		var result = AGKHex.string(data: AGKCrypto.sha1(data: data))
		XCTAssertTrue(result == "32D10C7B8CF96570CA04CE37F2A19D84240D3A89")

		result = AGKHex.string(data: AGKCrypto.sha1(data: data, hmacKey: key))
		XCTAssertTrue(result == "345DF8EAF4AE8ADF276BEA5E282FA732F8F8BEF4")

		result = AGKHex.string(data: AGKCrypto.sha256(data: data))
		XCTAssertTrue(result == "71C480DF93D6AE2F1EFAD1447C66C9525E316218CF51FC8D9ED832F2DAF18B73")
	}

	func testHex() {
		let count = 199;
		var bytes = [UInt8](repeating: 0, count: count)

		for i in 0 ..< count {
			bytes[i] = UInt8(arc4random() % 256)
		}

		let data0 = Data(bytes: UnsafePointer<UInt8>(bytes), count: count)
		let hex0 = AGKHex.string(data: data0)
		let data1 = AGKHex.data(string: hex0)!
		let hex1 = AGKHex.string(data: data1)

		XCTAssertTrue(data0 == data1)
		XCTAssertTrue(hex0 == hex1)
	}

	func testXML() {
		let parser = TestParser()
		XCTAssertTrue(parser.success)
	}

}

class TestParser: AGKXMLSAXParserDelegate {

	private(set) var success = true
	private let xml = "<root><hello foo='bar'>There</hello><a><b>Bee</b></a></root>"

	init() {
		let parser = AGKXMLSAXParser(delegate: self)
		parser.parseData(xml.data(using: String.Encoding.utf8)!)
	}

	func xmlsaxParser(_ parser: AGKXMLSAXParser,
		didEndElementPath path: String,
		text: String)
	{
		if path == "/root/a/b" {
			if text != "Bee" {
				success = false
			}
		}
	}

	func xmlsaxParser(_ parser: AGKXMLSAXParser,
		didStartElementPath path: String,
		attributes: [String : String])
	{
		if path == "/root/hello" {
			if attributes["foo"] != "bar" {
				success = false
			}
		}
	}

	func xmlsaxParser(_ parser: AGKXMLSAXParser, hadError error: Error) {
		success = false
	}

}
