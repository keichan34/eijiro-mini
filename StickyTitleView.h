/* StickyTitleView */

#import <Cocoa/Cocoa.h>

@class StickyBackgroundView;

@interface StickyTitleView : NSView
{
	NSImage *closeButtonImage;
	NSImage *closeButtonEnabledImage;
	NSImage *closeButtonPressedImage;

	BOOL	closeButtonActivated;
	BOOL	closeButtonPressed;
	BOOL	isKey;

	NSSize  paddingSize;
	
	NSAttributedString *title;
	
	NSColor *backgroundColor;
	
	NSScrollView	*scrollView;
	NSView			*resizeView;
	StickyBackgroundView	*backgroundView;
}

- (void)setIsKey:(BOOL)flag;

- (void)doShade;

- (void)drawTitleInRect:(NSRect)rect;
- (void)setTitle:(NSString *)str;

- (void)setBackgroundColor:(NSColor *)color;

- (void)setScrollView:(NSScrollView *)view;
- (void)setResizeView:(NSView *)view;
- (void)setBackgroundView:(StickyBackgroundView *)view;

@end
