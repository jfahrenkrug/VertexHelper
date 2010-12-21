//
//  VertexDocument.m
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 19.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//

#import "VertexDocument.h"
#import "VertexScanner.h"
#import "PrioritySplitViewDelegate.h"
#import <AppKit/AppKit.h>

#define VHTYPE_PURE		0
#define VHTYPE_BOX2D	1
#define VHTYPE_CHIPMUNK 2

#define VHSTYLE_ASSIGN	0
#define VHSTYLE_INIT	1

@interface VertexDocument(PrivateAPI)
- (void)setUpSplitViewDelegate;
- (BOOL)hasPointsDefined;
- (void)setUpPointMatrixForRows:(int)rows cols:(int)cols;
- (void)enableUI:(BOOL)enable;
@end


@implementation VertexDocument

@synthesize pointMatrix, imageLoaded;

- (id)init
{
    self = [super init];
    if (self) {
		pointMatrix = [[NSMutableArray alloc] init];
		imageLoaded = NO;
    }
    return self;
}

- (NSString *)windowNibName
{
    return @"VertexDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
	
	[self setUpSplitViewDelegate];
	
	[imageView setImageWithURL:	[NSURL fileURLWithPath:[[NSBundle mainBundle] pathForImageResource:@"drop_sprite.png"]]];
	[imageView setCurrentToolMode: IKToolModeMove];
	[imageView setDoubleClickOpensImageEditPanel:NO];
	
	gridLayer = [ImageViewGridLayer layer];
	gridLayer.owner = imageView;
	gridLayer.document = self;
	
	[gridLayer setNeedsDisplay];
	
	[imageView setOverlay:gridLayer forType:IKOverlayTypeImage];
	imageView.supportsDragAndDrop = NO;
	
	NSWindow *window = [aController window];
	[window registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
	[window setDelegate:self];
	
	filePath = nil;
	gridOK = NO;
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to write your document to data of the specified type. If the given outError != NULL, ensure that you set *outError when returning nil.

    // You can also choose to override -fileWrapperOfType:error:, -writeToURL:ofType:error:, or -writeToURL:ofType:forSaveOperation:originalContentsURL:error: instead.

    // For applications targeted for Panther or earlier systems, you should use the deprecated API -dataRepresentationOfType:. In this case you can also choose to override -fileWrapperRepresentationOfType: or -writeToFile:ofType: instead.

    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
	return nil;
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    // Insert code here to read your document from the given data of the specified type.  If the given outError != NULL, ensure that you set *outError when returning NO.

    // You can also choose to override -readFromFileWrapper:ofType:error: or -readFromURL:ofType:error: instead. 
    
    // For applications targeted for Panther or earlier systems, you should use the deprecated API -loadDataRepresentation:ofType. In this case you can also choose to override -readFromFile:ofType: or -loadFileWrapperRepresentation:ofType: instead.
    
    if ( outError != NULL ) {
		*outError = [NSError errorWithDomain:NSOSStatusErrorDomain code:unimpErr userInfo:NULL];
	}
    return YES;
}

- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender
{
	if ([NSImage canInitWithPasteboard:[sender draggingPasteboard]]) {
		return NSDragOperationCopy; //accept data
	}
	
    return NSDragOperationNone;
}

- (BOOL)prepareForDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject:NSFilenamesPboardType])
	{
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		return [files count] == 1;
	}
	return YES;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
	NSPasteboard *pboard = [sender draggingPasteboard];
	if([[pboard types] containsObject:NSFilenamesPboardType])
	{
		NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
		if([files count] == 1)
		{
			filePath = [files objectAtIndex:0];
			[imageView setImageWithURL:[NSURL fileURLWithPath:filePath]];
			imageLoaded = YES;
			[self enableUI:YES];
			[self updateGrid:self];
		}
	}
	return YES;
}

- (IBAction)updateGrid:(id)sender 
{
	int rows = [[rowsTextField stringValue] intValue];
	int cols = [[colsTextField stringValue] intValue];

	gridOK = rows > 0 && cols > 0;
	
	
	if (rows <= 50 && cols <= 50 && (rows != gridLayer.rows || cols != gridLayer.cols)) {
		if ([self hasPointsDefined]) {
			NSAlert *alert = [NSAlert alertWithMessageText:@"Reset all the vertices?"
											 defaultButton:@"Yes, reset them." alternateButton:@"Cancel"
											   otherButton:nil informativeTextWithFormat:@"Changing the number of rows and columns will reset all the vertices you have defined."];
			
			if ([alert runModal] != NSAlertDefaultReturn) {
				NSLog(@"clicked no");
				rowsTextField.stringValue = [NSString stringWithFormat:@"%i", gridLayer.rows];
				colsTextField.stringValue = [NSString stringWithFormat:@"%i", gridLayer.cols];
				
				return;
			}
		}
		
		//reset our array
		[self setUpPointMatrixForRows:rows cols:cols];
		
		gridLayer.rows = rows;
		gridLayer.cols = cols;
		[gridLayer setNeedsDisplay];
		[self updateResultTextField];
	}
}

