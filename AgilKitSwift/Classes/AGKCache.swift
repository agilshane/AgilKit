//
//  AGKCache.swift
//  AgilKit
//
//  Created by Shane Meyer on 6/6/15.
//  Copyright © 2015-2018 Agilstream, LLC. All rights reserved.
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

protocol AGKCacheDelegate: class {
	func cacheDidFinish(_ cache: AGKCache, error: Error?)
}

class AGKCache: AGKNetRequestDelegate {

	enum RequestType {
		case data, image
	}

	enum TrimPolicy {
		case becomeOrResignActive, none
	}

	fileprivate static var basePaths = [URL: URL]()
	private(set) var data: Data?
	weak var delegate: AGKCacheDelegate?
	private static var didAddToCacheSinceLastTrim = false
	fileprivate static var fileInfos = [URL: AGKCacheFileInfo]()
	private(set) var image: UIImage?
	private let keepIfExpired: Bool
	private static var maxBytes = UInt64(10 * 1024 * 1024)
	private var netRequest: AGKNetRequest?
	private static let observer = AGKCacheObserver()
	private let requestType: RequestType
	private let timeToLive: TimeInterval
	fileprivate static var trimPolicy = TrimPolicy.becomeOrResignActive
	let url: URL

	private static let rootPath: URL = {
		let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
		return url.appendingPathComponent("AGKCache", isDirectory: true)
	}()

	init(delegate: AGKCacheDelegate?, url: URL, requestType: RequestType,
		timeToLive: TimeInterval = TimeInterval(3600 * 24 * 365), keepIfExpired: Bool = true)
	{
		_ = AGKCache.observer // Create the singleton observer in case initialize() wasn't called.

		self.delegate = delegate
		self.keepIfExpired = keepIfExpired
		self.requestType = requestType
		self.timeToLive = timeToLive
		self.url = url

		netRequest = AGKNetRequest(delegate: self, url: url)
	}

	class func add(data: Data, url: URL, timeToLive: TimeInterval, keepIfExpired: Bool) {
		let bp = basePath(url: url)
		try? FileManager.default.createDirectory(at: bp,
			withIntermediateDirectories: true, attributes: nil)
		let path = bp.appendingPathComponent("file.bin", isDirectory: false)
		try? data.write(to: path, options: [.atomic])
		writeInfoFile(basePath: bp, timeToLive: timeToLive, keepIfExpired: keepIfExpired)
	}

	private class func add(imageData: Data, ext: String, url: URL,
		timeToLive: TimeInterval, keepIfExpired: Bool)
	{
		let bp = basePath(url: url)
		try? FileManager.default.createDirectory(at: bp,
			withIntermediateDirectories: true, attributes: nil)
		let scale = UIScreen.main.scale
		let filename =
			scale == CGFloat(3) ? "file@3x" :
			scale == CGFloat(2) ? "file@2x" : "file"
		let path = bp.appendingPathComponent(filename + ext, isDirectory: false)
		try? imageData.write(to: path, options: [.atomic])
		writeInfoFile(basePath: bp, timeToLive: timeToLive, keepIfExpired: keepIfExpired)
	}

	class func add(jpegData: Data, url: URL, timeToLive: TimeInterval, keepIfExpired: Bool) {
		add(imageData: jpegData, ext: ".jpg", url: url, timeToLive: timeToLive,
			keepIfExpired: keepIfExpired)
	}

	class func add(pngData: Data, url: URL, timeToLive: TimeInterval, keepIfExpired: Bool) {
		add(imageData: pngData, ext: ".png", url: url, timeToLive: timeToLive,
			keepIfExpired: keepIfExpired)
	}

	private class func basePath(url: URL) -> URL {
		if let path = basePaths[url] {
			return path
		}
		let data = AGKCrypto.sha1(data: url.absoluteString.data(using: .utf8)!)
		let path = rootPath.appendingPathComponent(AGKHex.string(data: data), isDirectory: true)
		basePaths[url] = path
		return path
	}

	class func data(url: URL) -> Data? {
		if let path = dataPath(url: url) {
			return try? Data(contentsOf: path)
		}
		return nil
	}

