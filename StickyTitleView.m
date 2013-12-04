#import "StickyTitleView.h"
#import "StickyBackgroundView.h"

@implementation StickyTitleView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (void)awakeFromNib {
	closeButtonPressed = NO;
	closeButtonImage = [NSImage imageNamed:@"close_button"];
	closeButtonEnabledImage = [NSImage imageNamed:@"close_button_enabled"];
	closeButtonPressedImage = [NSImage imageNamed:@"close_button_pressed"];
	[closeButtonImage setFlipped:YES];
	[closeButtonEnabledImage setFlipped:YES];
	[closeButtonPressedImage setFlipped:YES];
	backgroundColor = [[NSColor whiteColor] retain];
	isKey = NO;
}

- (void)dealloc {
	[title release];
	[backgroundColor release];
	[super dealloc];
}

- (void)setIsKey:(BOOL)flag {
	isKey = flag;
	[self setNeedsDisplay:YES];
}

- (void)drawRect:(NSRect)rect {
	[backgroundColor set];
	NSRectFill(NSMakeRect(0, 0, rect.size.width, rect.size.height-1));

	NSImage *buttonImage =
		closeButtonPressed? closeButtonPressedImage:
		(isKey || closeButtonActivated)? closeButtonEnabledImage: closeButtonImage;
	[buttonImage drawAtPoint:NSMakePoint(6, 3)
					fromRect:NSMakeRect(0, 0, 11, 11)
				   operation:NSCompositeCopy
					fraction:1.0];

	[self drawTitleInRect:rect];
}

- (void)drawTitleInRect:(NSRect)rect {
	rect.size.width -= 40;
	rect.origin.x += 20;
	[title drawInRect:rect];
}

- (void)setTitle:(NSString *)str {
	
	NSMutableParagraphStyle *alignment =
		[[[NSMutableParagraphStyle alloc] init] autorelease];
	[alignment setAlignment:NSCenterTextAlignment];
	NSDictionary *attrDict =
		[NSDictionary dictionaryWithObjects:
			[NSArray arrayWithObjects:
				[NSFont fontWithName:@"Times New Roman Bold Italic" size:13.0],
				[NSColor blackColor],
				alignment,
				nil]
			forKeys:
			[NSArray arrayWithObjects:
				NSFontAttributeName,
				NSForegroundColorAttributeName,
				NSParagraphStyleAttributeName,
				nil]];
	title = [[[[NSAttributedString alloc] initWithString:str attributes:attrDict] autorelease] retain];
	[self display];
}

- (void)setScrollView:(NSScrollView *)view {
	scrollView = view;
}

- (void)setResizeView:(NSView *)view {
	resizeView = view;
}

- (void)setBackgroundView:(StickyBackgroundView *)view {
	backgroundView = view;
}

- (void)doShade {
	if ([scrollView isHidden]) {
		[scrollView setHidden:NO];
		[resizeView setHidden:NO];
		[backgroundView setShrank:NO];
	} else {
		[scrollView setHidden:YES];
		[resizeView setHidden:YES];
		[backgroundView setShrank:YES];
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
	if ([theEvent clickCount] == 2) {
		[self doShade];
		return;
	}
	NSPoint pos = [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSRect closeButtonRect = NSMakeRect(7, 3, 11, 11);
	if (NSPointInRect(pos, closeButtonRect)) {
		closeButtonActivated = YES;
		closeButtonPressed = YES;
		[self display];
		return;
	}
	NSPoint globalPos = [NSEvent mouseLocation];
	NSRect frameRect = [[self window] frame];
	paddingSize = NSMakeSize(globalPos.x - frameRect.origin.x, globalPos.y - frameRect.origin.y);
}
 
- (void)mouseDragged:(NSEvent *)theEvent {
	if (closeButtonActivated) {
		NSPoint pos = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSRect closeButtonRect = NSMakeRect(7, 3, 11, 11);
		closeButtonPressed = NSPointInRect(pos, closeButtonRect);
		[self display];
		return;
	}
	NSPoint globalPos = [NSEvent mouseLocation];
	NSWindow *window = [self window];
	NSRect frame = [[self window] frame];
	frame.origin.x = globalPos.x - paddingSize.width;
	frame.origin.y = globalPos.y - paddingSize.height;
	[window setFrame:frame display:YES];
}
 
- (void)mouseUp:(NSEvent *)theEvent {
	[super mouseUp:theEvent];
	if (closeButtonActivated) {
		NSPoint pos = [self convertPoint:[theEvent locationInWindow] fromView:nil];
		NSRect closeButtonRect = NSMakeRect(7, 3, 11, 11);
		if (NSPointInRect(pos, closeButtonRect)) {
			[[self window] close];
		}
		closeButtonPressed = NO;
		closeButtonActivated = NO;
	}
	[self display];
}

- (void)mouseMoved:(NSEvent *)theEvent {
	NSLog(@"moved");
}

- (BOOL)isFlipped {
	return YES;
}

- (void)setBackgroundColor:(NSColor *)color {
	[backgroundColor release];
	backgroundColor = [color retain];
	[self display];
}

@end