- (IBAction)resetVertices:(id)sender
{
	NSAlert *alert = [NSAlert alertWithMessageText:@"Reset all the vertices?"
									 defaultButton:@"Yes, reset them." alternateButton:@"Cancel"
									   otherButton:nil informativeTextWithFormat:@""];
	
	if ([alert runModal] == NSAlertDefaultReturn) {
		int rows = [[rowsTextField stringValue] intValue];
		int cols = [[colsTextField stringValue] intValue];
		[self setUpPointMatrixForRows:rows cols:cols];
		[gridLayer setNeedsDisplay];
		[self updateResultTextField];
	}
}



- (IBAction)scanImage:(id)sender
{
	[self updateGrid:sender];

	CGImageRef img = [imageView image];
	size_t width = CGImageGetWidth(img);
	size_t height = CGImageGetHeight(img);
	size_t pitch = width*4;
	
	UInt8 *bits = (UInt8*)malloc(width * height * 4);
	memset(bits, 0, width*height*4);
	CGContextRef bitmapContext = CGBitmapContextCreate(bits, width, height, 8, pitch,
													  CGImageGetColorSpace(img), kCGImageAlphaPremultipliedLast);
	CGContextTranslateCTM(bitmapContext, 0, height);
	CGContextScaleCTM(bitmapContext, 1.0, -1.0);
	CGContextDrawImage(bitmapContext, CGRectMake(0.0, 0.0, (CGFloat)width, (CGFloat)height), img);
	CGContextRelease(bitmapContext);
	
	const UInt8 *data = bits;
	int cellWidth = (width / gridLayer.cols);
	int cellHeight = (height / gridLayer.rows);
	
	for(int cy=0; cy<[pointMatrix count]; cy++)
	{
		NSArray *cells = [pointMatrix objectAtIndex:cy];
		for(int cx=0; cx<[cells count]; cx++)
		{
			ImageDesc cell;
			cell.width = cellWidth;
			cell.height = cellHeight;
			// the CGImage is a bottom-up image
			cell.pitch = pitch;
			// so data will point to the last row
			cell.data = data;
			// also offset it by the coordinates of the cell
			cell.data += (cx*cellWidth*4)+(cy*cellHeight*pitch);
			Vec2Array points;
			findPoints(&cell, &points);
			if(points.count > 0)
			{
				NSMutableArray *arr = [cells objectAtIndex: cx];
				[arr removeAllObjects];
				for(int i=0; i<points.count; i++)
				{
					Vec2 p = points.points[i];
					p.x -= cellWidth*0.5f;
					p.y -= cellHeight*0.5f;
					[arr addObject:[NSValue valueWithPoint:NSMakePoint(p.x, p.y)]];
				}
			}
			if(points.points)
				free(points.points);
		}
	}
	free(bits);
	[gridLayer setNeedsDisplay];
	[self updateResultTextField];
}

- (IBAction)updateOutput:(id)sender
{
	[self updateResultTextField];
}

- (IBAction)makeAnnotatable:(id)sender 
{
	if ([(NSButton *)sender state] == NSOnState) {
		[imageView setCurrentToolMode: IKToolModeAnnotate];
	} else {
		[imageView setCurrentToolMode: IKToolModeMove];
	}

}

- (void)addPoint:(NSPoint)aPoint forRow:(int)aRow col:(int)aCol 
{
	[[[pointMatrix objectAtIndex:(aRow - 1)] objectAtIndex:(aCol - 1)] addObject:[NSValue valueWithPoint:aPoint]];
	[gridLayer setNeedsDisplay];
	[self updateResultTextField];
}

