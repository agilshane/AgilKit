//
//  AGKCrypto.swift
//  AgilKit
//
//  Created by Shane Meyer on 6/2/15.
//  Copyright © 2015-2019 Agilstream, LLC. All rights reserved.
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

	enum BlockCipherOption {
		case ecbMode, pkcs7Padding
		var value: CCOptions {
			switch self {
				case .ecbMode:
					return CCOptions(kCCOptionECBMode)
				case .pkcs7Padding:
					return CCOptions(kCCOptionPKCS7Padding)
			}
		}
	}

	class func aes128Decrypt(data: Data, key: Data, option: BlockCipherOption) -> Data? {
		guard key.count == kCCKeySizeAES128 else {
			assertionFailure("The AES 128 key size is invalid!")
			return nil
		}

		let dataOutCount = data.count + kCCBlockSizeAES128
		var dataOut = Data(count: dataOutCount)
		var numBytesDecrypted = 0
		var status: CCCryptorStatus?

		key.withUnsafeBytes { bytesKey in
			data.withUnsafeBytes { bytesIn in
				dataOut.withUnsafeMutableBytes { bytesOut in
					status = CCCrypt(
						CCOperation(kCCDecrypt),
						CCAlgorithm(kCCAlgorithmAES128),
						option.value,
						bytesKey.baseAddress,
						key.count,
						nil,
						bytesIn.baseAddress,
						data.count,
						bytesOut.baseAddress,
						dataOutCount,
						&numBytesDecrypted)
				}
			}
		}

		if status == CCCryptorStatus(kCCSuccess) {
			return dataOut[0 ..< numBytesDecrypted]
		}

		assertionFailure("AES 128 decryption failed!")
		return nil
	}

	class func aes128Encrypt(data: Data, key: Data, option: BlockCipherOption) -> Data? {
		guard key.count == kCCKeySizeAES128 else {
			assertionFailure("The AES 128 key size is invalid!")
			return nil
		}

		let dataOutCount = data.count + kCCBlockSizeAES128
		var dataOut = Data(count: dataOutCount)
		var numBytesEncrypted = 0
		var status: CCCryptorStatus?

		key.withUnsafeBytes { bytesKey in
			data.withUnsafeBytes { bytesIn in
				dataOut.withUnsafeMutableBytes { bytesOut in
					status = CCCrypt(
						CCOperation(kCCEncrypt),
						CCAlgorithm(kCCAlgorithmAES128),
						option.value,
						bytesKey.baseAddress,
						key.count,
						nil,
						bytesIn.baseAddress,
						data.count,
						bytesOut.baseAddress,
						dataOutCount,
						&numBytesEncrypted)
				}
			}
		}

		if status == CCCryptorStatus(kCCSuccess) {
			return dataOut[0 ..< numBytesEncrypted]
		}

		assertionFailure("AES 128 encryption failed!")
		return nil
	}

	class func md5(data: Data) -> Data {
		var result = Data(count: Int(CC_MD5_DIGEST_LENGTH))
		data.withUnsafeBytes { bytesIn in
			result.withUnsafeMutableBytes { bytesOut in
				let bytesOut2 = bytesOut.bindMemory(to: UInt8.self)
				CC_MD5(bytesIn.baseAddress, CC_LONG(data.count), bytesOut2.baseAddress)
			}
		}
		return result
	}

	class func md5OfFile(url: URL) -> Data? {
		guard url.isFileURL else {
			assertionFailure("The URL is not a file URL!")
			return nil
		}

		guard let handle = try? FileHandle(forReadingFrom: url) else {
			assertionFailure("The file handle is nil!")
			return nil
		}

		var ctx = CC_MD5_CTX()
		CC_MD5_Init(&ctx)

		while true {
			let data = handle.readData(ofLength: 16384)
			guard data.count > 0 else { break }
			data.withUnsafeBytes { bytes in
				_ = CC_MD5_Update(&ctx, bytes.baseAddress, CC_LONG(data.count))
			}
		}

		var result = Data(count: Int(CC_MD5_DIGEST_LENGTH))
		result.withUnsafeMutableBytes { bytes  in
			let bytes2 = bytes.bindMemory(to: UInt8.self)
			CC_MD5_Final(bytes2.baseAddress, &ctx)
		}
		return result
	}

	class func sha1(data: Data) -> Data {
		var result = Data(count: Int(CC_SHA1_DIGEST_LENGTH))
		data.withUnsafeBytes { bytesIn in
			result.withUnsafeMutableBytes { bytesOut in
				let bytesOut2 = bytesOut.bindMemory(to: UInt8.self)
				CC_SHA1(bytesIn.baseAddress, CC_LONG(data.count), bytesOut2.baseAddress)
			}
		}
		return result
	}

	class func sha1(data: Data, hmacKey: Data) -> Data {
		var result = Data(count: Int(CC_SHA1_DIGEST_LENGTH))
		data.withUnsafeBytes { bytesIn in
			hmacKey.withUnsafeBytes { bytesKey in
				result.withUnsafeMutableBytes { bytesOut in
					CCHmac(CCHmacAlgorithm(kCCHmacAlgSHA1),
						bytesKey.baseAddress,
						hmacKey.count,
						bytesIn.baseAddress,
						data.count,
						bytesOut.baseAddress)
				}
			}
		}
		return result
	}

	class func sha1OfFile(url: URL) -> Data? {
		guard url.isFileURL else {
			assertionFailure("The URL is not a file URL!")
			return nil
		}

		guard let handle = try? FileHandle(forReadingFrom: url) else {
			assertionFailure("The file handle is nil!")
			return nil
		}

		var ctx = CC_SHA1_CTX()
		CC_SHA1_Init(&ctx)

		while true {
			let data = handle.readData(ofLength: 16384)
			guard data.count > 0 else { break }
			data.withUnsafeBytes { bytes in
				_ = CC_SHA1_Update(&ctx, bytes.baseAddress, CC_LONG(data.count))
			}
		}

		var result = Data(count: Int(CC_SHA1_DIGEST_LENGTH))
		result.withUnsafeMutableBytes { bytes in
			let bytes2 = bytes.bindMemory(to: UInt8.self)
			CC_SHA1_Final(bytes2.baseAddress, &ctx)
		}
		return result
	}

	class func sha256(data: Data) -> Data {
		var result = Data(count: Int(CC_SHA256_DIGEST_LENGTH))
		data.withUnsafeBytes { bytesIn in
			result.withUnsafeMutableBytes { bytesOut in
				let bytesOut2 = bytesOut.bindMemory(to: UInt8.self)
				CC_SHA256(bytesIn.baseAddress, CC_LONG(data.count), bytesOut2.baseAddress)
			}
		}
		return result
	}

}
