#import "DraggableView.h"

@implementation DraggableView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (void)mouseDown:(NSEvent *)theEvent {
	NSPoint globalPos = [NSEvent mouseLocation];
	NSRect frameRect = [[self window] frame];
	paddingSize = NSMakeSize(globalPos.x - frameRect.origin.x, globalPos.y - frameRect.origin.y);
}

- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint globalPos = [NSEvent mouseLocation];
	NSWindow *window = [self window];
	NSRect frame = [[self window] frame];
	frame.origin.x = globalPos.x - paddingSize.width;
	frame.origin.y = globalPos.y - paddingSize.height;
	[window setFrame:frame display:YES];
}

@end

