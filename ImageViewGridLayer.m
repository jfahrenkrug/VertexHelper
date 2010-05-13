//
//  ImageViewGridLayer.m
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 20.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//
//	Concave Polygons Bug Fixed by Ivan Bastidas on 09/05/2010.

#import "ImageViewGridLayer.h"
#import "VertexDocument.h"
#define RAD_TO_DEG(rad) ( (180.0 * (rad)) / M_PI )
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
			
			NSMutableArray *points = [[document.pointMatrix objectAtIndex:(currentRow - 1)] objectAtIndex:(currentCol - 1)];
			if ([points count]>1 ) {
				
			NSPoint point3 = [[points objectAtIndex:[points count]-2] pointValue];
			NSPoint point2 = [[points objectAtIndex:[points count]-1] pointValue];
			NSPoint point1 = [[points objectAtIndex:0] pointValue];
			
				if ([self  calcWithPoint:point1 secondPoint:point2 thirdPoint:relativePoint fourthPoint:point3]) {
					[document addPoint:relativePoint forRow:currentRow col:currentCol];
				}else {
					return nil; 
				}

			
			}else {
				[document addPoint:relativePoint forRow:currentRow col:currentCol];
			}

			 
		}
		
	}
	
	if(NSPointInRect(hitPoint, NSRectFromCGRect([self bounds]))) {
		return self;
	} else {
		return nil;    
	}
}
-(BOOL) calcWithPoint:(CGPoint)point1 secondPoint: (CGPoint)point2 thirdPoint:(CGPoint)point3 fourthPoint: (CGPoint)point4{
	double ang1 = RAD_TO_DEG(atan2(point2.y-point1.y,point2.x - point1.x));
	//NSLog(@"Angulo 1 = %1.2f",ang1);
	if (ang1<0) {
		ang1 = 180+ang1;
	}
	//NSLog(@"Transformado = %1.2f",ang1);
	double ang2 = RAD_TO_DEG(atan2(point3.y-point2.y,point3.x - point2.x));
	
	//NSLog(@"Angulo 2 = %1.2f",ang2);
	if (ang2>=0) {
		ang2 = 180-ang2;
	}else {
		ang2 = (ang2+180) * -1;
	}
	//NSLog(@"Transformado = %1.2f",ang2);
	
	double total = ang1+ang2;
	
	
	double ang3 = RAD_TO_DEG(atan2(point2.y-point4.y,point2.x - point4.x));
	//NSLog(@"Angulo 3 = %1.2f",ang3);
	if (ang3<0) {
		ang3 = 180+ang3;
		ang2 = RAD_TO_DEG(atan2(point3.y-point2.y,point3.x - point2.x))*-1;
	}
	
	//NSLog(@"Transformado = %1.2f",ang3);
	
	double total2 = ang2+ang3;
	//NSLog(@"Angulo Interno Suma = %1.2f",total);
	//NSLog(@"Angulo Interno = %1.2f",total2);
	if ((total <= 180 && total>=0) && (total2 <= 180 && total2>=0)) {

		return YES;
	
	}else {
		return NO;
	}
	
	
}

- (void)dealloc
{
	CGColorRelease(gray);
	CGColorRelease(green);
	
	[super dealloc];
}


@end