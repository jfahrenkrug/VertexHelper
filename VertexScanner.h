/*
 *  VertexScanner.h
 *  VertexHelper
 *
 *  Created by Peter Siroki on 2010.06.20.
 *
 */

#pragma once

#include <stdlib.h>

#ifdef __cplusplus
extern "C" {
#endif

typedef struct Vec2_
{
	float x, y;
} Vec2;

typedef struct Vec2Array_
{
	size_t count;
	Vec2 *points;
} Vec2Array;

typedef struct ImageDesc_
{
	/// Width of the image in pixels
	size_t width;
	/// Height of the image in pixels
	size_t height;
	/// Number of bytes between rows
	size_t pitch;
	/// Pointer to image data
	const unsigned char *data;
} ImageDesc;

/// 
/**
 * Finds the vertices of the convex hull
 *	@param img
 *		the image to scan (assumes it is RGBA, 8 bit wide each)
 *	@param output
 *		the resulting array will be loaded here
 *		(output only, the contents of the struct will be discarded)
 */
void findPoints(ImageDesc *img, Vec2Array *output);

#ifdef __cplusplus
}
#endif

