#import "MetalButton.h"

@implementation MetalButton

- (void)dealloc {
	[enabledImage release];
	[disabledImage release];
	[super dealloc];
}

- (void)mouseDown:(NSEvent *)theEvent {
	if (isEnabled) {
		[super mouseDown:theEvent];
	} else {
		[[self superview] mouseDown:theEvent];
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
}

- (void)setEnabledImage:(NSImage *)image {
	enabledImage = [image retain];
}

- (void)setDisabledImage:(NSImage *)image {
	disabledImage = [image retain];
}

- (void)setEnabled:(BOOL)flag {
	isEnabled = flag;
	if (!isEnabled && disabledImage) {
		[self setImage:disabledImage];
	} else {
		[self setImage:enabledImage];
	}
}

@end
