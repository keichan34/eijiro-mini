#import "StickyWindow.h"

@implementation StickyWindow

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	self = [super initWithContentRect:contentRect
							styleMask:NSBorderlessWindowMask
							  backing:backingType
								defer:flag];
	if (self) {
		[self setBackgroundColor: [NSColor clearColor]];
		[self setLevel:NSStatusWindowLevel];
		[self setAlphaValue:1.0];
		[self setOpaque:NO];
		[self setHasShadow:NO];
		[self setMovableByWindowBackground:NO];
	}
	return self;
}

- (BOOL)becomesKeyOnlyIfNeeded {
	return YES;
}

- (BOOL)canBecomeKeyWindow {
	return YES;
}

- (BOOL)canBecomeMainWindow {
	return YES;
}

@end
