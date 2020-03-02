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
	
typedef struct ScanParameters_
{
	/// Minimum angle at the vertices in degrees.
	/// Should be a couple degrees.
	/// Negative values are replaced with the default
	/// value (5 degrees).
	float minimumAngle;
	/// Maximum angle at the vertices in degrees.
	/// Should be at most couple degree seconds less than 180.
	/// A value close to 180 would mean a very sharp spike
	/// Negative values are replaced with the default
	/// value (179.9 degrees).
	float maximumAngle;
} ScanParameters;

/**
 * Finds the vertices of the convex hull
 *	@param scanParams
 *		parameters for scanning (see ScanParameters), safe to pass NULL
 *		(in case the routine will use default values)
 *	@param img
 *		the image to scan (assumes it is RGBA, 8 bit wide each)
 *	@param output
 *		the resulting array will be loaded here
 *		(output only, the contents of the struct will be discarded)
 */
void findPoints(ScanParameters *scanParams, ImageDesc *img, Vec2Array *output);

#ifdef __cplusplus
}
#endif

