//
//  AGKXMLSAXParser.swift
//  AgilKit
//
//  Created by Shane Meyer on 6/9/15.
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

protocol AGKXMLSAXParserDelegate: class {
	func xmlsaxParser(parser: AGKXMLSAXParser, didEndElementPath path: String, text: String)
	func xmlsaxParser(parser: AGKXMLSAXParser, didStartElementPath path: String,
		attributes: [String: String])
	func xmlsaxParser(parser: AGKXMLSAXParser, hadError error: NSError)
}

class AGKXMLSAXParser: NSObject, NSXMLParserDelegate {

	private var currPath = ""
	private var currText = ""
	private weak var delegate: AGKXMLSAXParserDelegate?

	init(delegate: AGKXMLSAXParserDelegate) {
		self.delegate = delegate
	}

	func parseData(data: NSData) {
		currPath = ""
		currText = ""
		let parser = NSXMLParser(data: data)
		parser.delegate = self
		parser.parse()
	}

	func parser(parser: NSXMLParser,
		didEndElement elementName: String,
		namespaceURI: String?,
		qualifiedName qName: String?)
	{
		delegate?.xmlsaxParser(self, didEndElementPath: currPath, text: currText)
		currText = ""
		if let range = currPath.rangeOfString("/", options: .BackwardsSearch) {
			currPath = currPath.substringToIndex(range.startIndex)
		}
		else {
			assertionFailure("The current path has no forward slash!")
		}
	}

	func parser(parser: NSXMLParser,
		didStartElement elementName: String,
		namespaceURI: String?,
		qualifiedName qName: String?,
		attributes attributeDict: [String: String])
	{
		currText = ""
		currPath += "/" + elementName
		delegate?.xmlsaxParser(self, didStartElementPath: currPath, attributes: attributeDict)
	}

	func parser(parser: NSXMLParser, foundCharacters string: String) {
		currText += string
	}

	func parser(parser: NSXMLParser, parseErrorOccurred parseError: NSError) {
		delegate?.xmlsaxParser(self, hadError: parseError)
	}

}
