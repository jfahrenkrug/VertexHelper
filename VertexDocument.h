//
//  VertexDocument.h
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 19.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#import "SWImageView.h"
#import "ImageViewGridLayer.h"

@class PrioritySplitViewDelegate;

@interface VertexDocument : NSDocument
{
	IBOutlet NSTextField *rowsTextField;
	IBOutlet NSTextField *colsTextField;
	IBOutlet NSTextView *resultTextView;
	IBOutlet SWImageView *imageView;
	
	IBOutlet NSButton *zoomInButton;
	IBOutlet NSButton *zoomOutButton;
	IBOutlet NSButton *actualSizeButton;
	IBOutlet NSButton *editModeCheckbox;
	
	IBOutlet NSTextField *variableTextField;
	IBOutlet NSPopUpButton *typePopUpButton;
	IBOutlet NSPopUpButton *stylePopUpButton;
	
	IBOutlet NSSplitView *splitView;
	PrioritySplitViewDelegate *splitViewDelegate;
	
	ImageViewGridLayer *gridLayer;
	// each row has columns, each column has points
	NSMutableArray *pointMatrix;
	NSString *filePath;
	BOOL gridOK;
	BOOL imageLoaded;
}

- (IBAction)updateGrid:(id)sender;
- (IBAction)makeAnnotatable:(id)sender;
- (IBAction)updateOutput:(id)sender;

- (IBAction)scanImage:(id)sender;
- (IBAction)resetVertices:(id)sender;

- (void)addPoint:(NSPoint)aPoint forRow:(int)aRow col:(int)aCol;
- (void)updateResultTextField;

@property (readonly) NSMutableArray *pointMatrix;
@property (readonly) BOOL imageLoaded;

@end
