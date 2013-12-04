/* ResizeView */

#import <Cocoa/Cocoa.h>

@interface ResizeView : NSView
{
	NSImage *indicatorImage;
	NSPoint  oldPos;
	NSPoint startPos;
	NSSize  startSize;
	BOOL	doAdjust;
	float	startTop;
}

- (void)setDoAdjust:(BOOL)flag;

@end
