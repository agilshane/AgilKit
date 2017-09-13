//
//  AGKXMLSAXParser.swift
//  AgilKit
//
//  Created by Shane Meyer on 6/9/15.
//  Copyright © 2015-2017 Agilstream, LLC. All rights reserved.
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
	func xmlsaxParser(_ parser: AGKXMLSAXParser, didEndElementPath path: String, text: String)
	func xmlsaxParser(_ parser: AGKXMLSAXParser, didStartElementPath path: String,
		attributes: [String: String])
	func xmlsaxParser(_ parser: AGKXMLSAXParser, hadError error: Error)
}

class AGKXMLSAXParser: NSObject, XMLParserDelegate {

	private var currPath = ""
	private var currText = ""
	weak var delegate: AGKXMLSAXParserDelegate?

	init(delegate: AGKXMLSAXParserDelegate?) {
		self.delegate = delegate
	}

	func parseData(_ data: Data) {
		currPath = ""
		currText = ""
		let parser = XMLParser(data: data as Data)
		parser.delegate = self
		parser.parse()
	}

	func parser(_ parser: XMLParser,
		didEndElement elementName: String,
		namespaceURI: String?,
		qualifiedName qName: String?)
	{
		delegate?.xmlsaxParser(self, didEndElementPath: currPath, text: currText)
		currText = ""
		if let range = currPath.range(of: "/", options: .backwards) {
			currPath = String(currPath[..<range.lowerBound])
		}
		else {
			assertionFailure("The current path has no forward slash!")
		}
	}

	func parser(_ parser: XMLParser,
		didStartElement elementName: String,
		namespaceURI: String?,
		qualifiedName qName: String?,
		attributes attributeDict: [String: String])
	{
		currText = ""
		currPath += "/" + elementName
		delegate?.xmlsaxParser(self, didStartElementPath: currPath, attributes: attributeDict)
	}

	func parser(_ parser: XMLParser, foundCharacters string: String) {
		currText += string
	}

	func parser(_ parser: XMLParser, parseErrorOccurred parseError: Error) {
		delegate?.xmlsaxParser(self, hadError: parseError)
	}

}
