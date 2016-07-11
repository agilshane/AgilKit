//
//  AGKNetRequest.swift
//  AgilKit
//
//  Created by Shane Meyer on 12/5/14.
//  Copyright © 2013-2016 Agilstream, LLC. All rights reserved.
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

protocol AGKNetRequestAuthenticationChallengeDelegate: class {
	func netRequest(netRequest: AGKNetRequest,
		connection: NSURLConnection,
		willSendRequestForAuthenticationChallenge challenge: NSURLAuthenticationChallenge)
}

protocol AGKNetRequestDelegate: class {
	func netRequestDidFinish(netRequest: AGKNetRequest, error: NSError?)
}

protocol AGKNetRequestProgressDelegate: class {
	func netRequest(netRequest: AGKNetRequest,
		didDownloadChunk chunkSize: Int64,
		totalBytesDownloaded: Int64,
		totalBytesExpected: Int64)
}

class AGKNetRequest {

	enum Method: String {
		case Delete = "DELETE"
		case Get = "GET"
		case Post = "POST"
		case Put = "PUT"
	}

	weak static var authenticationChallengeDelegate: AGKNetRequestAuthenticationChallengeDelegate?
	private static var cleanUpTime = NSTimeInterval(0)
	private weak var delegate: AGKNetRequestDelegate?
	private static var ignoreCount = 0
	private var ignoreInteraction = false
	private var impl: AGKNetRequestImpl?
	weak var progressDelegate: AGKNetRequestProgressDelegate?
	private(set) var responseBody = NSData()
	private var responseBodyMutable: NSMutableData?
	private(set) var responseHeaders = [String: String]()
	private(set) var responseURL: NSURL?
	private var showNetActivityIndicator = false
	private(set) var statusCode = 0
	private var totalBytesExpected = Int64(0)
	static var trustServerRegardlessForDebugging = false
	let url: String
	var userInfo: [String: Any]?

	private static let basePath: NSURL = {
		let fm = NSFileManager.defaultManager()
		let url = fm.URLsForDirectory(.CachesDirectory, inDomains: .UserDomainMask)[0]
		return url.URLByAppendingPathComponent("AGKNetRequest", isDirectory: true)!
	}()

	init?(delegate: AGKNetRequestDelegate,
		url: String,
		ignoreInteraction: Bool = false,
		showNetActivityIndicator: Bool = false,
		headers: [String: String]? = nil,
		body: NSData? = nil,
		method: Method = .Get,
		writeResponseToFile: Bool = false)
	{
		self.delegate = delegate
		self.url = url

		let nsurl = NSURL(string: url)

		if nsurl == nil {
			return nil
		}

		let req = NSMutableURLRequest(URL: nsurl!)
		req.HTTPMethod = method.rawValue

		if headers != nil {
			for (key, val) in headers! {
				req.setValue(val, forHTTPHeaderField: key)
			}
		}

		if body != nil {
			req.setValue("\(body!.length)", forHTTPHeaderField: "Content-Length")
			req.HTTPBody = body
		}

		// Create an instance of AGKNetRequestImpl to manage the connection, rather than
		// managing it ourselves, because the connection retains its delegate. By having the
		// impl code manage the connection, we (AGKNetRequest) can be released as a means to
		// trigger canceling the connection.

		impl = AGKNetRequestImpl(netRequest: self, urlRequest: req)

		if impl == nil {
			return nil
		}

		AGKNetRequest.cleanUpTempFiles()

		if writeResponseToFile {
			let now = NSDate.timeIntervalSinceReferenceDate()
			let fm = NSFileManager.defaultManager()

			while true {
				let filename = "\(now)_\(arc4random()).bin"
				let responseURL = AGKNetRequest.basePath.URLByAppendingPathComponent(
					filename, isDirectory: false)!

				if !responseURL.checkResourceIsReachableAndReturnError(nil) {
					self.responseURL = responseURL
					_ = try? fm.createDirectoryAtURL(AGKNetRequest.basePath,
						withIntermediateDirectories: true, attributes: nil)
					NSData().writeToURL(responseURL, atomically: true)
					break
				}
			}
		}

		self.ignoreInteraction = ignoreInteraction
		self.showNetActivityIndicator = showNetActivityIndicator

		if ignoreInteraction {
			AGKNetRequest.ignoreCount += 1
			if AGKNetRequest.ignoreCount == 1 {
				#if !NO_UIAPPLICATION
					UIApplication.sharedApplication().beginIgnoringInteractionEvents()
				#endif
			}
		}

		if showNetActivityIndicator {
			AGKNetActivityIndicator.show()
		}

		impl!.start()
	}

	deinit {
		impl?.cancel()
		impl = nil

		if ignoreInteraction {
			ignoreInteraction = false
			AGKNetRequest.ignoreCount -= 1

			if AGKNetRequest.ignoreCount < 0 {
				assertionFailure("AGKNetRequest has ended ignoring interaction too many times!")
				AGKNetRequest.ignoreCount = 0
			}

			if AGKNetRequest.ignoreCount == 0 {
				#if !NO_UIAPPLICATION
					UIApplication.sharedApplication().endIgnoringInteractionEvents()
				#endif
			}
		}

		if showNetActivityIndicator {
			showNetActivityIndicator = false
			AGKNetActivityIndicator.hide()
		}

		if let responseURL = self.responseURL {
			_ = try? NSFileManager.defaultManager().removeItemAtURL(responseURL)
		}
	}

	//
	// This generally won't do anything, unless a connection was abnormally terminated, such as
	// during a forced shutdown or crash of the app. We just want to make sure we don't have a
	// bunch of useless temp files laying around.
	//

