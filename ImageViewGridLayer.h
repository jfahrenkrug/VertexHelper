//
//  ImageViewGridLayer.h
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 20.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//

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

@end
