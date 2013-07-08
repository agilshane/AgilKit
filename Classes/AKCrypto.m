//
//  AKCrypto.m
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

#import "AKCrypto.h"
#import "AKHex.h"
#import <CommonCrypto/CommonCryptor.h>
#import <CommonCrypto/CommonHMAC.h>


#define kKeySize 16


@interface AKCrypto()

+ (NSData *)keyForPassword:(NSString *)password;

@end


@implementation AKCrypto


+ (NSData *)decryptData:(NSData *)data key:(NSData *)key {
	if (data == nil || key == nil || key.length != kKeySize) {
		return nil;
	}

	size_t bufferSize = data.length + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	size_t numBytesDecrypted = 0;

	CCCryptorStatus cryptStatus = CCCrypt(
		kCCDecrypt,
		kCCAlgorithmAES128,
		kCCOptionPKCS7Padding,
		key.bytes,
		key.length,
		NULL,
		data.bytes,
		data.length,
		buffer,
		bufferSize,
		&numBytesDecrypted);
	
	if (cryptStatus == kCCSuccess) {
		return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
	}

	NSLog(@"Decryption failed!");
	free(buffer);
	return nil;
}


+ (NSData *)decryptData:(NSData *)data password:(NSString *)password {
	return [self decryptData:data key:[self keyForPassword:password]];
}


+ (NSString *)decryptString:(NSString *)s password:(NSString *)password {
	if (s == nil) {
		return nil;
	}

	NSData *data = [self decryptData:[AKHex dataFromString:s] password:password];
	return [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding] autorelease];
}


+ (NSData *)encryptData:(NSData *)data key:(NSData *)key {
	if (data == nil || key == nil || key.length != kKeySize) {
		return nil;
	}

	size_t bufferSize = data.length + kCCBlockSizeAES128;
	void *buffer = malloc(bufferSize);
	size_t numBytesEncrypted = 0;

	CCCryptorStatus cryptStatus = CCCrypt(
		kCCEncrypt,
		kCCAlgorithmAES128,
		kCCOptionPKCS7Padding,
		key.bytes,
		key.length,
		NULL,
		data.bytes,
		data.length,
		buffer,
		bufferSize,
		&numBytesEncrypted);

	if (cryptStatus == kCCSuccess) {
		return [NSData dataWithBytesNoCopy:buffer length:numBytesEncrypted];
	}

	NSLog(@"Encryption failed!");
	free(buffer);
	return nil;
}


+ (NSData *)encryptData:(NSData *)data password:(NSString *)password {
	return [self encryptData:data key:[self keyForPassword:password]];
}


+ (NSString *)encryptString:(NSString *)s password:(NSString *)password {
	if (s == nil) {
		return nil;
	}

	NSData *data = [self encryptData:[s dataUsingEncoding:NSUTF8StringEncoding]
		password:password];

	return [AKHex stringFromData:data];
}


+ (NSData *)keyForPassword:(NSString *)password {
	if (password == nil) {
		return nil;
	}

	NSData *data = [self sha256:[password dataUsingEncoding:NSUTF8StringEncoding]];
	return [data subdataWithRange:NSMakeRange(0, kKeySize)];
}


+ (NSData *)md5:(NSData *)data {
	if (data == nil) {
		return nil;
	}

	uint8_t hashBytes[CC_MD5_DIGEST_LENGTH];
	memset(hashBytes, 0, CC_MD5_DIGEST_LENGTH);

	CC_MD5_CTX ctx;
	CC_MD5_Init(&ctx);
	CC_MD5_Update(&ctx, data.bytes, data.length);
	CC_MD5_Final(hashBytes, &ctx);

	return [NSData dataWithBytes:hashBytes length:CC_MD5_DIGEST_LENGTH];
}


+ (NSData *)md5OfFileAtPath:(NSString *)path {
	NSFileHandle *handle = [NSFileHandle fileHandleForReadingAtPath:path];

	if (handle == nil) {
		return nil;
	}

	uint8_t hashBytes[CC_MD5_DIGEST_LENGTH];
	memset(hashBytes, 0, CC_MD5_DIGEST_LENGTH);

	CC_MD5_CTX ctx;
	CC_MD5_Init(&ctx);

	while (YES) {
		@autoreleasepool {
			NSData *data = [handle readDataOfLength:8192];

			if (data != nil && data.length > 0) {
				CC_MD5_Update(&ctx, data.bytes, data.length);
			}
			else {
				break;
			}
		}
	}

	CC_MD5_Final(hashBytes, &ctx);
	return [NSData dataWithBytes:hashBytes length:CC_MD5_DIGEST_LENGTH];
}


+ (NSData *)sha1:(NSData *)data {
	if (data == nil) {
		return nil;
	}

	uint8_t hashBytes[CC_SHA1_DIGEST_LENGTH];
	memset(hashBytes, 0, CC_SHA1_DIGEST_LENGTH);

	CC_SHA1_CTX ctx;
	CC_SHA1_Init(&ctx);
	CC_SHA1_Update(&ctx, data.bytes, data.length);
	CC_SHA1_Final(hashBytes, &ctx);

	return [NSData dataWithBytes:hashBytes length:CC_SHA1_DIGEST_LENGTH];
}


+ (NSData *)sha1:(NSData *)data hmacKey:(NSData *)key {
	if (data == nil) {
		return nil;
	}

	uint8_t hashBytes[CC_SHA1_DIGEST_LENGTH];
	memset(hashBytes, 0, CC_SHA1_DIGEST_LENGTH);
	CCHmac(kCCHmacAlgSHA1, key.bytes, key.length, data.bytes, data.length, hashBytes);
	return [NSData dataWithBytes:hashBytes length:CC_SHA1_DIGEST_LENGTH];
}


+ (NSData *)sha256:(NSData *)data {
	if (data == nil) {
		return nil;
	}

	uint8_t hashBytes[CC_SHA256_DIGEST_LENGTH];
	memset(hashBytes, 0, CC_SHA256_DIGEST_LENGTH);

	CC_SHA256_CTX ctx;
	CC_SHA256_Init(&ctx);
	CC_SHA256_Update(&ctx, data.bytes, data.length);
	CC_SHA256_Final(hashBytes, &ctx);

	return [NSData dataWithBytes:hashBytes length:CC_SHA256_DIGEST_LENGTH];
}


@end
