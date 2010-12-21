//
//  SWImageView.m
//  VertexHelper
//
//  Created by Johannes Fahrenkrug on 21.12.10.
//  Copyright 2010 Springenwerk. All rights reserved.
//

#import "SWImageView.h"


@implementation SWImageView


// this is a hack. We don't want to see the red annotation circles
// when we drag in annotation mode. So we swallow drag events
// unless we're in move mode.
- (void)mouseDragged:(NSEvent *)theEvent {	
	if (self.currentToolMode == IKToolModeMove) {
		[super mouseDragged:theEvent];
	}
}


@end
