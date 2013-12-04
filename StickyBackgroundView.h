/* StickyBackgroundView */

#import <Cocoa/Cocoa.h>

@interface StickyBackgroundView : NSView
{
	BOOL isShrank;
	float alphaValue;
}

- (void)setShrank:(BOOL)flag;
- (void)setAlphaValue:(float)value;

@end
