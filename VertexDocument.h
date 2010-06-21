//
//  VertexDocument.h
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 19.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>
#import "ImageViewGridLayer.h"

@interface VertexDocument : NSDocument
{
	IBOutlet NSTextField *rowsTextField;
	IBOutlet NSTextField *colsTextField;
	IBOutlet NSTextView *resultTextView;
	IBOutlet IKImageView *imageView;
	
	IBOutlet NSTextField *variableTextField;
	IBOutlet NSPopUpButton *typePopUpButton;
	IBOutlet NSPopUpButton *stylePopUpButton;
	
	IBOutlet NSButton *scanButton;
	
	ImageViewGridLayer *gridLayer;
	// each row has columns, each column has points
	NSMutableArray *pointMatrix;
}

- (IBAction)updateGrid:(id)sender;
- (IBAction)makeAnnotatable:(id)sender;
- (IBAction)updateOutput:(id)sender;

- (IBAction)scanImage:(id)sender;

- (void)addPoint:(NSPoint)aPoint forRow:(int)aRow col:(int)aCol;
- (void)updateResultTextField;

@property (readonly) NSMutableArray *pointMatrix;

@end
