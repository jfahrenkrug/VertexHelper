//
//  ImageViewGridLayer.m
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 20.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//

#import "ImageViewGridLayer.h"
#import "VertexDocument.h"

// Thanks to Bill Dudney (http://bill.dudney.net/roller/objc/entry/nscolor_cgcolorref)
@interface NSColor(CGColor)
- (CGColorRef)CGColor;
@end

@implementation NSColor(CGColor)
- (CGColorRef)CGColor {
    CGColorSpaceRef colorSpace = [[self colorSpace] CGColorSpace];
    NSInteger componentCount = [self numberOfComponents];
    CGFloat *components = (CGFloat *)calloc(componentCount, sizeof(CGFloat));
    [self getComponents:components];
    CGColorRef color = CGColorCreate(colorSpace, components);
    free((void*)components);
    return color;
}
@end


@implementation ImageViewGridLayer

@synthesize owner, document, rows, cols;

// -------------------------------------------------------------------------
//	init
// -------------------------------------------------------------------------
- (id) init
{
	if((self = [super init])){
		//needs to redraw when bounds change
		[self setNeedsDisplayOnBoundsChange:YES];
		green = [[NSColor greenColor] CGColor];
		gray = [[NSColor grayColor] CGColor];
	}
	
	return self;
}

// -------------------------------------------------------------------------
//	actionForKey:
//
// always return nil, to never animate
// -------------------------------------------------------------------------
- (id<CAAction>)actionForKey:(NSString *)event
{
	return nil;
}

// -------------------------------------------------------------------------
//	drawInContext:
//
// draw a metal background that scrolls when the image browser scroll
// -------------------------------------------------------------------------
- (void)drawInContext:(CGContextRef)context
{
	//retreive bounds and visible rect
	NSSize imageSize = [owner imageSize];
	
	
	int i = 0;
	float colWidth = (imageSize.width / cols);
	float rowHeight = (imageSize.height / rows);
	
	CGContextSetLineWidth(context, 1.0);
	
	for (i = 0; i <= cols; i++) {
		CGContextMoveToPoint(context, (imageSize.width / cols) * i, 0);
		CGContextAddLineToPoint(context, (imageSize.width / cols) * i, imageSize.height);
	}
	
	for (i = 0; i <= rows; i++) {
		CGContextMoveToPoint(context, 0, (imageSize.height / rows) * i);
		CGContextAddLineToPoint(context, imageSize.width, (imageSize.height / rows) * i);
	}
	
	CGContextStrokePath(context);
	
	// now we stroke the points...
	for (int r = 0; r < [document.pointMatrix count]; r++) {
		for (int c = 0; c < [[document.pointMatrix objectAtIndex:r] count]; c++) {
			NSMutableArray *points = [[document.pointMatrix objectAtIndex:r] objectAtIndex:c];
			float originX = (imageSize.width / cols) * c;
			float originY = (imageSize.height / rows) * r;
			float firstX = 0;
			float firstY = 0;
			float lastX = 0;
			float lastY = 0;
			
			// at the beginning of a different sprite...
			
			if ([points count] > 1) {
				for (int p = 0; p < [points count]; p++) {
					float x = [[points objectAtIndex:p] pointValue].x + (colWidth / 2) + originX;
					float y = [[points objectAtIndex:p] pointValue].y + (rowHeight / 2) + originY;
					
					
					if (p == 0) {
						CGContextMoveToPoint(context, x, y);
						firstX = x;
						firstY = y;
					} else {
						CGContextAddLineToPoint(context, x, y);
						lastX = x;
						lastY = y;
					}

				}
				CGContextSetStrokeColorWithColor(context, green);
				CGContextStrokePath(context);
				
				// the last "auto-connected" line will have a different color...
				CGContextSetStrokeColorWithColor(context, gray);
				CGContextMoveToPoint(context, lastX, lastY);
				CGContextAddLineToPoint(context, firstX, firstY);
				CGContextStrokePath(context);
			}
		}
	}
	
	CGContextStrokePath(context);
}

-(CALayer *)hitTest:(CGPoint)aPoint {
	//NSLog(@"hittest x: %.f, y: %.f", aPoint.x, aPoint.y);
	// don't allow any mouse clicks for subviews in this view
    NSPoint hitPoint = NSPointFromCGPoint(aPoint);
    
	if (owner.currentToolMode == IKToolModeAnnotate) {
		NSPoint p = [owner convertViewPointToImagePoint:hitPoint];
		//NSLog(@"hittest x: %.f, y: %.f", p.x, p.y);
		NSSize imageSize = [owner imageSize];
		NSPoint relativePoint = NSMakePoint(0, 0);
		float colWidth = (imageSize.width / cols);
		float rowHeight = (imageSize.height / rows);
		
		float yExtra = (int)(p.y) %  (int)rowHeight;
		float xExtra = (int)p.x % (int)colWidth;
		int currentRow = p.y / rowHeight + (yExtra > 0 ? 1 : 0); 
		int currentCol = p.x / colWidth + (xExtra > 0 ? 1 : 0);
		
		if (currentRow > 0 && currentCol > 0 && currentCol <= cols && currentRow <= rows) {
			relativePoint.x = (p.x - ((currentCol - 1) * colWidth)) - (colWidth / 2);
			relativePoint.y = (p.y - ((currentRow - 1) * rowHeight)) - (rowHeight / 2);
			
			[document addPoint:relativePoint forRow:currentRow col:currentCol];
		}
		
	}
	
	if(NSPointInRect(hitPoint, NSRectFromCGRect([self bounds]))) {
		return self;
	} else {
		return nil;    
	}
}

- (void)dealloc
{
	CGColorRelease(gray);
	CGColorRelease(green);
	
	[super dealloc];
}


@end