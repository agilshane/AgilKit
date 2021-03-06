//
//  AGKImage.swift
//  AgilKit
//
//  Created by Shane Meyer on 2/13/15.
//  Copyright © 2013-2018 Agilstream, LLC. All rights reserved.
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

	class func cropped(image: UIImage, rect: CGRect) -> UIImage {
		var r = rect

		switch image.imageOrientation {
			case .down:
				r.origin.x = image.size.width - rect.maxX
				r.origin.y = image.size.height - rect.maxY
			case .left:
				r.origin.x = image.size.height - rect.maxY
				r.origin.y = rect.origin.x
				r.size.width = rect.size.height
				r.size.height = rect.size.width
			case .right:
				r.origin.x = rect.origin.y
				r.origin.y = image.size.width - rect.maxX
				r.size.width = rect.size.height
				r.size.height = rect.size.width
			default:
				break
		}

		let scale = image.scale
		r.origin.x *= scale
		r.origin.y *= scale
		r.size.width *= scale
		r.size.height *= scale

		if let cgImage = image.cgImage, let imageRef = cgImage.cropping(to: r) {
			return UIImage(cgImage: imageRef, scale: scale, orientation: image.imageOrientation)
		}

		return image
	}

	// Returns a resizable image with a 1x1 point that is not capped. The point is centered
	// vertically and horizontally.

	class func resizable(image: UIImage) -> UIImage {
		let left = round(image.size.width / 2) - 1
		return resizable(image: image, insetLeft: left)
	}

	// Returns a resizable image with a 1x1 point that is not capped. The point is centered
	// vertically and uses the given left inset.

	class func resizable(image: UIImage, insetLeft: CGFloat) -> UIImage {
		let top = round(image.size.height / 2) - 1
		return image.resizableImage(withCapInsets: UIEdgeInsets(top: top, left: insetLeft,
			bottom: image.size.height - top - 1, right: image.size.width - insetLeft - 1))
	}

	// Returns a resizable image with a 1x1 point that is not capped. The point is centered
	// vertically and uses the given right inset.

	class func resizable(image: UIImage, insetRight: CGFloat) -> UIImage {
		let top = round(image.size.height / 2) - 1
		return image.resizableImage(withCapInsets: UIEdgeInsets(
			top: top, left: image.size.width - insetRight - 1,
			bottom: image.size.height - top - 1, right: insetRight))
	}

	// Replaces all pixels with the given color, preserving the alpha channel.

	class func tint(image: UIImage, color: UIColor) -> UIImage {
		UIGraphicsBeginImageContextWithOptions(image.size, false, image.scale)
		color.setFill()
		UIRectFill(CGRect(origin: .zero, size: image.size))
		image.draw(at: .zero, blendMode: .destinationIn, alpha: 1)
		let result = UIGraphicsGetImageFromCurrentImageContext()
		UIGraphicsEndImageContext()
		return result ?? UIImage()
	}

}