	class func dataPath(url: URL) -> URL? {
		if let contents = try? FileManager.default.contentsOfDirectory(at: basePath(url: url),
			includingPropertiesForKeys: nil, options: [])
		{
			for path in contents {
				let ext = path.pathExtension
				if ext == "jpg" || ext == "png" || ext == "bin" {
					return path
				}
			}
		}
		return nil
	}

	class func deleteFile(url: URL) {
		let bp = basePath(url: url)
		fileInfos.removeValue(forKey: bp)
		try? FileManager.default.removeItem(at: bp)
	}

	class func fileExists(url: URL) -> Bool {
		let path = basePath(url: url).appendingPathComponent("file.info", isDirectory: false)
		return (try? path.checkResourceIsReachable()) ?? false
	}

	class func fileExpired(url: URL) -> Bool {
		let bp = basePath(url: url)
		if let fileInfo = fileInfos[bp] {
			return fileInfo.expiry <= Date.timeIntervalSinceReferenceDate
		}
		if let fileInfo = AGKCacheFileInfo(basePath: bp) {
			fileInfos[bp] = fileInfo
			return fileInfo.expiry <= Date.timeIntervalSinceReferenceDate
		}
		return false
	}

	class func image(url: URL) -> UIImage? {
		if let path = imagePath(url: url)?.path {
			return UIImage(contentsOfFile: path)
		}
		return nil
	}

	class func imagePath(url: URL) -> URL? {
		let bp = basePath(url: url)
		let scale = UIScreen.main.scale
		let x = (scale == CGFloat(1)) ? "" : "@\(Int(scale))x"
		let path = bp.appendingPathComponent("file" + x, isDirectory: false)

		do {
			let u = path.appendingPathExtension("jpg")
			if (try? u.checkResourceIsReachable()) ?? false {
				return u
			}
		}

		do {
			let u = path.appendingPathExtension("png")
			if (try? u.checkResourceIsReachable()) ?? false {
				return u
			}
		}

		return nil
	}

	class func initialize(maxBytes: UInt64 = 10 * 1024 * 1024,
		trimPolicy: TrimPolicy = .becomeOrResignActive)
	{
		self.maxBytes = maxBytes
		_ = observer // Create the singleton observer.
	}

	func netRequestDidFinish(_ netRequest: AGKNetRequest, error: Error?) {
		if error == nil && netRequest.statusCode == 200 {
			AGKCache.deleteFile(url: url)
			data = netRequest.responseBody

			switch requestType {
				case .data:
					AGKCache.add(data: netRequest.responseBody, url: url,
						timeToLive: timeToLive, keepIfExpired: keepIfExpired)

				case .image:
					var isJPEG = false
					var isPNG = false

					for (key, val) in netRequest.responseHeaders {
						if key.lowercased() == "content-type" {
							let valLower = val.lowercased()
							if valLower == "image/jpeg" {
								isJPEG = true
							}
							else if valLower == "image/png" {
								isPNG = true
							}
							break
						}
					}

					if !isJPEG && !isPNG {
						let urlLower = url.absoluteString.lowercased()
						if urlLower.range(of: ".jpg") != nil || urlLower.range(of: ".jpeg") != nil {
							isJPEG = true
						}
						else if urlLower.range(of: ".png") != nil {
							isPNG = true
						}
					}

					if isJPEG || isPNG {
						let scale = UIScreen.main.scale
						if let image = UIImage(data: netRequest.responseBody, scale: scale) {
							self.image = image
							if isJPEG {
								AGKCache.add(jpegData: netRequest.responseBody, url: url,
									timeToLive: timeToLive, keepIfExpired: keepIfExpired)
							}
							else {
								AGKCache.add(pngData: netRequest.responseBody, url: url,
									timeToLive: timeToLive, keepIfExpired: keepIfExpired)
							}
						}
					}
			}
		}

		delegate?.cacheDidFinish(self, error: error)
		self.netRequest = nil
	}

	class func trim() {
		if !didAddToCacheSinceLastTrim {
			return
		}

