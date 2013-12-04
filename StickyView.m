#import "StickyView.h"

@implementation StickyView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (void)drawRect:(NSRect)rect {
	[super drawRect:rect];
}

- (void)resetCursorRects {
	NSRect frameRect = [self frame];
    [self addCursorRect:NSMakeRect(frameRect.size.width-11, 0, 11, 11)
				 cursor:[NSCursor arrowCursor]];
}

@end
