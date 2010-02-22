//
//  ImageViewGridLayer.h
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 20.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

@class MyDocument;

@interface ImageViewGridLayer : CALayer {
	IKImageView *owner;
	MyDocument *document;
	int rows;
	int cols;
}
@property (assign) IKImageView *owner;
@property (assign) MyDocument *document;
@property (assign) int rows;
@property (assign) int cols;

@end