		let fm = FileManager.default
		var items = [AGKCacheItem]()
		let now = Date.timeIntervalSinceReferenceDate
		var totalSize = UInt64(0)

		do {
			for basePath in try fm.contentsOfDirectory(at: rootPath,
				includingPropertiesForKeys: nil, options: [])
			{
				guard let contents = try? fm.contentsOfDirectory(at: basePath,
					includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey],
					options: [])
				else { continue }

				for path in contents {
					let ext = path.pathExtension
					if ext == "jpg" || ext == "png" || ext == "bin" {
						var obj0: AnyObject?
						var obj1: AnyObject?
						try (path as NSURL).getResourceValue(&obj0,
							forKey: .contentModificationDateKey)
						try (path as NSURL).getResourceValue(&obj1,
							forKey: .fileSizeKey)
						if let modified = obj0 as? Date, let size = obj1 as? NSNumber {
							let item = AGKCacheItem(basePath: basePath, modified: modified,
								size: size.uint64Value)
							var fileInfo = fileInfos[item.basePath]
							if fileInfo == nil {
								fileInfo = AGKCacheFileInfo(basePath: item.basePath)
							}
							if let fi = fileInfo, (fi.keepIfExpired || fi.expiry > now) {
								totalSize += item.size
								items.append(item)
							}
							else {
								fileInfos.removeValue(forKey: item.basePath)
								try fm.removeItem(at: item.basePath)
							}
						}
						break
					}
				}
			}
		} catch {}

		items.sort {
			$0.modified.timeIntervalSinceReferenceDate <
			$1.modified.timeIntervalSinceReferenceDate
		}

		for item in items {
			if totalSize < maxBytes {
				break
			}
			fileInfos.removeValue(forKey: item.basePath)
			try? fm.removeItem(at: item.basePath)
			totalSize -= item.size
		}

		didAddToCacheSinceLastTrim = false
	}

	private class func writeInfoFile(basePath: URL, timeToLive: TimeInterval, keepIfExpired: Bool) {
		let path = basePath.appendingPathComponent("file.info", isDirectory: false)
		var s = keepIfExpired ? "1|" : "0|"
		s += "\(Int64(floor(Date.timeIntervalSinceReferenceDate + timeToLive)))"
		try? s.write(to: path, atomically: true, encoding: .utf8)
		fileInfos[basePath] = AGKCacheFileInfo(basePath: basePath)
		didAddToCacheSinceLastTrim = true
	}

}

private class AGKCacheFileInfo {

	let basePath: URL
	var expiry = TimeInterval(0)
	var keepIfExpired = false

	init?(basePath: URL) {
		self.basePath = basePath
		var success = false
		let path = basePath.appendingPathComponent("file.info", isDirectory: false)

		if let info = try? String(contentsOf: path, encoding: .utf8), info.count >= 3 {
			keepIfExpired = !info.hasPrefix("0")
			let time = info[info.index(info.startIndex, offsetBy: 2)...]
			if let value = TimeInterval(time) {
				expiry = value
				success = true
			}
		}

		if !success {
			return nil
		}
	}

}

private class AGKCacheItem {

	let basePath: URL
	let modified: Date
	let size: UInt64

	init(basePath: URL, modified: Date, size: UInt64) {
		self.basePath = basePath
		self.modified = modified
		self.size = size
	}

}

private class AGKCacheObserver {

	init() {
		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(onAppNotification),
			name: .UIApplicationDidBecomeActive, object: nil)
		nc.addObserver(self, selector: #selector(onAppNotification),
			name: .UIApplicationWillResignActive, object: nil)
		nc.addObserver(self, selector: #selector(onLowMemory),
			name: .UIApplicationDidReceiveMemoryWarning, object: nil)
	}

	@objc
	func onAppNotification() {
		if AGKCache.trimPolicy == .becomeOrResignActive {
			AGKCache.trim()
		}
	}

	@objc
	func onLowMemory() {
		AGKCache.basePaths.removeAll()
		AGKCache.fileInfos.removeAll()
	}

}
