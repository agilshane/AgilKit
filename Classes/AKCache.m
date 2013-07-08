//
//  AKCache.m
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

#import "AKCache.h"
#import "AKCrypto.h"
#import "AKHex.h"


static int m_maxBytes = 10000000;


//
// AKCacheItem
//


@interface AKCacheItem : NSObject {
	@private NSString *m_basePath;
	@private NSTimeInterval m_expiry;
	@private BOOL m_keepIfExpired;
	@private NSDate *m_modified;
	@private unsigned long long m_size;
}

@property (nonatomic, retain) NSString *basePath;
@property (nonatomic, assign) NSTimeInterval expiry;
@property (nonatomic, assign) BOOL keepIfExpired;
@property (nonatomic, retain) NSDate *modified;
@property (nonatomic, assign) unsigned long long size;

@end

@implementation AKCacheItem

@synthesize basePath = m_basePath;
@synthesize expiry = m_expiry;
@synthesize keepIfExpired = m_keepIfExpired;
@synthesize modified = m_modified;
@synthesize size = m_size;

- (void)dealloc {
	[m_basePath release];
	[m_modified release];
	[super dealloc];
}

@end


//
// AKCache
//


@interface AKCache()

+ (NSString *)basePathForURL:(NSString *)url;
+ (NSString *)rootPath;

+ (void)
	writeInfoFileWithBasePath:(NSString *)basePath
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired;

@end


@implementation AKCache


@synthesize data = m_data;
@synthesize image = m_image;
@synthesize url = m_url;


+ (void)
	addData:(NSData *)data
	url:(NSString *)url
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired
{
	NSString *basePath = [self basePathForURL:url];
	NSString *path = [basePath stringByAppendingPathComponent:@"file.bin"];

	if (path == nil || data == nil) {
		return;
	}

	[[NSFileManager defaultManager] createDirectoryAtPath:basePath
		withIntermediateDirectories:YES attributes:nil error:nil];
	[data writeToFile:path atomically:YES];
	[self writeInfoFileWithBasePath:basePath timeToLive:timeToLive keepIfExpired:keepIfExpired];
}


+ (void)
	addJPEGData:(NSData *)data
	url:(NSString *)url
	retina:(BOOL)retina
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired
{
	NSString *basePath = [self basePathForURL:url];
	NSString *path = retina ?
		[basePath stringByAppendingPathComponent:@"file@2x.jpg"] :
		[basePath stringByAppendingPathComponent:@"file.jpg"];

	if (path == nil || data == nil) {
		return;
	}

	[[NSFileManager defaultManager] createDirectoryAtPath:basePath
		withIntermediateDirectories:YES attributes:nil error:nil];
	[data writeToFile:path atomically:YES];
	[self writeInfoFileWithBasePath:basePath timeToLive:timeToLive keepIfExpired:keepIfExpired];
}


+ (void)
	addPNGData:(NSData *)data
	url:(NSString *)url
	retina:(BOOL)retina
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired
{
	NSString *basePath = [self basePathForURL:url];
	NSString *path = retina ?
		[basePath stringByAppendingPathComponent:@"file@2x.png"] :
		[basePath stringByAppendingPathComponent:@"file.png"];

	if (path == nil || data == nil) {
		return;
	}

	[[NSFileManager defaultManager] createDirectoryAtPath:basePath
		withIntermediateDirectories:YES attributes:nil error:nil];
	[data writeToFile:path atomically:YES];
	[self writeInfoFileWithBasePath:basePath timeToLive:timeToLive keepIfExpired:keepIfExpired];
}


+ (NSString *)basePathForURL:(NSString *)url {
	NSString *rootPath = [self rootPath];

	if (url == nil || rootPath == nil) {
		return nil;
	}

	NSData *data = [AKCrypto md5:[url dataUsingEncoding:NSUTF8StringEncoding]];
	return [rootPath stringByAppendingPathComponent:[AKHex stringFromData:data]];
}


+ (NSData *)dataWithURL:(NSString *)url {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *basePath = [self basePathForURL:url];

	if (basePath == nil) {
		return nil;
	}

	for (NSString *name in [fm contentsOfDirectoryAtPath:basePath error:nil]) {
		if ([name hasSuffix:@".jpg"] || [name hasSuffix:@".png"] || [name hasSuffix:@".bin"]) {
			NSString *path = [basePath stringByAppendingPathComponent:name];
			return [NSData dataWithContentsOfFile:path];
		}
	}

	return nil;
}


