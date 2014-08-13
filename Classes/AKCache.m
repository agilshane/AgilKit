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
#import "AKNetRequest.h"


static BOOL m_didAddToCacheSinceLastTrim = NO;
static NSMutableDictionary *m_fileInfos = nil;
static unsigned long long m_maxBytes = 10 * 1024 * 1024;
static AKCacheTrimPolicy m_policy = AKCacheTrimPolicyBecomeOrResignActive;


//
// AKCacheFileInfo
//

@interface AKCacheFileInfo : NSObject {
	@private NSString *m_basePath;
	@private NSTimeInterval m_expiry;
	@private BOOL m_keepIfExpired;
}

@property (nonatomic, readonly) NSString *basePath;
@property (nonatomic, readonly) NSTimeInterval expiry;
@property (nonatomic, readonly) BOOL keepIfExpired;

- (id)initWithBasePath:(NSString *)basePath;

@end

@implementation AKCacheFileInfo

@synthesize basePath = m_basePath;
@synthesize expiry = m_expiry;
@synthesize keepIfExpired = m_keepIfExpired;

- (id)initWithBasePath:(NSString *)basePath {
	if (basePath == nil || basePath.length == 0) {
		return nil;
	}

	if (self = [super init]) {
		m_basePath = basePath;
		NSString *infoPath = [basePath stringByAppendingPathComponent:@"file.info"];

		NSString *info = [NSString stringWithContentsOfFile:infoPath
			encoding:NSUTF8StringEncoding error:nil];

		if (info == nil || info.length < 3) {
			return nil;
		}

		m_keepIfExpired = ([info characterAtIndex:0] != NO);
		m_expiry = [info substringFromIndex:2].longLongValue;
	}

	return self;
}

@end


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

@property (nonatomic, strong) NSString *basePath;
@property (nonatomic, assign) NSTimeInterval expiry;
@property (nonatomic, assign) BOOL keepIfExpired;
@property (nonatomic, strong) NSDate *modified;
@property (nonatomic, assign) unsigned long long size;

@end

@implementation AKCacheItem

@synthesize basePath = m_basePath;
@synthesize expiry = m_expiry;
@synthesize keepIfExpired = m_keepIfExpired;
@synthesize modified = m_modified;
@synthesize size = m_size;

@end


//
// AKCache
//


@interface AKCache () <AKNetRequestDelegate> {
	@private NSData *m_data;
	@private __weak id <AKCacheDelegate> m_delegate;
	@private UIImage *m_image;
	@private BOOL m_keepIfExpired;
	@private AKNetRequest *m_netRequestData;
	@private AKNetRequest *m_netRequestImage;
	@private BOOL m_retina;
	@private NSTimeInterval m_timeToLive;
	@private NSString *m_url;
}

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


+ (void)deleteFileWithURL:(NSString *)url {
	NSString *basePath = [self basePathForURL:url];

	if (basePath != nil) {
		[m_fileInfos removeObjectForKey:basePath];
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
	NSString *infoPath = [[self basePathForURL:url] stringByAppendingPathComponent:@"file.info"];
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
			return image;
		}

		return [[UIImage alloc] initWithCGImage:image.CGImage
			scale:2 orientation:image.imageOrientation];
	}

	image = [[UIImage alloc] initWithContentsOfFile:
		[basePath stringByAppendingPathComponent:@"file.jpg"]];

	if (image == nil) {
		image = [[UIImage alloc] initWithContentsOfFile:
			[basePath stringByAppendingPathComponent:@"file.png"]];
	}

	if (image != nil) {
		if (image.scale == 1.0) {
			return image;
		}

		return [[UIImage alloc] initWithCGImage:image.CGImage
			scale:1 orientation:image.imageOrientation];
	}

	return nil;
}


+ (void)initialize {
	m_fileInfos = [[NSMutableDictionary alloc] init];

	NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];

	[nc addObserver:self selector:@selector(onAppNotification)
		name:UIApplicationDidBecomeActiveNotification object:nil];

	[nc addObserver:self selector:@selector(onAppNotification)
		name:UIApplicationWillResignActiveNotification object:nil];

	[nc addObserver:self selector:@selector(onLowMemory)
		name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
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
		return nil;
	}

	if (self = [super init]) {
		m_delegate = delegate;
		m_url = url;
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
		return nil;
	}

	if (self = [super init]) {
		m_delegate = delegate;
		m_url = url;
		m_netRequestImage = [[AKNetRequest alloc] initWithDelegate:self url:url];
	}

	return self;
}


- (void)netRequestDidFinish:(AKNetRequest *)request error:(NSError *)error {
	if (error != nil) {
		if (request == m_netRequestData) {
			m_netRequestData = nil;
		}
		else if (request == m_netRequestImage) {
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

		m_data = data;
		[m_delegate cacheDidFinish:self error:nil];
	}
	else if (request == m_netRequestImage) {
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
			image = [[UIImage alloc] initWithCGImage:image.CGImage
				scale:scale orientation:image.imageOrientation];
		}

		m_image = image;
		[m_delegate cacheDidFinish:self error:nil];
	}
}


+ (void)onAppNotification {
	if (m_policy == AKCacheTrimPolicyBecomeOrResignActive) {
		[self trim];
	}
}


+ (void)onLowMemory {
	[m_fileInfos removeAllObjects];
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
			rootPath = path;
		}
		else {
			NSLog(@"Could not create the root path!");
		}
	}

	return rootPath;
}


+ (void)setMaxBytes:(unsigned long long)maxBytes {
	m_maxBytes = maxBytes;
}


+ (void)setTrimPolicy:(AKCacheTrimPolicy)policy {
	m_policy = policy;
}


+ (void)trim {
	if (!m_didAddToCacheSinceLastTrim) {
		return;
	}

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
		}
	}

	NSMutableArray *expiredItemsToNuke = [NSMutableArray array];
	NSTimeInterval now = [NSDate timeIntervalSinceReferenceDate];

	for (AKCacheItem *item in items) {
		AKCacheFileInfo *fileInfo = m_fileInfos[item.basePath];

		if (fileInfo == nil) {
			fileInfo = [[AKCacheFileInfo alloc] initWithBasePath:item.basePath];

			if (fileInfo != nil) {
				m_fileInfos[item.basePath] = fileInfo;
			}
		}

		if (fileInfo != nil && !fileInfo.keepIfExpired && fileInfo.expiry < now) {
			[expiredItemsToNuke addObject:item];
		}
	}

	for (AKCacheItem *item in expiredItemsToNuke) {
		[m_fileInfos removeObjectForKey:item.basePath];
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

		[m_fileInfos removeObjectForKey:item.basePath];
		[fm removeItemAtPath:item.basePath error:nil];
		totalSize -= item.size;
	}

	m_didAddToCacheSinceLastTrim = NO;
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
		m_fileInfos[basePath] = [[AKCacheFileInfo alloc] initWithBasePath:basePath];
		m_didAddToCacheSinceLastTrim = YES;
	}
}


@end
