//
//  ImageViewGridLayer.h
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 20.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//
//  Concave Polygons Bug Fixed by Ivan Bastidas on 09/05/2010.

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

@class VertexDocument;

@interface ImageViewGridLayer : CALayer {
	IKImageView *owner;
	VertexDocument *document;
	int rows;
	int cols;
	CGColorRef green;
	CGColorRef gray;
}
@property (assign) IKImageView *owner;
@property (assign) VertexDocument *document;
@property (assign) int rows;
@property (assign) int cols;
-(BOOL) calcWithPoint:(CGPoint)point1 secondPoint: (CGPoint)point2 thirdPoint:(CGPoint)point3 fourthPoint: (CGPoint)point4;
@end