- (void)dealloc {
	[m_data release];
	[m_image release];
	[m_netRequestData release];
	[m_netRequestImage release];
	[m_url release];
	[super dealloc];
}


+ (void)deleteFileWithURL:(NSString *)url {
	NSString *basePath = [self basePathForURL:url];

	if (basePath != nil) {
		[[NSFileManager defaultManager] removeItemAtPath:basePath error:nil];
		return;
	}
}


+ (BOOL)fileExistsWithURL:(NSString *)url {
	NSString *basePath = [self basePathForURL:url];
	BOOL exists = NO;

	if (basePath != nil) {
		NSString *path = [basePath stringByAppendingPathComponent:@"file.info"];
		exists = [[NSFileManager defaultManager] fileExistsAtPath:path];
	}

	return exists;
}


+ (BOOL)fileExpiredWithURL:(NSString *)url {
	NSString *infoPath = [[self basePathForURL:url]
		stringByAppendingPathComponent:@"file.info"];
	NSString *info = [NSString stringWithContentsOfFile:infoPath
		encoding:NSUTF8StringEncoding error:nil];

	if (info == nil || info.length < 3) {
		return NO;
	}

	NSTimeInterval expiry = [info substringFromIndex:2].longLongValue;
	return expiry < [NSDate timeIntervalSinceReferenceDate];
}


+ (UIImage *)imageWithURL:(NSString *)url {
	NSString *basePath = [self basePathForURL:url];

	if (basePath == nil) {
		return nil;
	}

	UIImage *image = [[UIImage alloc] initWithContentsOfFile:
		[basePath stringByAppendingPathComponent:@"file@2x.jpg"]];

	if (image == nil) {
		image = [[UIImage alloc] initWithContentsOfFile:
			[basePath stringByAppendingPathComponent:@"file@2x.png"]];
	}

	if (image != nil) {
		if (image.scale == 2.0) {
			return [image autorelease];
		}

		UIImage *image2 = [[[UIImage alloc] initWithCGImage:image.CGImage
			scale:2 orientation:image.imageOrientation] autorelease];
		[image release];
		return image2;
	}

	image = [[UIImage alloc] initWithContentsOfFile:
		[basePath stringByAppendingPathComponent:@"file.jpg"]];

	if (image == nil) {
		image = [[UIImage alloc] initWithContentsOfFile:
			[basePath stringByAppendingPathComponent:@"file.png"]];
	}

	if (image != nil) {
		if (image.scale == 1.0) {
			return [image autorelease];
		}

		UIImage *image2 = [[[UIImage alloc] initWithCGImage:image.CGImage
			scale:1 orientation:image.imageOrientation] autorelease];
		[image release];
		return image2;
	}

	return nil;
}


- (id)
	initDataRequestWithDelegate:(id <AKCacheDelegate>)delegate
	url:(NSString *)url
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired
{
	m_keepIfExpired = keepIfExpired;
	m_retina = NO;
	m_timeToLive = timeToLive;

	if (url == nil || url.length == 0) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_delegate = delegate;
		m_url = [url retain];
		m_netRequestData = [[AKNetRequest alloc] initWithDelegate:self url:url];
	}

	return self;
}


- (id)
	initImageRequestWithDelegate:(id <AKCacheDelegate>)delegate
	url:(NSString *)url
	retina:(BOOL)retina
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired
{
	m_keepIfExpired = keepIfExpired;
	m_retina = retina;
	m_timeToLive = timeToLive;

	if (url == nil || url.length == 0) {
		[self release];
		return nil;
	}

	if (self = [super init]) {
		m_delegate = delegate;
		m_url = [url retain];
		m_netRequestImage = [[AKNetRequest alloc] initWithDelegate:self url:url];
	}

	return self;
}


