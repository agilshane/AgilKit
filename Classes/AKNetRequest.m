//
//  AKNetRequest.m
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

#import "AKNetRequest.h"
#import "AKNetActivityIndicator.h"


static NSString *m_basePath;


//
// AKNetRequestImpl
//


@protocol AKNetRequestImplDelegate

- (void)implDidFailWithError:(NSError *)error;
- (void)implDidFinishLoading;
- (void)implDidReceiveData:(NSData *)data;
- (void)implDidReceiveResponse:(NSURLResponse *)response;

@end

@interface AKNetRequestImpl : NSObject <NSURLConnectionDataDelegate> {
	@private NSURLConnection *m_cxn;
	@private id <AKNetRequestImplDelegate> m_delegate;
}

- (void)cancel;
- (id)initWithDelegate:(id <AKNetRequestImplDelegate>)delegate request:(NSURLRequest *)request;
- (void)setDelegateToNil;
- (void)start;

@end


@implementation AKNetRequestImpl


- (void)cancel {
	m_delegate = nil;

	if (m_cxn != nil) {
		NSURLConnection *cxn = m_cxn;
		m_cxn = nil;
		[cxn cancel];
		[cxn release];
	}
}


- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
	[m_delegate implDidFailWithError:error];
}


- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
	[m_delegate implDidReceiveData:data];
}


- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
	[m_delegate implDidReceiveResponse:response];
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
	[m_delegate implDidFinishLoading];
}


- (void)dealloc {
	[self cancel];
	[super dealloc];
}


- (id)initWithDelegate:(id <AKNetRequestImplDelegate>)delegate request:(NSURLRequest *)request {
	if (request == nil) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		// This adds one to our retain count.
		m_cxn = [[NSURLConnection alloc] initWithRequest:request
			delegate:self startImmediately:NO];

		if (m_cxn == nil) {
			[self release];
			return nil;
		}
	}

	return self;
}


- (void)setDelegateToNil {
	m_delegate = nil;
}


- (void)start {
	[m_cxn scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
	[m_cxn start];
}


@end


//
// AKNetRequest
//


@interface AKNetRequest() <AKNetRequestImplDelegate> {
	@private AKNetRequestImpl *m_impl;
}

- (void)cleanUpTempFiles;
- (void)finishUpWithError:(NSError *)error;

@end


@implementation AKNetRequest


@synthesize responseBody = m_responseBody;
@synthesize responseHeaders = m_responseHeaders;
@synthesize responsePath = m_responsePath;
@synthesize statusCode = m_statusCode;
@synthesize url = m_url;


//
// This generally won't do anything, unless a connection was abnormally terminated, such as
// during a forced shutdown or crash of the app.  We just want to make sure we don't have a
// bunch of useless temp files laying around.
//
- (void)cleanUpTempFiles {
	static NSTimeInterval time = 0;
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

	if (ABS(now - time) >= 3600) {
		time = now;
	}
	else {
		return;
	}

	NSMutableArray *pathsToNuke = [NSMutableArray array];
	NSFileManager *fm = [NSFileManager defaultManager];

	for (NSString *fileName in [fm contentsOfDirectoryAtPath:m_basePath error:nil]) {
		NSString *path = [m_basePath stringByAppendingPathComponent:fileName];
		NSRange range = [fileName rangeOfString:@"_"];

		if (range.location == NSNotFound || ![fileName hasSuffix:@".bin"]) {
			[pathsToNuke addObject:path];
		}
		else {
			NSString *s = [fileName substringToIndex:range.location];
			NSTimeInterval fileTime = s.doubleValue;

			if (ABS(now - fileTime) >= 24 * 3600) {
				[pathsToNuke addObject:path];
			}
		}
	}

	for (NSString *pathToNuke in pathsToNuke) {
		[fm removeItemAtPath:pathToNuke error:nil];
	}
}


- (void)dealloc {
	if (m_impl != nil) {
		[m_impl cancel];
		[m_impl release];
		m_impl = nil;
	}

	if (m_ignoreInteraction) {
		m_ignoreInteraction = NO;
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}

	if (m_showNetActivityIndicator) {
		m_showNetActivityIndicator = NO;
		[AKNetActivityIndicator hide];
	}

	if (m_responsePath != nil) {
		[[NSFileManager defaultManager] removeItemAtPath:m_responsePath error:nil];
	}

	[m_responseBody release];
	[m_responseHeaders release];
	[m_responsePath release];
	[m_url release];

	[super dealloc];
}


- (void)finishUpWithError:(NSError *)error {
	[m_impl setDelegateToNil];
	[m_impl autorelease];
	m_impl = nil;

	if (m_ignoreInteraction) {
		m_ignoreInteraction = NO;
		[[UIApplication sharedApplication] endIgnoringInteractionEvents];
	}

	if (m_showNetActivityIndicator) {
		m_showNetActivityIndicator = NO;
		[AKNetActivityIndicator hide];
	}

	[m_delegate netRequestDidFinish:self error:error];
	m_delegate = nil;
}


- (void)implDidFailWithError:(NSError *)error {
	[self finishUpWithError:error];
}


- (void)implDidFinishLoading {
	[self finishUpWithError:nil];
}


- (void)implDidReceiveData:(NSData *)data {
	long long totalBytesDownloaded = 0;

	if (m_responsePath != nil) {
		@autoreleasepool {
			NSFileHandle *handle = [NSFileHandle fileHandleForWritingAtPath:m_responsePath];
			[handle seekToEndOfFile];
			[handle writeData:data];
			totalBytesDownloaded = handle.offsetInFile;
		}
	}
	else {
		if (m_responseBody == nil) {
			if (m_totalBytesExpected > 0) {
				m_responseBody = [[NSMutableData alloc] initWithCapacity:m_totalBytesExpected];
				[m_responseBody appendData:data];
			}
			else {
				m_responseBody = [[NSMutableData alloc] initWithData:data];
			}
		}
		else {
			[m_responseBody appendData:data];
		}

		totalBytesDownloaded = m_responseBody.length;
	}

	id delegate = m_delegate;

	if (delegate != nil && [delegate respondsToSelector:
		@selector(netRequest:didDownloadChunk:totalBytesDownloaded:totalBytesExpected:)])
	{
		[m_delegate
			netRequest:self
			didDownloadChunk:data.length
			totalBytesDownloaded:totalBytesDownloaded
			totalBytesExpected:m_totalBytesExpected];
	}
}


- (void)implDidReceiveResponse:(NSURLResponse *)response {
	if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
		NSHTTPURLResponse *r = (NSHTTPURLResponse *)response;
		m_statusCode = r.statusCode;

		[m_responseHeaders release];
		m_responseHeaders = [r.allHeaderFields retain];

		for (NSString *key in m_responseHeaders) {
			if ([key.lowercaseString isEqualToString:@"content-length"]) {
				NSString *value = [m_responseHeaders objectForKey:key];
				m_totalBytesExpected = value.longLongValue;
				break;
			}
		}
	}
}


