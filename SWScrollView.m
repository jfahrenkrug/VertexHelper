//
//  SWScrollView.m
//  VertexHelper
//
//  Code from Nicholas Riley
//
//  Created by Nicholas Riley on 1/25/10.
//  Copyright 2010 Nicholas Riley. All rights reserved.
//

#import "SWScrollView.h"
#import <Quartz/Quartz.h>

@interface IKImageClipView : NSClipView
- (NSRect)docRect;
@end

@implementation SWScrollView

- (void)reflectScrolledClipView:(NSClipView *)cView;
{
    NSView *_imageView = [self documentView];
    [super reflectScrolledClipView:cView];
    if ([_imageView isKindOfClass:[IKImageView class]] &&
        [[self contentView] isKindOfClass:[IKImageClipView class]] &&
        [[self contentView] respondsToSelector:@selector(docRect)]) {
        NSSize docSize = [(IKImageClipView *)[self contentView] docRect].size;
        NSSize scrollViewSize = [self contentSize];
  
        if (docSize.height > scrollViewSize.height || docSize.width > scrollViewSize.width)
            ((IKImageView *)_imageView).autohidesScrollers = NO;
        else
            ((IKImageView *)_imageView).autohidesScrollers = YES;
    }
}

@end
