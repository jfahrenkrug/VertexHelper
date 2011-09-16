//
//  SWUndo.m
//  VertexHelper
//
//  Created by Jon Gilkison on 9/16/11.
//  Copyright 2011 Interfacelab LLC. All rights reserved.
//

#import "SWUndo.h"


@implementation SWUndo

@synthesize points, col, row;

- (id)initWithPointMatrix:(NSMutableArray *)pointMatrix col:(NSInteger)c row:(NSInteger)r 
{
    self = [super init];
    if (self) {
        col=c;
        row=r;
        points=[[NSMutableArray alloc] initWithArray:[[pointMatrix objectAtIndex:r] objectAtIndex:c] copyItems:YES];
    }
    
    return self;
}

- (void)dealloc
{
    [points release];
    [super dealloc];
}


+(SWUndo *)undoForMatrix:(NSMutableArray *)pointMatrix col:(NSInteger)c row:(NSInteger)r
{
    return [[[SWUndo alloc] initWithPointMatrix:pointMatrix col:c row:r] autorelease];
}


@end
