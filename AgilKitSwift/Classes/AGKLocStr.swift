//
//  AGKLocStr.swift
//  AgilKit
//
//  Created by Shane Meyer on 10/29/14.
//  Copyright © 2013-2019 Agilstream, LLC. All rights reserved.
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

func AGKLocStr(_ key: String, _ args: String...) -> String {
	return processString(key: key, args: args)
}

func AGKLocStrError(_ key: String, _ args: String...) -> Error {
	let s = processString(key: key, args: args)
	return NSError(domain: "AGKLocStrErrorDomain", code: 0, userInfo: [NSLocalizedDescriptionKey: s])
}

fileprivate func processString(key: String, args: [String]) -> String {
	let notFound = "N0T_F0UND!"
	var s = Bundle.main.localizedString(forKey: key, value: notFound, table: nil)

	assert(s != notFound, "Localized string '\(key)' not found!")
	assert(args.count % 2 == 0)

	var i = 0
	while i < args.count {
		if i + 1 < args.count {
			let k = args[i]
			let v = args[i + 1]
			s = s.replacingOccurrences(of: k, with: v)
		}
		i += 2
	}

	return s
}
