/* BackgroundView */

#import <Cocoa/Cocoa.h>

@class ControllableScroller;

@interface BackgroundView : NSView
{
	NSImage *metalImage;
	NSImage *metalResizeImage;
	NSImage *lightImage;
	
	BOOL	displayResizeIndicator;
	BOOL	isResizing;
	NSPoint oldPos;
	NSSize  paddingSize;
	
	ControllableScroller	*scroller;
	NSScrollView	*scrollView;
}

- (void)setDisplayResizeIndicator:(BOOL)flag;

- (void)setScroller:(ControllableScroller *)scroller;
- (void)setScrollView:(NSScrollView *)view;

@end