+ (void)initialize {
	NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
		NSUserDomainMask, YES) objectAtIndex:0];
	m_basePath = [[path stringByAppendingPathComponent:@"AKNetRequest"] retain];
}


- (id)
	initWithDelegate:(id <AKNetRequestDelegate>)delegate
	url:(NSString *)url
{
	return [self
		initWithDelegate:delegate
		url:url
		ignoreInteraction:NO
		showNetActivityIndicator:NO
		headers:nil
		body:nil
		method:AKNetRequestMethodGet
		writeResponseToFile:NO];
}


- (id)
	initWithDelegate:(id <AKNetRequestDelegate>)delegate
	url:(NSString *)url
	ignoreInteraction:(BOOL)ignoreInteraction
	showNetActivityIndicator:(BOOL)showNetActivityIndicator
{
	return [self
		initWithDelegate:delegate
		url:url
		ignoreInteraction:ignoreInteraction
		showNetActivityIndicator:showNetActivityIndicator
		headers:nil
		body:nil
		method:AKNetRequestMethodGet
		writeResponseToFile:NO];
}


- (id)
	initWithDelegate:(id <AKNetRequestDelegate>)delegate
	url:(NSString *)url
	ignoreInteraction:(BOOL)ignoreInteraction
	showNetActivityIndicator:(BOOL)showNetActivityIndicator
	headers:(NSDictionary *)headers
	body:(NSData *)body
	method:(AKNetRequestMethod)method
	writeResponseToFile:(BOOL)writeResponseToFile
{
	if (url == nil || url.length == 0) {
		[self release];
		return nil;
	}

	NSURL *nsurl = [NSURL URLWithString:url];

	if (nsurl == nil) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_delegate = delegate;
		m_url = [url retain];

		NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:nsurl];

		if (method == AKNetRequestMethodDelete) {
			[req setHTTPMethod:@"DELETE"];
		}
		else if (method == AKNetRequestMethodGet) {
			[req setHTTPMethod:@"GET"];
		}
		else if (method == AKNetRequestMethodPost) {
			[req setHTTPMethod:@"POST"];
		}
		else if (method == AKNetRequestMethodPut) {
			[req setHTTPMethod:@"PUT"];
		}

		for (NSString *key in headers.allKeys) {
			[req setValue:[headers objectForKey:key] forHTTPHeaderField:key];
		}

		if (body != nil) {
			[req setValue:[NSString stringWithFormat:@"%d", body.length]
				forHTTPHeaderField:@"Content-Length"];
			[req setHTTPBody:body];
		}

		// Create an instance of AKNetRequestImpl to manage the connection, rather than
		// managing it ourselves, because the connection retains its delegate.  By having the
		// impl code manage the connection, we (AKNetRequest) can be released as a means to
		// trigger canceling the connection.

		m_impl = [[AKNetRequestImpl alloc] initWithDelegate:self request:req];

		if (m_impl == nil) {
			[self release];
			return nil;
		}

		[self cleanUpTempFiles];

		if (writeResponseToFile) {
			NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

			while (YES) {
				NSFileManager *fm = [NSFileManager defaultManager];
				NSString *fileName = [NSString stringWithFormat:@"%f_%d.bin", now, rand()];
				m_responsePath = [m_basePath stringByAppendingPathComponent:fileName];

				if (![fm fileExistsAtPath:m_responsePath]) {
					m_responsePath = [m_responsePath retain];
					[fm createDirectoryAtPath:m_basePath withIntermediateDirectories:YES
						attributes:nil error:nil];
					[fm createFileAtPath:m_responsePath contents:nil attributes:nil];
					break;
				}
			}
		}

		if (ignoreInteraction) {
			m_ignoreInteraction = YES;
			[[UIApplication sharedApplication] beginIgnoringInteractionEvents];
		}

		if (showNetActivityIndicator) {
			m_showNetActivityIndicator = YES;
			[AKNetActivityIndicator show];
		}

		[m_impl start];
	}

	return self;
}


@end