- (void)updateResultTextField
{
	NSString *result = [NSString string];
	NSString *variableName = [variableTextField stringValue];
	
	if (!variableName || [variableName length] < 1) {
		variableName = @"verts";
	}
	
	for (int r = [pointMatrix count] - 1; r >= 0; r--) {
		for (int c = 0; c < [[pointMatrix objectAtIndex:r] count]; c++) {
			NSMutableArray *points = [[pointMatrix objectAtIndex:r] objectAtIndex:c];
			NSString *itemString = nil;
			
			// at the beginning of a different sprite...
			result = [result stringByAppendingFormat:@"//row %i, col %i\n", ([pointMatrix count] - r), (c + 1)];
			
			if ([typePopUpButton selectedTag] != VHTYPE_PURE) {
				result = [result stringByAppendingFormat:@"int num = %i;\n", [points count]];
			}
			
			for (int p = 0; p < [points count]; p++) {
				NSPoint point = [[points objectAtIndex:p] pointValue];
				switch ([typePopUpButton selectedTag]) {
					case VHTYPE_PURE:
						result = [result stringByAppendingFormat:@"%.1f, %.1f\n", p, point.x, point.y];
						break;
					case VHTYPE_BOX2D:
						itemString = [NSString stringWithFormat:@"%.1ff / PTM_RATIO, %.1ff / PTM_RATIO", point.x, point.y];
						switch ([stylePopUpButton selectedTag]) {
							case VHSTYLE_ASSIGN:
								result = [result stringByAppendingFormat:@"%@[%i].Set(%@);\n", variableName, p, itemString];
								break;
							case VHSTYLE_INIT:
								if (p == 0) {
									result = [result stringByAppendingFormat:@"b2Vec2 %@[] = {\n", variableName];
								}
								
								result = [result stringByAppendingFormat:@"    b2Vec2(%@)", itemString];
								
								if (p + 1 == [points count]) {
									result = [result stringByAppendingString:@"\n};\n"];
								} else {
									result = [result stringByAppendingString:@",\n"];
								}

								break;
							default:
								break;
						}
						
						break;
					case VHTYPE_CHIPMUNK:
						itemString = [NSString stringWithFormat:@"cpv(%.1ff, %.1ff)", point.x, point.y];
						switch ([stylePopUpButton selectedTag]) {
							case VHSTYLE_ASSIGN:
								result = [result stringByAppendingFormat:@"%@[%i] = %@;\n", variableName, p, itemString];
								break;
							case VHSTYLE_INIT:
								if (p == 0) {
									result = [result stringByAppendingFormat:@"CGPoint %@[] = {\n", variableName];
								}
								
                                result = [result stringByAppendingString:@"    "];    
								result = [result stringByAppendingString:itemString];
								
								if (p + 1 == [points count]) {
									result = [result stringByAppendingString:@"\n};\n"];
								} else {
									result = [result stringByAppendingString:@",\n"];
								}
								
								break;
							default:
								break;
						}
						
						break;
					default:
						break;
				}
			}
			result = [result stringByAppendingString:@"\n"];			  
		}
	}
						  
	[resultTextView setString: result];
}

- (BOOL)hasPointsDefined 
{
	for (int r = [pointMatrix count] - 1; r >= 0; r--) {
		for (int c = 0; c < [[pointMatrix objectAtIndex:r] count]; c++) {
			NSMutableArray *points = [[pointMatrix objectAtIndex:r] objectAtIndex:c];
			
			if ([points count] > 0) {
				return YES;
			}
		}
	}
	
	return NO;
}

- (void)setUpPointMatrixForRows:(int)rows cols:(int)cols 
{
	[pointMatrix removeAllObjects];
	for (int r = 0; r < rows; r++) {
		[pointMatrix addObject:[NSMutableArray array]];
		for (int c = 0; c < cols; c++) {
			[[pointMatrix objectAtIndex:r] addObject:[NSMutableArray array]];
		}
	}	
}

- (void)enableUI:(BOOL)enable
{
	[zoomInButton setEnabled:enable];
	[zoomOutButton setEnabled:enable];
	[actualSizeButton setEnabled:enable];
	[editModeCheckbox setEnabled:enable];
	
	[rowsTextField setEnabled:enable];
	[colsTextField setEnabled:enable];
	[variableTextField setEnabled:enable];
	[typePopUpButton setEnabled:enable];
	[stylePopUpButton setEnabled:enable];
}

#pragma mark -
#pragma mark SplitViewDelegate Set Up 

- (void)setUpSplitViewDelegate 
{
	splitViewDelegate = [[PrioritySplitViewDelegate alloc] init];
	
	[splitViewDelegate setPriority:0 forViewAtIndex:0]; // top priority for top view
	[splitViewDelegate setMinimumLength:100 forViewAtIndex:0];
	[splitViewDelegate setPriority:1 forViewAtIndex:1];
	[splitViewDelegate setMinimumLength:[[[splitView subviews] objectAtIndex:1] frame].size.height forViewAtIndex:1];
	
	[splitView setDelegate:splitViewDelegate];
}

#pragma mark -
#pragma mark Menu Delegate Methods
- (BOOL) validateMenuItem: (NSMenuItem *) menuItem
{
	BOOL enable = NO;
	
    if ([menuItem action] == @selector(resetVertices:))
    {
		enable = self.imageLoaded;
    }
    else if ([menuItem action] == @selector(scanImage:))
    {
		enable = self.imageLoaded;
    }
    else
    {
        enable = [super validateMenuItem:menuItem]; 
    }
	
    return enable;
}

- (void)dealloc
{
	[pointMatrix release];
	[splitView setDelegate:nil];
	[splitViewDelegate release];
	
	[super dealloc];
}


@end
