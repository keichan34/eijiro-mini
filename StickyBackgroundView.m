#import "StickyBackgroundView.h"

@implementation StickyBackgroundView

- (void)drawRect:(NSRect)rect {
 	[[NSColor colorWithCalibratedWhite:0.5f alpha:alphaValue] set];
	rect = [self frame];
	if (isShrank) {
		rect.origin.y = rect.size.height - 19;
		rect.size.height = 19;
		NSRectFill(rect);
	} else {
		NSRectFill(rect);
	}
}

- (void)setShrank:(BOOL)flag {
	isShrank = flag;
	[self display];
}

- (void)setAlphaValue:(float)value {
	alphaValue = value;
	[self display];
}

@end
