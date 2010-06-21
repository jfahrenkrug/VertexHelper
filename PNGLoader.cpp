/*
 *  PNGLoader.cpp
 *  VertexHelper
 *
 *  Created by Peter Siroki on 2010.06.21.
 *
 */

#include "PNGLoader.h"

// Currently it uses CoreGraphics,
// libpng would be preferable on other platforms
// On Mac it would just bloat the build unnecessarily
#import <ApplicationServices/ApplicationServices.h>

extern "C" void loadPNG(const char *fn, ImageDesc *output)
{
	CGDataProviderRef data = CGDataProviderCreateWithFilename(fn);
	CGImageRef img = CGImageCreateWithPNGDataProvider(data, NULL, true, kCGRenderingIntentDefault);
	CGDataProviderRelease(data);
	
	int width, height, pitch;
	
	width = output->width = CGImageGetWidth(img);
	height = output->height = CGImageGetHeight(img);
	pitch = output->pitch = width*4;

	UInt8 *bits = (UInt8*)malloc(width * height * 4);
	CGContextRef bitmapContext = CGBitmapContextCreate(bits, width, height, 8, pitch,
														CGImageGetColorSpace(img), kCGImageAlphaPremultipliedLast);
	CGContextTranslateCTM(bitmapContext, 0, output->height);
	CGContextScaleCTM(bitmapContext, 1.0, -1.0);
	CGContextDrawImage(bitmapContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), img);
	CGContextRelease(bitmapContext);
	
	output->data = bits;
	
	CGImageRelease(img);
}
