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

protocol AGKNetRequestDelegate: class {
	func netRequestDidFinish(_ netRequest: AGKNetRequest, error: Error?)
}

protocol AGKNetRequestProgressDelegate: class {
	func netRequest(_ netRequest: AGKNetRequest, didDownloadChunk chunkSize: Int64,
		totalBytesDownloaded: Int64, totalBytesExpected: Int64)
}

class AGKNetRequest {

	enum Method: String {
		case delete = "DELETE"
		case get = "GET"
		case post = "POST"
		case put = "PUT"
	}

	private static var cleanUpTime = TimeInterval(0)
	weak var delegate: AGKNetRequestDelegate?
	private static var ignoreCount = 0
	private var ignoreInteraction = false
	private var impl: AGKNetRequestImpl?
	weak var progressDelegate: AGKNetRequestProgressDelegate?
	private(set) var responseBody = Data()
	private var responseBodyMutable: Data?
	private(set) var responseHeaders = [String: String]()
	private(set) var responseURL: URL?
	private var showNetActivityIndicator = false
	private(set) var statusCode = 0
	private var totalBytesExpected = Int64(0)
	let url: URL
	var userInfo: [String: Any]?

	private static let basePath: URL = {
		let url = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]
		return url.appendingPathComponent("AGKNetRequest", isDirectory: true)
	}()

	init(
		delegate: AGKNetRequestDelegate?,
		url: URL,
		ignoreInteraction: Bool = false,
		showNetActivityIndicator: Bool = false,
		headers: [String: String]? = nil,
		body: Data? = nil,
		method: Method = .get,
		writeResponseToFile: Bool = false)
	{
		self.delegate = delegate
		self.ignoreInteraction = ignoreInteraction
		self.showNetActivityIndicator = showNetActivityIndicator
		self.url = url

		AGKNetRequest.cleanUpTempFiles()

		var req = URLRequest(url: url)
		req.httpMethod = method.rawValue

		if let headers = headers {
			for (key, val) in headers {
				req.setValue(val, forHTTPHeaderField: key)
			}
		}

		if let body = body {
			req.setValue("\(body.count)", forHTTPHeaderField: "Content-Length")
			req.httpBody = body
		}

		if writeResponseToFile {
			let now = Date.timeIntervalSinceReferenceDate
			while true {
				let filename = "\(now)_\(arc4random()).bin"
				let responseURL = AGKNetRequest.basePath.appendingPathComponent(
					filename, isDirectory: false)
				let exists = (try? responseURL.checkResourceIsReachable()) ?? false
				if !exists {
					self.responseURL = responseURL
					try? FileManager.default.createDirectory(at: AGKNetRequest.basePath,
						withIntermediateDirectories: true, attributes: nil)
					try? Data().write(to: responseURL, options: [.atomic])
					break
				}
			}
		}

		if ignoreInteraction {
			AGKNetRequest.ignoreCount += 1
			if AGKNetRequest.ignoreCount == 1 {
				#if !NO_UIAPPLICATION
					UIApplication.shared.beginIgnoringInteractionEvents()
				#endif
			}
		}

		if showNetActivityIndicator {
			AGKNetActivityIndicator.show()
		}

		// Create an instance of AGKNetRequestImpl to manage the connection, rather than
		// managing it ourselves, because the connection retains its delegate. By having the
		// impl code manage the connection, we (AGKNetRequest) can be released as a means to
		// trigger canceling the connection.

		impl = AGKNetRequestImpl(parent: self, urlRequest: req)
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
					UIApplication.shared.endIgnoringInteractionEvents()
				#endif
			}
		}

		if showNetActivityIndicator {
			showNetActivityIndicator = false
			AGKNetActivityIndicator.hide()
		}

		if let responseURL = self.responseURL {
			try? FileManager.default.removeItem(at: responseURL)
		}
	}

	//
	// This generally won't do anything, unless a connection was abnormally terminated, such as
	// during a forced shutdown or crash of the app. We just want to make sure we don't have a
	// bunch of useless temp files laying around.
	//

	private class func cleanUpTempFiles() {
		let now = Date.timeIntervalSinceReferenceDate

		if abs(now - cleanUpTime) >= TimeInterval(3600) {
			cleanUpTime = now
		}
		else {
			return
		}

		var pathsToNuke = [URL]()
		let fm = FileManager.default

		if let contents = try? fm.contentsOfDirectory(at: basePath,
			includingPropertiesForKeys: nil, options: [])
		{
			for path in contents {
				guard let filename = path.pathComponents.last else { continue }
				if filename.hasSuffix(".bin"), let range = filename.range(of: "_") {
					let s = filename.substring(to: range.lowerBound)
					if let val = TimeInterval(s), abs(now - val) >= TimeInterval(24 * 3600) {
						pathsToNuke.append(path)
					}
				}
				else {
					pathsToNuke.append(path)
				}
			}
		}

		for pathToNuke in pathsToNuke {
			try? fm.removeItem(at: pathToNuke)
		}
	}

	fileprivate func implDidFinish(error: Error?) {
		impl?.parent = nil
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
					UIApplication.shared.endIgnoringInteractionEvents()
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

	fileprivate func implDidReceive(data: Data) {
		var totalBytesDownloaded = Int64(0)

		if let responseURL = self.responseURL {
			if let handle = try? FileHandle(forWritingTo: responseURL) {
				handle.seekToEndOfFile()
				handle.write(data)
				totalBytesDownloaded = Int64(handle.offsetInFile)
			}
		}
		else {
			if responseBodyMutable == nil {
				if totalBytesExpected > 0 {
					responseBodyMutable = Data(capacity: Int(totalBytesExpected))
					responseBodyMutable?.append(data)
				}
				else {
					responseBodyMutable = data
				}
			}
			else {
				responseBodyMutable?.append(data)
			}

			responseBody = responseBodyMutable ?? Data()
			totalBytesDownloaded = Int64(responseBody.count)
		}

		progressDelegate?.netRequest(self, didDownloadChunk: Int64(data.count),
			totalBytesDownloaded: totalBytesDownloaded, totalBytesExpected: totalBytesExpected)
	}

	fileprivate func implDidReceive(response: URLResponse) {
		guard let r = response as? HTTPURLResponse else { return }
		statusCode = r.statusCode
		guard let allHeaderFields = r.allHeaderFields as? [String: String] else { return }
		for (key, val) in allHeaderFields {
			responseHeaders[key] = val
			if key.lowercased() == "content-length" {
				if let contentLength = Int64(val) {
					totalBytesExpected = contentLength
				}
			}
		}
	}

}

