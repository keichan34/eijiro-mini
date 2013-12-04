//
//  ControllableScroller.h
//  Mini EIJIRO
//
//  Created by numata on Sun Jan 18 2004.
//  Copyright (c) 2004 Satoshi NUMATA. All rights reserved.
//

#import <Cocoa/Cocoa.h>


@interface ControllableScroller : NSScroller {
	NSScrollView	*scrollView;
}

- (void)setScrollView:(NSScrollView *)view;
- (void)setResizeView:(NSView *)view;

@end
