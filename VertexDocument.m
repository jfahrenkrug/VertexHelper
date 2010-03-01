//
//  VertexDocument.m
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 19.02.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//

#import "VertexDocument.h"

#define VHTYPE_PURE		0
#define VHTYPE_BOX2D	1
#define VHTYPE_CHIPMUNK 2

#define VHSTYLE_ASSIGN	0
#define VHSTYLE_INIT	1

@implementation VertexDocument

@synthesize pointMatrix;

- (id)init
{
    self = [super init];
    if (self) {
		pointMatrix = [[NSMutableArray alloc] init];
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
	
	[imageView setImageWithURL:	[NSURL URLWithString:[NSString stringWithFormat:@"file://%@", [[NSBundle mainBundle] pathForImageResource:@"drop_sprite.png"]]]];
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
				result = [result stringByAppendingFormat:@"num = %i;\n", [points count]];
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
									result = [result stringByAppendingFormat:@"b2Vec2 %@[] = {", variableName];
								}
								
								result = [result stringByAppendingFormat:@"b2Vec2(%@)", itemString];
								
								if (p + 1 == [points count]) {
									result = [result stringByAppendingString:@"};\n"];
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
									result = [result stringByAppendingFormat:@"CGPoint %@[] = {", variableName];
								}
								
								result = [result stringByAppendingString:itemString];
								
								if (p + 1 == [points count]) {
									result = [result stringByAppendingString:@"};\n"];
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

- (void)dealloc
{
	[pointMatrix release];
	
	[super dealloc];
}


@end
