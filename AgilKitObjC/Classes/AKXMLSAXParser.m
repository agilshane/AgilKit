//
//  AKXMLSAXParser.m
//  AgilKit
//
//  Created by Shane Meyer on 3/28/13.
//  Copyright (c) 2013-2015 Agilstream, LLC.
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

#import "AKXMLSAXParser.h"


@interface AKXMLSAXParser () {
	@private NSMutableString *m_currPath;
	@private NSMutableString *m_currText;
	@private __weak id <AKXMLSAXParserDelegate> m_delegate;
}

@end


@implementation AKXMLSAXParser


- (instancetype)initWithDelegate:(id <AKXMLSAXParserDelegate>)delegate {
	if (self = [super init]) {
		m_currPath = [[NSMutableString alloc] initWithCapacity:256];
		m_currText = [[NSMutableString alloc] initWithCapacity:512];
		m_delegate = delegate;
	}

	return self;
}


- (void)parseData:(NSData *)data {
	[m_currPath setString:@""];
	[m_currText setString:@""];

	NSXMLParser *parser = [[NSXMLParser alloc] initWithData:data];

	[parser setDelegate:self];
	[parser parse];
}


- (void)
	parser:(NSXMLParser *)parser
	didEndElement:(NSString *)elementName
	namespaceURI:(NSString *)namespaceURI
	qualifiedName:(NSString *)qName
{
	NSString *path = [[NSString alloc] initWithString:m_currPath];
	NSString *text = [[NSString alloc] initWithString:m_currText];
	[m_delegate xmlsaxParser:self didEndElementPath:path text:text];
	[m_currText setString:@""];
	NSRange range = [m_currPath rangeOfString:@"/" options:NSBackwardsSearch];

	if (range.location == NSNotFound) {
		NSLog(@"The current path has no forward slash!");
	}
	else {
		range = NSMakeRange(range.location, m_currPath.length - range.location);
		[m_currPath deleteCharactersInRange:range];
	}
}


- (void)
	parser:(NSXMLParser *)parser
	didStartElement:(NSString *)elementName
	namespaceURI:(NSString *)namespaceURI
	qualifiedName:(NSString *)qualifiedName
	attributes:(NSDictionary *)attributeDict
{
	[m_currText setString:@""];
	[m_currPath appendString:@"/"];
	[m_currPath appendString:elementName];
	NSString *path = [[NSString alloc] initWithString:m_currPath];
	[m_delegate xmlsaxParser:self didStartElementPath:path attributes:attributeDict];
}


- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {

	// Using a mutable string and appending to it (as done here) is more memory efficient than
	// creating a new string each time and discarding the old, especially in cases where the
	// "found characters" contain many escaped XML characters.  For whatever reason with that
	// kind of text this callback is called many times with very few characters in each call.

	[m_currText appendString:string];
}


- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)error {
	[m_delegate xmlsaxParser:self hadError:error];
}


@end