- (void)netRequestDidFinish:(AKNetRequest *)request error:(NSError *)error {
	if (error != nil) {
		if (request == m_netRequestData) {
			[m_netRequestData autorelease];
			m_netRequestData = nil;
		}
		else if (request == m_netRequestImage) {
			[m_netRequestImage autorelease];
			m_netRequestImage = nil;
		}

		[m_delegate cacheDidFinish:self error:error];
		return;
	}

	NSFileManager *fm = [NSFileManager defaultManager];
	NSString *basePath = [AKCache basePathForURL:m_url];

	if (request.statusCode == 200) {
		[AKCache deleteFileWithURL:m_url];
	}

	if (request == m_netRequestData) {
		[m_netRequestData autorelease];
		m_netRequestData = nil;
		NSData *data = request.responseBody;

		if (request.statusCode != 200 || data == nil || data.length == 0) {
			[m_delegate cacheDidFinish:self error:nil];
			return;
		}

		NSString *path = [basePath stringByAppendingPathComponent:@"file.bin"];

		if (path != nil) {
			[fm createDirectoryAtPath:basePath withIntermediateDirectories:YES attributes:nil
				error:nil];
			[data writeToFile:path atomically:YES];
			[AKCache writeInfoFileWithBasePath:basePath timeToLive:m_timeToLive
				keepIfExpired:m_keepIfExpired];
		}

		m_data = [data retain];
		[m_delegate cacheDidFinish:self error:nil];
	}
	else if (request == m_netRequestImage) {
		[m_netRequestImage autorelease];
		m_netRequestImage = nil;
		NSData *data = request.responseBody;

		if (request.statusCode != 200 || data == nil || data.length == 0) {
			[m_delegate cacheDidFinish:self error:nil];
			return;
		}

		BOOL isJPEG = NO;
		BOOL isPNG = NO;

		for (NSString *key in request.responseHeaders.allKeys) {
			if ([key.lowercaseString isEqualToString:@"content-type"]) {
				NSString *val = [request.responseHeaders objectForKey:key];

				if (val != nil && val.length > 0) {
					NSString *valLower = val.lowercaseString;

					if ([valLower isEqualToString:@"image/jpeg"]) {
						isJPEG = YES;
					}
					else if ([valLower isEqualToString:@"image/png"]) {
						isPNG = YES;
					}
				}

				break;
			}
		}

		if (!isJPEG && !isPNG) {
			NSString *urlLower = m_url.lowercaseString;

			if ([urlLower rangeOfString:@".jpg"].location != NSNotFound ||
				[urlLower rangeOfString:@".jpeg"].location != NSNotFound)
			{
				isJPEG = YES;
			}
			else if ([urlLower rangeOfString:@".png"].location != NSNotFound) {
				isPNG = YES;
			}
		}

		if (isJPEG || isPNG) {
			NSString *path = basePath;

			if (m_retina) {
				if (isJPEG) {
					path = [path stringByAppendingPathComponent:@"file@2x.jpg"];
				}
				else {
					path = [path stringByAppendingPathComponent:@"file@2x.png"];
				}
			}
			else {
				if (isJPEG) {
					path = [path stringByAppendingPathComponent:@"file.jpg"];
				}
				else {
					path = [path stringByAppendingPathComponent:@"file.png"];
				}
			}

			if (path != nil) {
				[fm createDirectoryAtPath:basePath withIntermediateDirectories:YES
					attributes:nil error:nil];
				[data writeToFile:path atomically:YES];
				[AKCache writeInfoFileWithBasePath:basePath timeToLive:m_timeToLive
					keepIfExpired:m_keepIfExpired];
			}
		}

		UIImage *image = [[UIImage alloc] initWithData:data];
		CGFloat scale = m_retina ? 2 : 1;

		if (image != nil && image.scale != scale) {
			UIImage *image2 = [[UIImage alloc] initWithCGImage:image.CGImage
				scale:scale orientation:image.imageOrientation];
			[image release];
			image = image2;
		}

		m_image = image;
		[m_delegate cacheDidFinish:self error:nil];
	}
}


+ (void)onAppNotification {
	[self trim];
}


+ (NSString *)rootPath {
	static NSString *rootPath = nil;

	if (rootPath == nil) {
		NSFileManager *fm = [NSFileManager defaultManager];
		NSString *path = [NSSearchPathForDirectoriesInDomains(NSCachesDirectory,
			NSUserDomainMask, YES) objectAtIndex:0];
		path = [path stringByAppendingPathComponent:@"AKCache"];
		[fm createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:nil];

		if ([fm fileExistsAtPath:path]) {
			rootPath = [path retain];
		}
		else {
			NSLog(@"Could not create the root path!");
		}
	}

	return rootPath;
}


