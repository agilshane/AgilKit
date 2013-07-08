//
//  AKKeychain.m
//  AgilKit
//
//  Created by Shane Meyer on 3/28/13.
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

#import "AKKeychain.h"


@implementation AKKeychain


+ (void)deleteStringValueForKey:(NSString *)key {
	NSDictionary *dict = @{
		(id)kSecAttrAccount : key,
		(id)kSecClass : (id)kSecClassGenericPassword
	};

	OSStatus status = SecItemDelete((CFDictionaryRef)dict);

	if (status == errSecItemNotFound) {
		// Not found, no problem.
	}
	else if (status != errSecSuccess) {
		NSLog(@"There was a problem deleting an item from the keychain (%ld)!", status);
	}
}


+ (void)setStringValue:(NSString *)value forKey:(NSString *)key {
	if (value == nil) {
		[self deleteStringValueForKey:key];
		return;
	}

	NSString *oldValue = [self stringValueForKey:key];

	if (oldValue == nil) {
		NSDictionary *dict = @{
			(id)kSecAttrAccount : key,
			(id)kSecClass : (id)kSecClassGenericPassword,
			(id)kSecValueData : [value dataUsingEncoding:NSUTF8StringEncoding]
		};

		id outval = nil;
		OSStatus status = SecItemAdd((CFDictionaryRef)dict, (CFTypeRef *)&outval);

		if (status != errSecSuccess) {
			NSLog(@"Failed to set a keychain value (%ld)!", status);
		}
	}
	else {
		[self deleteStringValueForKey:key];
		[self setStringValue:value forKey:key];
	}
}


+ (NSString *)stringValueForKey:(NSString *)key {
	NSDictionary *query = @{
		(id)kSecAttrAccount : key,
		(id)kSecClass : (id)kSecClassGenericPassword,
		(id)kSecMatchLimit : (id)kSecMatchLimitOne,
		(id)kSecReturnData : (id)kCFBooleanTrue
	};

	id outval = nil;
	OSStatus status = SecItemCopyMatching((CFDictionaryRef)query, (CFTypeRef *)&outval);
	NSString *value = nil;

	if (status == errSecItemNotFound) {
		// Not found, no problem.
	}
	else if (status == errSecSuccess) {
		NSData *data = (NSData *)outval;

		if (data != nil) {
			value = [[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]
				autorelease];
			[data release];
		}
	}
	else {
		NSLog(@"There was a problem retrieving a keychain value (%ld)!", status);
	}

	return value;
}


@end
