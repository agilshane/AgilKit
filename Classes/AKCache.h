//
//  AKCache.h
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

#define kAKCacheTimeToLiveOneYear 31536000.0

typedef enum {
	AKCacheTrimPolicyBecomeOrResignActive,
	AKCacheTrimPolicyNone
} AKCacheTrimPolicy;

@class AKCache;

@protocol AKCacheDelegate <NSObject>

- (void)cacheDidFinish:(AKCache *)cache error:(NSError *)error;

@end

@interface AKCache : NSObject

@property (nonatomic, readonly) NSData *data;
@property (nonatomic, readonly) UIImage *image;
@property (nonatomic, readonly) NSString *url;

+ (void)
	addData:(NSData *)data
	url:(NSString *)url
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired;

+ (void)
	addJPEGData:(NSData *)data
	url:(NSString *)url
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired;

+ (void)
	addPNGData:(NSData *)data
	url:(NSString *)url
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired;

+ (NSData *)dataWithURL:(NSString *)url;
+ (void)deleteFileWithURL:(NSString *)url;
+ (BOOL)fileExistsWithURL:(NSString *)url;
+ (BOOL)fileExpiredWithURL:(NSString *)url;
+ (UIImage *)imageWithURL:(NSString *)url;

- (instancetype)
	initDataRequestWithDelegate:(id <AKCacheDelegate>)delegate
	url:(NSString *)url
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired;

- (instancetype)
	initImageRequestWithDelegate:(id <AKCacheDelegate>)delegate
	url:(NSString *)url
	timeToLive:(NSTimeInterval)timeToLive
	keepIfExpired:(BOOL)keepIfExpired;

+ (void)setMaxBytes:(unsigned long long)maxBytes;
+ (void)setTrimPolicy:(AKCacheTrimPolicy)policy;
+ (void)trim;

@end