+ (void)setMaxBytes:(int)maxBytes {
	m_maxBytes = maxBytes;
}


+ (void)setTrimPolicy:(AKCacheTrimPolicy)policy {
	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
	[nc removeObserver:self];

	if (policy == AKCacheTrimPolicyBecomeOrResignActive) {
		[nc addObserver:self selector:@selector(onAppNotification)
			name:UIApplicationDidBecomeActiveNotification object:nil];
		[nc addObserver:self selector:@selector(onAppNotification)
			name:UIApplicationWillResignActiveNotification object:nil];
	}
}


+ (void)trim {
	NSFileManager *fm = [NSFileManager defaultManager];
	NSMutableArray *items = [NSMutableArray array];
	NSString *rootPath = [self rootPath];
	unsigned long long totalSize = 0;

	if (rootPath == nil) {
		return;
	}

	for (NSString *name in [fm contentsOfDirectoryAtPath:rootPath error:nil]) {
		NSString *basePath = [rootPath stringByAppendingPathComponent:name];

		NSString *path = [basePath stringByAppendingPathComponent:@"file@2x.jpg"];
		NSDictionary *attributes = [fm attributesOfItemAtPath:path error:nil];

		if (attributes == nil) {
			path = [basePath stringByAppendingPathComponent:@"file@2x.png"];
			attributes = [fm attributesOfItemAtPath:path error:nil];

			if (attributes == nil) {
				path = [basePath stringByAppendingPathComponent:@"file.jpg"];
				attributes = [fm attributesOfItemAtPath:path error:nil];

				if (attributes == nil) {
					path = [basePath stringByAppendingPathComponent:@"file.png"];
					attributes = [fm attributesOfItemAtPath:path error:nil];

					if (attributes == nil) {
						path = [basePath stringByAppendingPathComponent:@"file.bin"];
						attributes = [fm attributesOfItemAtPath:path error:nil];
					}
				}
			}
		}

		if (attributes == nil) {
			// Probably a .DS_Store file.
		}
		else {
			AKCacheItem *item = [[AKCacheItem alloc] init];

			item.basePath = basePath;
			item.modified = attributes.fileModificationDate;
			item.size = attributes.fileSize;

			totalSize += item.size;

			[items addObject:item];
			[item release];
		}
	}

	NSMutableArray *expiredItemsToNuke = [NSMutableArray array];
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

	for (AKCacheItem *item in items) {
		NSString *path = [item.basePath stringByAppendingPathComponent:@"file.info"];
		NSString *info = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding
			error:nil];

		if (info == nil || info.length < 3) {
			continue;
		}

		BOOL keep = ([info characterAtIndex:0] != NO);

		if (!keep) {
			NSTimeInterval expiry = [info substringFromIndex:2].longLongValue;

			if (expiry < now) {
				[expiredItemsToNuke addObject:item];
			}
		}
	}

	for (AKCacheItem *item in expiredItemsToNuke) {
		[fm removeItemAtPath:item.basePath error:nil];
		[items removeObject:item];
		totalSize -= item.size;
	}

	[items sortUsingComparator:^NSComparisonResult(AKCacheItem *item0, AKCacheItem *item1) {
		return [item0.modified compare:item1.modified];
	}];

	for (AKCacheItem *item in items) {
		if (totalSize < m_maxBytes) {
			break;
		}

		[fm removeItemAtPath:item.basePath error:nil];
		totalSize -= item.size;
	}
}


+ (void)
	writeInfoFileWithBasePath:(NSString *)basePath
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired
{
	if (basePath != nil) {
		NSString *path = [basePath stringByAppendingPathComponent:@"file.info"];
		NSString *s = [NSString stringWithFormat:@"%d|%qi", keepIfExpired,
			(long long)([NSDate timeIntervalSinceReferenceDate] + timeToLive)];
		[s writeToFile:path atomically:NO encoding:NSUTF8StringEncoding error:nil];
	}
}


@end
