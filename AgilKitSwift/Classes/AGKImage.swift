//
//  AGKImage.swift
//  AgilKit
//
//  Created by Shane Meyer on 2/13/15.
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

import UIKit

class AGKImage {

	class func croppedImageWithImage(image: UIImage, rect: CGRect) -> UIImage {
		var r = rect
		if image.imageOrientation == .Down {
			r.origin.x = image.size.width - rect.maxX
			r.origin.y = image.size.height - rect.maxY
		}
		else if image.imageOrientation == .Left {
			r.origin.x = image.size.height - rect.maxY
			r.origin.y = rect.origin.x
			r.size.width = rect.size.height
			r.size.height = rect.size.width
		}
		else if image.imageOrientation == .Right {
			r.origin.x = rect.origin.y
			r.origin.y = image.size.width - rect.maxX
			r.size.width = rect.size.height
			r.size.height = rect.size.width
		}
		let scale = image.scale
		r.origin.x *= scale
		r.origin.y *= scale
		r.size.width *= scale
		r.size.height *= scale
		if let imageRef = CGImageCreateWithImageInRect(image.CGImage, r) {
			return UIImage(CGImage: imageRef, scale: scale, orientation: image.imageOrientation)
		}
		return image
	}

	// Returns a resizable image with a 1x1 point that is not capped. The point is centered
	// vertically and horizontally.

	class func resizableImageWithImage(image: UIImage) -> UIImage {
		return resizableImageWithImage(image, insetLeft: round(0.5 * image.size.width) - CGFloat(1))
	}

	// Returns a resizable image with a 1x1 point that is not capped. The point is centered
	// vertically and uses the given left inset.

	class func resizableImageWithImage(image: UIImage, insetLeft: CGFloat) -> UIImage {
		let top = round(0.5 * image.size.height) - CGFloat(1)
		return image.resizableImageWithCapInsets(UIEdgeInsetsMake(
			top, insetLeft,
			image.size.height - top - CGFloat(1), image.size.width - insetLeft - CGFloat(1)))
	}

	// Returns a resizable image with a 1x1 point that is not capped. The point is centered
	// vertically and uses the given right inset.

	class func resizableImageWithImage(image: UIImage, insetRight: CGFloat) -> UIImage {
		let top = round(0.5 * image.size.height) - CGFloat(1)
		return image.resizableImageWithCapInsets(UIEdgeInsetsMake(
			top, image.size.width - insetRight - CGFloat(1),
			image.size.height - top - CGFloat(1), insetRight))
	}

	// Replaces all pixels with the given color, preserving the alpha channel.

	class func tintImage(image: UIImage, color: UIColor) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
		color.setFill()
		CGContextFillRect(UIGraphicsGetCurrentContext(),
			CGRectMake(0, 0, image.size.width, image.size.height))
		image.drawAtPoint(CGPointZero, blendMode: .DestinationIn, alpha: 1)
		let result = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return result
	}

}
