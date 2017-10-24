//
//  AGKKeychain.swift
//  AgilKit
//
//  Created by Shane Meyer on 10/24/17.
//  Copyright © 2017 Agilstream, LLC. All rights reserved.
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

class AGKKeychain {

	private static let secAttrAccessible = kSecAttrAccessible as String
	private static let secAttrAccount = kSecAttrAccount as String
	private static let secAttrGeneric = kSecAttrGeneric as String
	private static let secAttrService = kSecAttrService as String
	private static let secClass = kSecClass as String
	private static let secMatchLimit = kSecMatchLimit as String
	private static let secReturnData = kSecReturnData as String
	private static let secValueData = kSecValueData as String

	private class func createDictionary(key: String) -> [String: Any] {
		let id = key.data(using: .utf8)!
		return [
			secAttrAccount: id,
			secAttrGeneric: id,
			secAttrService: Bundle.main.bundleIdentifier!,
			secClass: kSecClassGenericPassword,
		]
	}

	class func data(key: String) -> Data? {
		var dict = createDictionary(key: key)
		dict[secMatchLimit] = kSecMatchLimitOne
		dict[secReturnData] = kCFBooleanTrue
		var result: AnyObject?
		let status = SecItemCopyMatching(dict as CFDictionary, &result)
		return status == noErr ? result as? Data : nil
	}

	class func delete(key: String) {
		let status = SecItemDelete(createDictionary(key: key) as CFDictionary)
		assert(status == errSecSuccess || status == errSecItemNotFound)
	}

	class func setData(_ data: Data, key: String) {
		var dict = createDictionary(key: key)
		dict[secAttrAccessible] = kSecAttrAccessibleWhenUnlocked
		dict[secValueData] = data
		let status = SecItemAdd(dict as CFDictionary, nil)
		if status == errSecDuplicateItem {
			updateData(data, key: key)
		}
		else {
			assert(status == errSecSuccess)
		}
	}

	class func setString(_ string: String, key: String) {
		setData(string.data(using: .utf8)!, key: key)
	}

	class func string(key: String) -> String? {
		guard let data = data(key: key) else { return nil }
		return String(data: data, encoding: .utf8)
	}

	private class func updateData(_ data: Data, key: String) {
		let dict0 = createDictionary(key: key)
		let dict1 = [secValueData: data]
		let status = SecItemUpdate(dict0 as CFDictionary, dict1 as CFDictionary)
		assert(status == errSecSuccess)
	}

}
