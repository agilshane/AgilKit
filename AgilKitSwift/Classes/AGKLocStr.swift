//
//  AGKLocStr.swift
//  AgilKit
//
//  Created by Shane Meyer on 10/29/14.
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

func AGKLocStr(key: String, _ args: (String, String)...) -> String {
	let notFound = "NOT_F0UND"
	var s = NSBundle.mainBundle().localizedStringForKey(key, value: notFound, table: nil)
	assert(s != notFound, "Localized string '\(key)' not found!")

	for (argKey, argVal) in args {
		s = s.stringByReplacingOccurrencesOfString(argKey, withString: argVal)
	}

	return s
}

func AGKLocStrError(key: String, _ args: (String, String)...) -> NSError {
	let notFound = "NOT_F0UND"
	var s = NSBundle.mainBundle().localizedStringForKey(key, value: notFound, table: nil)
	assert(s != notFound, "Localized string '\(key)' not found!")

	for (argKey, argVal) in args {
		s = s.stringByReplacingOccurrencesOfString(argKey, withString: argVal)
	}

	return NSError(domain: "AGKLocStrErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: s])
}
