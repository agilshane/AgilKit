//
//  AKImageEffects.m
//  AgilKit
//
//  Created by Shane Meyer on 6/8/15.
//  Copyright (c) 2015 Agilstream, LLC. All rights reserved.
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

#import "AKImageEffects.h"

@import Accelerate;

@implementation AKImageEffects

+ (nonnull UIImage *)blurImage:(nonnull UIImage *)image
	radius:(CGFloat)radius
	tintColor:(nullable UIColor *)tintColor
	saturation:(CGFloat)saturation
{
	// Based on Apple's UIImageEffects sample class.

	CGImageRef inputCGImage = image.CGImage;

	if (inputCGImage == nil || image.size.width < 1.0 || image.size.height < 1.0) {
		return image;
	}

	BOOL hasBlur = radius > 0.0;
	BOOL hasSaturation = ABS(saturation - 1.0) > 0.0;

	CGFloat inputImageScale = image.scale;
	CGBitmapInfo inputImageBitmapInfo = CGImageGetBitmapInfo(inputCGImage);
	CGImageAlphaInfo inputImageAlphaInfo = (inputImageBitmapInfo & kCGBitmapAlphaInfoMask);

	CGSize outputImageSizeInPoints = image.size;

	CGRect outputImageRectInPoints = CGRectMake(0, 0,
		outputImageSizeInPoints.width, outputImageSizeInPoints.height);

	BOOL useOpaqueContext =
		inputImageAlphaInfo == kCGImageAlphaNone ||
		inputImageAlphaInfo == kCGImageAlphaNoneSkipLast ||
		inputImageAlphaInfo == kCGImageAlphaNoneSkipFirst;

	UIGraphicsBeginImageContextWithOptions(outputImageSizeInPoints,
		useOpaqueContext, inputImageScale);
	CGContextRef outputContext = UIGraphicsGetCurrentContext();
	CGContextScaleCTM(outputContext, 1, -1);
	CGContextTranslateCTM(outputContext, 0, -outputImageSizeInPoints.height);

	if (hasBlur || hasSaturation) {
		vImage_Buffer effectInBuffer;
		vImage_Buffer scratchBuffer1;

		vImage_Buffer *inputBuffer;
		vImage_Buffer *outputBuffer;

		vImage_CGImageFormat format = {
			.bitsPerComponent = 8,
			.bitsPerPixel = 32,
			.colorSpace = NULL,
			.bitmapInfo = kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Little,
			.version = 0,
			.decode = NULL,
			.renderingIntent = kCGRenderingIntentDefault
		};

		vImage_Error e = vImageBuffer_InitWithCGImage(&effectInBuffer, &format,
			NULL, inputCGImage, kvImagePrintDiagnosticsToConsole);

		if (e != kvImageNoError) {
			UIGraphicsEndImageContext();
			return image;
		}

		vImageBuffer_Init(&scratchBuffer1, effectInBuffer.height,
			effectInBuffer.width, format.bitsPerPixel, kvImageNoFlags);

		inputBuffer = &effectInBuffer;
		outputBuffer = &scratchBuffer1;

		if (hasBlur) {

			//
			// A description of how to compute the box kernel width from the Gaussian
			// radius (aka standard deviation) appears in the SVG spec:
			// http://www.w3.org/TR/SVG/filters.html#feGaussianBlurElement
			//
			// For larger values of 's' (s >= 2.0), an approximation can be used: Three
			// successive box-blurs build a piece-wise quadratic convolution kernel, which
			// approximates the Gaussian kernel to within roughly 3%.
			//
			// let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
			//
			// ... if d is odd, use three box-blurs of size 'd', centered on the output pixel.
			//

			CGFloat inputRadius = MAX(2.0, radius * inputImageScale);
			uint32_t radiusInt = floor((inputRadius * 3.0 * sqrt(2.0 * M_PI) / 4.0 + 0.5) / 2.0);

			// Force radius to be odd so that the three box-blur methodology works.
			radiusInt |= 1;

			NSInteger tempBufferSize = vImageBoxConvolve_ARGB8888(
				inputBuffer,
				outputBuffer,
				NULL,
				0,
				0,
				radiusInt,
				radiusInt,
				NULL,
				kvImageGetTempBufferSize | kvImageEdgeExtend);

			void *tempBuffer = malloc(tempBufferSize);

			vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, tempBuffer,
				0, 0, radiusInt, radiusInt, NULL, kvImageEdgeExtend);

			vImageBoxConvolve_ARGB8888(outputBuffer, inputBuffer, tempBuffer,
				0, 0, radiusInt, radiusInt, NULL, kvImageEdgeExtend);

			vImageBoxConvolve_ARGB8888(inputBuffer, outputBuffer, tempBuffer,
				0, 0, radiusInt, radiusInt, NULL, kvImageEdgeExtend);

			free(tempBuffer);

			vImage_Buffer *temp = inputBuffer;
			inputBuffer = outputBuffer;
			outputBuffer = temp;
		}

		if (hasSaturation) {
			CGFloat s = saturation;

			//
			// These values appear in the W3C Filter Effects spec:
			// https://dvcs.w3.org/hg/FXTF/raw-file/default/filters/index.html#grayscaleEquivalent
			//

			CGFloat floatingPointSaturationMatrix[] = {
				0.0722 + 0.9278 * s,  0.0722 - 0.0722 * s,  0.0722 - 0.0722 * s,  0,
				0.7152 - 0.7152 * s,  0.7152 + 0.2848 * s,  0.7152 - 0.7152 * s,  0,
				0.2126 - 0.2126 * s,  0.2126 - 0.2126 * s,  0.2126 + 0.7873 * s,  0,
				0,                    0,                    0,                    1,
			};

			const int32_t divisor = 256;
			NSUInteger matrixSize = sizeof(floatingPointSaturationMatrix) /
				sizeof(floatingPointSaturationMatrix[0]);
			int16_t saturationMatrix[matrixSize];

			for (NSUInteger i = 0; i < matrixSize; ++i) {
				saturationMatrix[i] = (int16_t)roundf(floatingPointSaturationMatrix[i] * divisor);
			}

			vImageMatrixMultiply_ARGB8888(inputBuffer, outputBuffer,
				saturationMatrix, divisor, NULL, NULL, kvImageNoFlags);

			vImage_Buffer *temp = inputBuffer;
			inputBuffer = outputBuffer;
			outputBuffer = temp;
		}

		CGImageRef effectCGImage;

		if ((effectCGImage = vImageCreateCGImageFromBuffer(inputBuffer,
			&format, &cleanupBuffer, NULL, kvImageNoAllocate, NULL)) == NULL)
		{
			effectCGImage = vImageCreateCGImageFromBuffer(inputBuffer,
				&format, NULL, NULL, kvImageNoFlags, NULL);
			free(inputBuffer->data);
		}

		CGContextSaveGState(outputContext);
		CGContextDrawImage(outputContext, outputImageRectInPoints, effectCGImage);
		CGContextRestoreGState(outputContext);

		CGImageRelease(effectCGImage);
		free(outputBuffer->data);
	}
	else {
		CGContextDrawImage(outputContext, outputImageRectInPoints, inputCGImage);
	}

	if (tintColor != nil) {
		CGContextSaveGState(outputContext);
		CGContextSetFillColorWithColor(outputContext, tintColor.CGColor);
		CGContextFillRect(outputContext, outputImageRectInPoints);
		CGContextRestoreGState(outputContext);
	}

	UIImage *outputImage = UIGraphicsGetImageFromCurrentImageContext();
	UIGraphicsEndImageContext();
	return (outputImage != nil) ? outputImage : image;
}

void cleanupBuffer(void *userData, void *buf_data) {
	free(buf_data);
}

@end
