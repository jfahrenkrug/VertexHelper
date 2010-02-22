//
//  MyDocument.m
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 19.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//

#import "MyDocument.h"

@implementation MyDocument

@synthesize pointMatrix;

- (id)init
{
    self = [super init];
    if (self) {
    
        // Add your subclass-specific initialization here.
        // If an error occurs here, send a [self release] message and return nil.
		pointMatrix = [[NSMutableArray alloc] init];
    
    }
    return self;
}

- (NSString *)windowNibName
{
    // Override returning the nib file name of the document
    // If you need to use a subclass of NSWindowController or if your document supports multiple NSWindowControllers, you should remove this method and override -makeWindowControllers instead.
    return @"MyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *) aController
{
    [super windowControllerDidLoadNib:aController];
    // Add any code here that needs to be executed once the windowController has loaded the document's window.
	[imageView setImageWithURL:[NSURL URLWithString:@"file:///Users/johannes/Code/Liebherr-Ice-Crusher/Resources/ice-cubes-atlas1.png"]];
	[imageView setCurrentToolMode: IKToolModeMove];
	[imageView setDoubleClickOpensImageEditPanel:NO];
	
	
	gridLayer = [ImageViewGridLayer layer];
	gridLayer.owner = imageView;
	gridLayer.document = self;
	
	[gridLayer setNeedsDisplay];
	
	[imageView setOverlay:gridLayer forType:IKOverlayTypeImage];
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

- (IBAction)updateGrid:(id)sender 
{
	int rows = [[rowsTextField stringValue] intValue];
	int cols = [[colsTextField stringValue] intValue];
	
	
	if (rows <= 20 && cols <= 20 && (rows != gridLayer.rows || cols != gridLayer.cols)) {
		//reset our array
		[pointMatrix removeAllObjects];
		for (int r = 0; r < rows; r++) {
			[pointMatrix addObject:[NSMutableArray array]];
			for (int c = 0; c < cols; c++) {
				[[pointMatrix objectAtIndex:r] addObject:[NSMutableArray array]];
			}
		}
		
		
		gridLayer.rows = rows;
		gridLayer.cols = cols;
		[gridLayer setNeedsDisplay];
		[self updateResultTextField];
	}
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
	NSLog(@"adding point...");
	[[[pointMatrix objectAtIndex:(aRow - 1)] objectAtIndex:(aCol - 1)] addObject:[NSValue valueWithPoint:aPoint]];
	[gridLayer setNeedsDisplay];
	[self updateResultTextField];
}

- (void)updateResultTextField
{
	NSString *result = [NSString string];
	
	for (int r = 0; r < [pointMatrix count]; r++) {
		for (int c = 0; c < [[pointMatrix objectAtIndex:r] count]; c++) {
			NSMutableArray *points = [[pointMatrix objectAtIndex:r] objectAtIndex:c];
			
			// at the beginning of a different sprite...
			result = [result stringByAppendingFormat:@"//row %i, col %i\nnum = %i;\n", (r + 1), (c + 1), [points count]];
			
			for (int p = 0; p < [points count]; p++) {
				NSPoint point = [[points objectAtIndex:p] pointValue];
				result = [result stringByAppendingFormat:@"verts[%i].Set(%.1ff / PTM_RATIO, %.1ff / PTM_RATIO);\n", p, point.x, point.y];
			}
			result = [result stringByAppendingString:@"\n"];			  
		}
	}
						  
	[resultTextField setStringValue:result];
}


@end
