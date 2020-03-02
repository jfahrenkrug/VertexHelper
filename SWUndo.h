//
//  SWUndo.h
//  VertexHelper
//
//  Created by Jon Gilkison on 9/16/11.
//  Copyright 2011 Interfacelab LLC. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface SWUndo : NSObject {
    NSInteger col,row;
    NSMutableArray *points;
}

@property (readonly) NSInteger col;
@property (readonly) NSInteger row;
@property (readonly) NSMutableArray *points;

+(SWUndo *)undoForMatrix:(NSMutableArray *)pointMatrix col:(NSInteger)c row:(NSInteger)r;

@end