private class AGKNetRequestImpl {

	weak var parent: AGKNetRequest?
	var task: URLSessionTask?

	init(parent: AGKNetRequest, urlRequest: URLRequest) {
		self.parent = parent

		let nc = NotificationCenter.default
		nc.addObserver(self, selector: #selector(onDidComplete(_:)),
			name: AGKNetRequestShared.eventDidComplete, object: nil)
		nc.addObserver(self, selector: #selector(onDidReceiveData(_:)),
			name: AGKNetRequestShared.eventDidReceiveData, object: nil)
		nc.addObserver(self, selector: #selector(onDidReceiveResponse(_:)),
			name: AGKNetRequestShared.eventDidReceiveResponse, object: nil)

		task = AGKNetRequestShared.shared.session?.dataTask(with: urlRequest)
		task?.resume()
	}

	deinit {
		cancel()
	}

	func cancel() {
		NotificationCenter.default.removeObserver(self)
		parent = nil
		task?.cancel()
		task = nil
	}

	@objc
	func onDidComplete(_ notification: Notification) {
		guard let userInfo = notification.userInfo else { return }
		guard let task = userInfo["task"] as? URLSessionTask, task == self.task else { return }
		parent?.implDidFinish(error: userInfo["error"] as? Error)
	}

	@objc
	func onDidReceiveData(_ notification: Notification) {
		guard let userInfo = notification.userInfo else { return }
		guard let task = userInfo["task"] as? URLSessionTask, task == self.task else { return }
		guard let data = userInfo["data"] as? Data else { return }
		parent?.implDidReceive(data: data)
	}

	@objc
	func onDidReceiveResponse(_ notification: Notification) {
		guard let userInfo = notification.userInfo else { return }
		guard let task = userInfo["task"] as? URLSessionTask, task == self.task else { return }
		guard let response = userInfo["response"] as? URLResponse else { return }
		parent?.implDidReceive(response: response)
	}

}

private class AGKNetRequestShared: NSObject, URLSessionDataDelegate {

	static let eventDidComplete = Notification.Name("AGKNetRequestSharedDidComplete")
	static let eventDidReceiveData = Notification.Name("AGKNetRequestSharedDidReceiveData")
	static let eventDidReceiveResponse = Notification.Name("AGKNetRequestSharedDidReceiveResponse")
	var session: URLSession?
	static let shared = AGKNetRequestShared()

	override init() {
		super.init()
		session = URLSession(configuration: URLSessionConfiguration.default,
			delegate: self, delegateQueue: nil)
	}

	func urlSession(_ session: URLSession, task: URLSessionTask,
		didCompleteWithError error: Error?)
	{
		var userInfo: [String: Any] = ["task": task]
		if let error = error {
			userInfo["error"] = error
		}
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: AGKNetRequestShared.eventDidComplete,
				object: nil, userInfo: userInfo)
		}
	}

	func urlSession(_ session: URLSession, dataTask: URLSessionDataTask, didReceive data: Data) {
		let userInfo: [String: Any] = ["data": data, "task": dataTask]
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: AGKNetRequestShared.eventDidReceiveData,
				object: nil, userInfo: userInfo)
		}
	}

	func urlSession(_ session: URLSession,
		dataTask: URLSessionDataTask,
		didReceive response: URLResponse,
		completionHandler: @escaping (URLSession.ResponseDisposition) -> Void)
	{
		let userInfo = ["response": response, "task": dataTask]
		DispatchQueue.main.async {
			NotificationCenter.default.post(name: AGKNetRequestShared.eventDidReceiveResponse,
				object: nil, userInfo: userInfo)
		}
		completionHandler(.allow)
	}

}
