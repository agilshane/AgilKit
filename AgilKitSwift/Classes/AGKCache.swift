//
//  AGKCache.swift
//  AgilKit
//
//  Created by Shane Meyer on 6/6/15.
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

import UIKit

protocol AGKCacheDelegate: class {
	func cacheDidFinish(cache: AGKCache, error: NSError?)
}

class AGKCache: AGKNetRequestDelegate {

	enum RequestType {
		case Data, Image
	}

	enum TrimPolicy {
		case BecomeOrResignActive, None
	}

	private static var basePaths = [String: NSURL]()
	private(set) var data: NSData?
	private weak var delegate: AGKCacheDelegate?
	private static var didAddToCacheSinceLastTrim = false
	private static var fileInfos = [NSURL: AGKCacheFileInfo]()
	private(set) var image: UIImage?
	private let keepIfExpired: Bool
	private static var maxBytes = UInt64(10 * 1024 * 1024)
	private var netRequest: AGKNetRequest?
	private static let observer = AGKCacheObserver()
	private let requestType: RequestType
	private let timeToLive: NSTimeInterval
	private static var trimPolicy = TrimPolicy.BecomeOrResignActive
	let url: String

	private static let rootPath: NSURL = {
		let fm = NSFileManager.defaultManager()
		let url = fm.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0]
		return url.URLByAppendingPathComponent("AGKCache", isDirectory: true)!
	}()

	init?(delegate: AGKCacheDelegate,
		url: String,
		requestType: RequestType,
		timeToLive: NSTimeInterval = NSTimeInterval(3600 * 24 * 365),
		keepIfExpired: Bool = true)
	{
		AGKCache.observer // Create the singleton observer in case initialize() wasn't called.

		self.delegate = delegate
		self.keepIfExpired = keepIfExpired
		self.requestType = requestType
		self.timeToLive = timeToLive
		self.url = url

		netRequest = AGKNetRequest(delegate: self, url: url)

		if netRequest == nil {
			return nil
		}
	}

	class func addData(data: NSData, url: String, timeToLive: NSTimeInterval, keepIfExpired: Bool) {
		let basePath = basePathForURL(url)
		_ = try? NSFileManager.defaultManager().createDirectoryAtURL(basePath,
			withIntermediateDirectories: true, attributes: nil)
		data.writeToURL(basePath.URLByAppendingPathComponent(
			"file.bin", isDirectory: false)!, atomically: true)
		writeInfoFileWithBasePath(basePath, timeToLive: timeToLive, keepIfExpired: keepIfExpired)
	}

	private class func addImageData(data: NSData, ext: String, url: String,
		timeToLive: NSTimeInterval, keepIfExpired: Bool)
	{
		let basePath = basePathForURL(url)
		_ = try? NSFileManager.defaultManager().createDirectoryAtURL(basePath,
			withIntermediateDirectories: true, attributes: nil)
		let scale = UIScreen.mainScreen().scale
		let filename =
			scale == CGFloat(3) ? "file@3x" :
			scale == CGFloat(2) ? "file@2x" : "file"
		let path = basePath.URLByAppendingPathComponent(filename + ext, isDirectory: false)!
		data.writeToURL(path, atomically: true)
		writeInfoFileWithBasePath(basePath, timeToLive: timeToLive, keepIfExpired: keepIfExpired)
	}

	class func addJPEGData(data: NSData, url: String,
		timeToLive: NSTimeInterval, keepIfExpired: Bool)
	{
		addImageData(data, ext: ".jpg", url: url, timeToLive: timeToLive,
			keepIfExpired: keepIfExpired)
	}

	class func addPNGData(data: NSData, url: String,
		timeToLive: NSTimeInterval, keepIfExpired: Bool)
	{
		addImageData(data, ext: ".png", url: url, timeToLive: timeToLive,
			keepIfExpired: keepIfExpired)
	}

	private class func basePathForURL(url: String) -> NSURL {
		if let path = basePaths[url] {
			return path
		}
		let data = AGKCrypto.sha1(url.dataUsingEncoding(NSUTF8StringEncoding)!)
		let path = rootPath.URLByAppendingPathComponent(
			AGKHex.stringFromData(data), isDirectory: true)!
		basePaths[url] = path
		return path
	}

	class func dataWithURL(url: String) -> NSData? {
		let basePath = basePathForURL(url)
		let fm = NSFileManager.defaultManager()
		if let contents = try? fm.contentsOfDirectoryAtURL(basePath,
			includingPropertiesForKeys: nil, options: [])
		{
			for name in contents {
				if let ext = name.pathExtension where ext == "jpg" || ext == "png" || ext == "bin" {
					return NSData(contentsOfURL: name)
				}
			}
		}
		return nil
	}

	class func deleteFileWithURL(url: String) {
		let basePath = basePathForURL(url)
		fileInfos.removeValueForKey(basePath)
		_ = try? NSFileManager.defaultManager().removeItemAtURL(basePath)
	}

	class func fileExistsWithURL(url: String) -> Bool {
		let path = basePathForURL(url).URLByAppendingPathComponent("file.info", isDirectory: false)!
		return path.checkResourceIsReachableAndReturnError(nil)
	}

	class func fileExpiredWithURL(url: String) -> Bool {
		let basePath = basePathForURL(url)
		if let fileInfo = fileInfos[basePath] {
			return fileInfo.expiry <= NSDate.timeIntervalSinceReferenceDate()
		}
		if let fileInfo = AGKCacheFileInfo(basePath: basePath) {
			fileInfos[basePath] = fileInfo
			return fileInfo.expiry <= NSDate.timeIntervalSinceReferenceDate()
		}
		return false
	}

	class func imagePathWithURL(url: String) -> NSURL? {
		let basePath = basePathForURL(url)
		let scale = UIScreen.mainScreen().scale
		let x = (scale == CGFloat(1)) ? "" : "@\(Int(scale))x"
		let path = basePath.URLByAppendingPathComponent("file" + x, isDirectory: false)!
		do {
			let nsurl = path.URLByAppendingPathExtension("jpg")!
			if nsurl.checkResourceIsReachableAndReturnError(nil) {
				return nsurl
			}
		}
		do {
			let nsurl = path.URLByAppendingPathExtension("png")!
			if nsurl.checkResourceIsReachableAndReturnError(nil) {
				return nsurl
			}
		}
		return nil
	}

	class func imageWithURL(url: String) -> UIImage? {
		if let path = imagePathWithURL(url)?.path {
			return UIImage(contentsOfFile: path)
		}
		return nil
	}

	class func initialize(maxBytes: UInt64 = 10 * 1024 * 1024,
		trimPolicy: TrimPolicy = .BecomeOrResignActive)
	{
		self.maxBytes = maxBytes
		observer // Create the singleton observer.
	}

	func netRequestDidFinish(netRequest: AGKNetRequest, error: NSError?) {
		if error == nil && netRequest.statusCode == 200 {
			AGKCache.deleteFileWithURL(url)
			data = netRequest.responseBody

			switch requestType {
				case .Data:
					AGKCache.addData(netRequest.responseBody, url: url,
						timeToLive: timeToLive, keepIfExpired: keepIfExpired)

				case .Image:
					var isJPEG = false
					var isPNG = false

					for (key, val) in netRequest.responseHeaders {
						if key.lowercaseString == "content-type" {
							let valLower = val.lowercaseString
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
						let urlLower = url.lowercaseString
						if urlLower.rangeOfString(".jpg") != nil ||
							urlLower.rangeOfString(".jpeg") != nil
						{
							isJPEG = true
						}
						else if urlLower.rangeOfString(".png") != nil {
							isPNG = true
						}
					}

					if isJPEG || isPNG {
						let scale = UIScreen.mainScreen().scale
						if let image = UIImage(data: netRequest.responseBody, scale: scale) {
							self.image = image
							if isJPEG {
								AGKCache.addJPEGData(netRequest.responseBody, url: url,
									timeToLive: timeToLive, keepIfExpired: keepIfExpired)
							}
							else {
								AGKCache.addPNGData(netRequest.responseBody, url: url,
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

		let fm = NSFileManager.defaultManager()
		var items = [AGKCacheItem]()
		let now = NSDate.timeIntervalSinceReferenceDate()
		var totalSize = UInt64(0)

		do {
			for basePath in try fm.contentsOfDirectoryAtURL(rootPath,
				includingPropertiesForKeys: nil, options: [])
			{
				if let contents = try? fm.contentsOfDirectoryAtURL(basePath,
					includingPropertiesForKeys: [NSURLContentModificationDateKey, NSURLFileSizeKey],
					options: [])
				{
					for path in contents {
						if let ext = path.pathExtension where ext == "jpg" ||
							ext == "png" || ext == "bin"
						{
							var obj0: AnyObject?
							var obj1: AnyObject?
							try path.getResourceValue(&obj0, forKey: NSURLContentModificationDateKey)
							try path.getResourceValue(&obj1, forKey: NSURLFileSizeKey)
							if let modified = obj0 as? NSDate, size = obj1 as? NSNumber {
								let item = AGKCacheItem(basePath: basePath, modified: modified,
									size: size.unsignedLongLongValue)
								var fileInfo = fileInfos[item.basePath]
								if fileInfo == nil {
									fileInfo = AGKCacheFileInfo(basePath: item.basePath)
								}
								if let fi = fileInfo where fi.keepIfExpired || fi.expiry > now {
									totalSize += item.size
									items.append(item)
								}
								else {
									fileInfos.removeValueForKey(item.basePath)
									try fm.removeItemAtURL(item.basePath)
								}
							}
							break
						}
					}
				}
			}
		} catch {}

		items.sortInPlace {
			$0.modified.timeIntervalSinceReferenceDate <
			$1.modified.timeIntervalSinceReferenceDate
		}

		for item in items {
			if totalSize < maxBytes {
				break
			}
			fileInfos.removeValueForKey(item.basePath)
			_ = try? fm.removeItemAtURL(item.basePath)
			totalSize -= item.size
		}

		didAddToCacheSinceLastTrim = false
	}

	private class func writeInfoFileWithBasePath(basePath: NSURL,
		timeToLive: NSTimeInterval, keepIfExpired: Bool)
	{
		let path = basePath.URLByAppendingPathComponent("file.info", isDirectory: false)!
		var s = keepIfExpired ? "1|" : "0|"
		s += "\(Int64(floor(NSDate.timeIntervalSinceReferenceDate() + timeToLive)))"
		_ = try? s.writeToURL(path, atomically: true, encoding: NSUTF8StringEncoding)
		fileInfos[basePath] = AGKCacheFileInfo(basePath: basePath)
		didAddToCacheSinceLastTrim = true
	}

}

private class AGKCacheFileInfo {

	let basePath: NSURL
	var expiry = NSTimeInterval(0)
	var keepIfExpired = false

	init?(basePath: NSURL) {
		self.basePath = basePath
		var success = false
		let path = basePath.URLByAppendingPathComponent("file.info", isDirectory: false)!

		if let info = try? String(contentsOfURL: path, encoding: NSUTF8StringEncoding)
			where info.characters.count >= 3
		{
			keepIfExpired = !info.hasPrefix("0")
			if let time = info.substringFromIndex(info.startIndex.advancedBy(2)) as NSString? {
				expiry = NSTimeInterval(time.longLongValue)
				success = true
			}
		}

		if !success {
			return nil
		}
	}

}

private class AGKCacheItem {

	let basePath: NSURL
	let modified: NSDate
	let size: UInt64

	init(basePath: NSURL, modified: NSDate, size: UInt64) {
		self.basePath = basePath
		self.modified = modified
		self.size = size
	}

}

class AGKCacheObserver: NSObject {

	override init() {
		super.init()
		let nc = NSNotificationCenter.defaultCenter()
		nc.addObserver(self, selector: #selector(onAppNotification),
			name: UIApplicationDidBecomeActiveNotification, object: nil)
		nc.addObserver(self, selector: #selector(onAppNotification),
			name: UIApplicationWillResignActiveNotification, object: nil)
		nc.addObserver(self, selector: #selector(onLowMemory),
			name: UIApplicationDidReceiveMemoryWarningNotification, object: nil)
	}

	func onAppNotification() {
		if AGKCache.trimPolicy == .BecomeOrResignActive {
			AGKCache.trim()
		}
	}

	func onLowMemory() {
		AGKCache.basePaths.removeAll()
		AGKCache.fileInfos.removeAll()
	}

}
