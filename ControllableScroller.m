//
//  ControllableScroller.m
//  Mini EIJIRO
//
//  Created by numata on Sun Jan 18 2004.
//  Copyright (c) 2004 Satoshi NUMATA. All rights reserved.
//

#import "ControllableScroller.h"


@implementation ControllableScroller

- (void)setScrollView:(NSScrollView *)view {
	scrollView = view;
}

- (void)setResizeView:(NSView *)view {
	NSView *parentView = [view superview];
	[view removeFromSuperviewWithoutNeedingDisplay];
	[parentView addSubview:view positioned:NSWindowAbove relativeTo:self];
}

- (void)setFrame:(NSRect)frameRect {
	NSRect parentRect = [scrollView frame];
	[super setFrame:
		NSMakeRect(parentRect.size.width-11, 0, 11, parentRect.size.height-11)];
}

- (void)setFrameOrigin:(NSPoint)newOrigin {
	NSRect parentRect = [scrollView frame];
	[super setFrameOrigin:NSMakePoint(parentRect.size.width-11, 0)];
}
 
- (void)setFrameSize:(NSSize)newSize {
	NSRect parentRect = [scrollView frame];
	[super setFrameSize:NSMakeSize(11, parentRect.size.height-11)];
}
 
@end
