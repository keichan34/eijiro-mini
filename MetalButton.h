/* MetalButton */

#import <Cocoa/Cocoa.h>

@interface MetalButton : NSButton
{
	NSImage *enabledImage;
	NSImage *disabledImage;
	BOOL	isEnabled;
}

- (void)setEnabledImage:(NSImage *)image;
- (void)setDisabledImage:(NSImage *)image;

@end
