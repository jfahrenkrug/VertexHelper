/*
 *  VertexScanner.cpp
 *  VertexHelper
 *
 *  Created by Peter Siroki on 2010.06.20.
 *
 */

#include "VertexScanner.h"
#include <math.h>
#include <vector>

using namespace std;

static const float DEFAULT_MIN_ANGLE = 5.0f;
static const float DEFAULT_MAX_ANGLE = 179.9f;
static const float DEG_TO_RAD = M_PI/180.0f;

inline Vec2 makeVec2(float x, float y)
{
	Vec2 result = { x, y };
	return result;
}

#define VEC2OP(op) \
inline const Vec2 operator op(const Vec2 &a, const Vec2 &b) \
{ \
	Vec2 result = { a.x op b.x, a.y op b.y }; \
	return result; \
}

VEC2OP(+)
VEC2OP(-)

inline void neg(Vec2 &v)
{
	v.x = -v.x;
	v.y = -v.y;
}

/// OR is dot product
inline float operator|(const Vec2 &a, const Vec2 &b)
{
	return a.x * b.x + a.y * b.y;
}

/// XOR is cross product
inline float operator^(const Vec2 &a, const Vec2 &b)
{
	return a.x * b.y - a.y * b.x;
}

static Vec2 normalize(const Vec2 &a)
{
	float rlen = sqrtf(a.x*a.x+a.y*a.y);
	if(rlen < 1.0e-3f)
		return a;
	rlen = 1.0f/rlen;
	Vec2 result = { a.x*rlen, a.y*rlen };
	return result;
}

// anonymous namespace: symbols are not exported
namespace {

class FindPointsCall
{
	float minAngle, maxAngle;
public:
	FindPointsCall(ScanParameters *params)
	{
		// the configuration parameters give the inner angle at the vertices
		// the algorithm works with outer angles
		minAngle = DEFAULT_MIN_ANGLE*DEG_TO_RAD;
		maxAngle = DEFAULT_MAX_ANGLE*DEG_TO_RAD;
		if(params)
		{
			if(params->minimumAngle >= 0.0f)
				minAngle = params->minimumAngle*DEG_TO_RAD;
			if(params->maximumAngle >= 0.0f)
				maxAngle = params->maximumAngle*DEG_TO_RAD;
		}
		
	}
	
	
	
	vector<Vec2> removeDuplicates(vector<Vec2> &points)
	{
		if(points.size() <= 0)
			return points;
		
		vector<Vec2> result;
		Vec2 last = *(points.end()-1);
		for(int i=0; i<points.size(); i++)
		{
			Vec2 current = points[i];
			Vec2 delta = current-last;
			// the last vertex is distant enough
			if(fabs(delta.x) > 0.9f || fabs(delta.y) > 0.9f)
			{
				result.push_back(current);
				last = current;
			}
		}
		
		return result;
	}

	inline bool isConvex(float sineOfAngle, float cosineOfAngle)
	{
		float angle = atan2f(sineOfAngle, cosineOfAngle);
		//return true;
		return angle < -minAngle && angle > -maxAngle;
	}

	vector<Vec2> makeConvex(vector<Vec2> &points)
	{
		if(points.size() <= 0)
			return points;

		vector<Vec2> convex;
		convex.push_back(points[0]);
		convex.push_back(points[1]);
		Vec2 last = points[1];
		Vec2 lastIn = points[1]-points[0];
		// 1 <-- 0: lastIn
		for(int i=2; i<points.size(); i++)
		{
			Vec2 current = points[i];
			// 2 <-- 1: currentOut
			Vec2 currentIn = current-last;
			Vec2 lastInNorm = normalize(lastIn);
			Vec2 currentInNorm = normalize(currentIn);
			float cross = lastInNorm ^ currentInNorm;
			float dot = lastInNorm | currentInNorm;
			bool convexAngle = isConvex(cross, dot);
			if(!convexAngle)
			{
				// last is not part of the convex hull
				while(!convexAngle)
				{
					convex.pop_back();
					int cl = convex.size();
					currentIn = current-convex[cl-1];
					if(cl >= 2)
					{
						lastIn = convex[cl-1]-convex[cl-2];
						lastInNorm = normalize(lastIn);
						currentInNorm = normalize(currentIn);
						cross = lastInNorm ^ currentInNorm;
						dot = lastInNorm | currentInNorm;
						convexAngle = isConvex(cross, dot);
					} else
					{
						convexAngle = true;
					}

				}
			}
			convex.push_back(current);
			lastIn = currentIn;
			last = current;
		}
		// please note that this takes advantage of the findPoints algorithm
		// the points are always CCW, and the top and the bottom are always OK
		// because of the scanning
		return convex;
	}

	void operator()(ImageDesc *img, Vec2Array *output)
	{
		const unsigned char *line = img->data;
		vector<Vec2> points;
		int leftCount = 0;
		for(int y=0; y<img->height; y++)
		{
			// since it's going to be a convex hull,
			// scanning a left and right edge should suffice
			int left = -1, right = -1;
			
			for(int x=0; x<img->width; x++)
			{
				if(line[x*4+3] >= 128)
				{
					left = x;
					break;
				}
			}
			
			for(int x=img->width-1; x>=0; x--)
			{
				if(line[x*4+3] >= 128)
				{
					right = x;
					break;
				}
			}
			
			// This is tricky. The array should look like:
			// (l1, l2, l3, l4, r4, r3, r2, r1)
			// where 'l' is a left node, 'r' is a right node
			// the indices correspond to y coordinates
			
			// leftCount as an index is the position of the first r element
			// (or where the r should be inserted)
			if(left >= 0)
			{
				// (l1, l2, l3, l4, _l5_, r4, r3, r2, r1)
				points.insert(points.begin()+leftCount, makeVec2(left, y));
				// leftCounts points at r4
				leftCount++;
			}
			
			if(right >= 0)
			{
				// (l1, l2, l3, l4, l5, _r5_, r4, r3, r2, r1)
				points.insert(points.begin()+leftCount, makeVec2(right, y));
			}
			
			line += img->pitch;
		}
		if(points.size() == 0)
		{
			output->count = 0;
			output->points = NULL;
		}
		// remove duplicates and make it convex
		points = removeDuplicates(points);
		// the polygon might be a single scanline
		// in this case we extrude it
	//	points = fixSingleLine(points);
		points = makeConvex(points);

		output->count = points.size();
		output->points = (Vec2*)malloc(sizeof(Vec2)*output->count);
		for(int i=0; i<points.size(); i++)
			output->points[i] = points[i];
	}

};

}

extern "C" void findPoints(ScanParameters *scanParams, ImageDesc *img, Vec2Array *output)
{
	FindPointsCall fp(scanParams);
	fp(img, output);
}
