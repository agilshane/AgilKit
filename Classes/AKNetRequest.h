//
//  AKNetRequest.h
//  AgilKit
//
//  Created by Shane Meyer on 3/27/13.
//  Copyright (c) 2013 Agilstream, LLC.
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

#import <Foundation/Foundation.h>

typedef enum {
	AKNetRequestMethodDelete,
	AKNetRequestMethodGet,
	AKNetRequestMethodPost,
	AKNetRequestMethodPut
} AKNetRequestMethod;

@class AKNetRequest;

//
// AKNetRequestAuthenticationChallengeDelegate
//

@protocol AKNetRequestAuthenticationChallengeDelegate

- (void)
	netRequest:(AKNetRequest *)request
	connection:(NSURLConnection *)connection
	willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end

//
// AKNetRequestDelegate
//

@protocol AKNetRequestDelegate

@required

- (void)netRequestDidFinish:(AKNetRequest *)request error:(NSError *)error;

@optional

- (void)
	netRequest:(AKNetRequest *)request
	didDownloadChunk:(long long)chunkSize
	totalBytesDownloaded:(long long)totalBytesDownloaded
	totalBytesExpected:(long long)totalBytesExpected;

@end

//
// AKNetRequest
//

@interface AKNetRequest : NSObject {
	@private __weak id <AKNetRequestDelegate> m_delegate;
	@private BOOL m_ignoreInteraction;
	@private NSMutableData *m_responseBody;
	@private NSDictionary *m_responseHeaders;
	@private NSString *m_responsePath;
	@private BOOL m_showNetActivityIndicator;
	@private int m_statusCode;
	@private long long m_totalBytesExpected;
	@private NSString *m_url;
	@private NSDictionary *m_userInfo;
}

@property (nonatomic, readonly) NSData *responseBody;
@property (nonatomic, readonly) NSDictionary *responseHeaders;
@property (nonatomic, readonly) NSString *responsePath;
@property (nonatomic, readonly) int statusCode;
@property (nonatomic, readonly) NSString *url;
@property (nonatomic, strong) NSDictionary *userInfo;

//
// A convenience method configured as follows:
//    ignoreInteraction:NO
//    showNetActivityIndicator:NO
//    headers:nil
//    body:nil
//    method:AKNetRequestMethodGet
//    writeResponseToFile:NO
//
- (id)
	initWithDelegate:(id <AKNetRequestDelegate>)delegate
	url:(NSString *)url;

//
// A convenience method configured as follows:
//    headers:nil
//    body:nil
//    method:AKNetRequestMethodGet
//    writeResponseToFile:NO
//
- (id)
	initWithDelegate:(id <AKNetRequestDelegate>)delegate
	url:(NSString *)url
	ignoreInteraction:(BOOL)ignoreInteraction
	showNetActivityIndicator:(BOOL)showNetActivityIndicator;

//
// Creates a network request.
//
// The ignoreInteraction parameter provides a convenient way to disable application interaction
// events for the life of the request.
//
// The showNetActivityIndicator parameter provides a convenient way to show the network
// activity indicator in the application status bar for the life of the request.  It utilizes
// AKNetActivityIndicator, which implements its show/hide logic using a reference count,
// similar to how UIApplication manages ignoring interaction events.
//
// The headers parameter represents additional HTTP header key/value pairs to add to the
// request.  A Content-Length header is automatically added to the request if the body isn't
// nil.
//
// A YES value for writeResponseToFile causes the response to be written to a temporary file.
// The path of the file can be discovered by inspecting the responsePath property.  Once the
// request has finished, the caller should either move or copy the file to another location.
//
- (id)
	initWithDelegate:(id <AKNetRequestDelegate>)delegate
	url:(NSString *)url
	ignoreInteraction:(BOOL)ignoreInteraction
	showNetActivityIndicator:(BOOL)showNetActivityIndicator
	headers:(NSDictionary *)headers
	body:(NSData *)body
	method:(AKNetRequestMethod)method
	writeResponseToFile:(BOOL)writeResponseToFile;

+ (void)setAuthenticationChallengeDelegate:(id <AKNetRequestAuthenticationChallengeDelegate>)delegate;

+ (void)setTrustServerRegardlessForDebugging:(BOOL)trust;

@end
