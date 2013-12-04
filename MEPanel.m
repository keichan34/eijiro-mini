#import "MEPanel.h"

@implementation MEPanel

- (id)initWithContentRect:(NSRect)contentRect styleMask:(unsigned int)styleMask backing:(NSBackingStoreType)backingType defer:(BOOL)flag
{
	self = [super initWithContentRect:contentRect
							styleMask:NSBorderlessWindowMask|NSTexturedBackgroundWindowMask
							  backing:backingType
								defer:flag];
	if (self) {
		[self setBackgroundColor: [NSColor clearColor]];
		[self setLevel:NSFloatingWindowLevel];
		[self setAlphaValue:1.0];
		[self setOpaque:NO];
		[self setHasShadow:YES];
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
	return NO;
}

@end