	private class func cleanUpTempFiles() {
		let now = NSDate.timeIntervalSinceReferenceDate()

		if abs(now - cleanUpTime) >= NSTimeInterval(3600) {
			cleanUpTime = now
		}
		else {
			return
		}

		var pathsToNuke = [NSURL]()
		let fm = NSFileManager.defaultManager()

		if let contents = try? fm.contentsOfDirectoryAtURL(basePath,
			includingPropertiesForKeys: nil, options: [])
		{
			for path in contents {
				let filename = path.pathComponents!.last!
				let range = filename.rangeOfString("_")

				if range == nil || !filename.hasSuffix(".bin") {
					pathsToNuke.append(path)
				}
				else {
					let s = filename.substringToIndex(range!.startIndex) as NSString
					if abs(now - s.doubleValue) >= NSTimeInterval(24 * 3600) {
						pathsToNuke.append(path)
					}
				}
			}
		}

		for pathToNuke in pathsToNuke {
			_ = try? fm.removeItemAtURL(pathToNuke)
		}
	}

	private func finishUp(error: NSError?) {
		impl?.netRequest = nil
		impl = nil

		if ignoreInteraction {
			ignoreInteraction = false
			AGKNetRequest.ignoreCount -= 1

			if AGKNetRequest.ignoreCount < 0 {
				assertionFailure("AGKNetRequest has ended ignoring interaction too many times!")
				AGKNetRequest.ignoreCount = 0
			}

			if AGKNetRequest.ignoreCount == 0 {
				#if !NO_UIAPPLICATION
					UIApplication.sharedApplication().endIgnoringInteractionEvents()
				#endif
			}
		}

		if showNetActivityIndicator {
			showNetActivityIndicator = false
			AGKNetActivityIndicator.hide()
		}

		delegate?.netRequestDidFinish(self, error: error)
		delegate = nil
	}

	private func implDidFailWithError(error: NSError) {
		finishUp(error)
	}

	private func implDidFinishLoading() {
		finishUp(nil)
	}

	private func implDidReceiveData(data: NSData) {
		var totalBytesDownloaded = Int64(0)

		if let responseURL = self.responseURL {
			if let handle = try? NSFileHandle(forWritingToURL: responseURL) {
				handle.seekToEndOfFile()
				handle.writeData(data)
				totalBytesDownloaded = Int64(handle.offsetInFile)
			}
		}
		else {
			if responseBodyMutable == nil {
				if totalBytesExpected > 0 {
					responseBodyMutable = NSMutableData(capacity: Int(totalBytesExpected))
					responseBodyMutable!.appendData(data)
				}
				else {
					responseBodyMutable = NSMutableData(data: data)
				}
			}
			else {
				responseBodyMutable!.appendData(data)
			}

			responseBody = responseBodyMutable!
			totalBytesDownloaded = Int64(responseBody.length)
		}

		progressDelegate?.netRequest(self,
			didDownloadChunk: Int64(data.length),
			totalBytesDownloaded: totalBytesDownloaded,
			totalBytesExpected: totalBytesExpected)
	}

	private func implDidReceiveResponse(response: NSURLResponse) {
		if let r = response as? NSHTTPURLResponse {
			statusCode = r.statusCode

			for (key, val) in r.allHeaderFields as! [String: String] {
				responseHeaders[key] = val

				if key.lowercaseString == "content-length" {
					totalBytesExpected = (val as NSString).longLongValue
				}
			}
		}
	}

}

class AGKNetRequestImpl: NSObject, NSURLConnectionDataDelegate {

	private var cxn: NSURLConnection?
	private weak var netRequest: AGKNetRequest?

	private init?(netRequest: AGKNetRequest, urlRequest: NSURLRequest) {
		super.init()
		self.netRequest = netRequest

		// This adds one to our retain count.
		cxn = NSURLConnection(request: urlRequest, delegate: self, startImmediately: false)

		if cxn == nil {
			return nil
		}
	}

	deinit {
		cancel()
	}

	private func cancel() {
		netRequest = nil
		cxn?.cancel()
		cxn = nil
	}

	func connection(connection: NSURLConnection, didFailWithError error: NSError) {
		netRequest?.implDidFailWithError(error)
	}

	func connection(connection: NSURLConnection, didReceiveData data: NSData) {
		netRequest?.implDidReceiveData(data)
	}

	func connection(connection: NSURLConnection, didReceiveResponse response: NSURLResponse) {
		netRequest?.implDidReceiveResponse(response)
	}

	func connection(connection: NSURLConnection,
		willSendRequestForAuthenticationChallenge challenge: NSURLAuthenticationChallenge)
	{
		if let authChallengeDelegate = AGKNetRequest.authenticationChallengeDelegate {
			authChallengeDelegate.netRequest(netRequest!,
				connection: connection,
				willSendRequestForAuthenticationChallenge: challenge)
		}
		else if AGKNetRequest.trustServerRegardlessForDebugging &&
			challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust
		{
			if let serverTrust = challenge.protectionSpace.serverTrust {
				challenge.sender?.useCredential(NSURLCredential(forTrust: serverTrust),
					forAuthenticationChallenge: challenge)
			}
		}
		else {
			challenge.sender?.performDefaultHandlingForAuthenticationChallenge?(challenge)
		}
	}

	func connectionDidFinishLoading(connection: NSURLConnection) {
		netRequest?.implDidFinishLoading()
	}

	private func start() {
		cxn!.scheduleInRunLoop(NSRunLoop.mainRunLoop(), forMode: NSRunLoopCommonModes)
		cxn!.start()
	}

}
