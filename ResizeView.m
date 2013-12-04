#import "ResizeView.h"

@implementation ResizeView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		indicatorImage = [NSImage imageNamed:@"resize_indicator"];
		doAdjust = NO;
	}
	return self;
}

- (void)drawRect:(NSRect)rect {
	[indicatorImage compositeToPoint:NSZeroPoint operation:NSCompositeCopy];
}

- (void)mouseDown:(NSEvent *)theEvent {
	startPos = [NSEvent mouseLocation];
	NSRect frameRect = [[self window] frame];
	startSize = frameRect.size;
	startTop = frameRect.origin.y + frameRect.size.height;
}

- (void)mouseDragged:(NSEvent *)theEvent {
	// マウスの移動量を計算
	NSPoint pos = [NSEvent mouseLocation];
	NSSize moveSize = NSMakeSize(pos.x - startPos.x, startPos.y - pos.y);
	// ウィンドウサイズを取得
	NSWindow *window = [self window];
	NSRect frameRect = [window frame];
	float originalHeight = frameRect.size.height;
	frameRect.size.width = startSize.width + moveSize.width;
	frameRect.size.height = startSize.height + moveSize.height;
	if (frameRect.size.width < [window minSize].width) {
		frameRect.size.width = [window minSize].width;
	}
	// 画面のサイズを取得
	NSRect screenRect = [[NSScreen mainScreen] frame];
	NSRect visibleScreenRect = [[NSScreen mainScreen] visibleFrame];
	// ??
	if (doAdjust && frameRect.origin.x + frameRect.size.width > screenRect.size.width) {
		frameRect.size.width = screenRect.size.width - frameRect.origin.x;
	} else if (doAdjust && !([theEvent modifierFlags] & NSCommandKeyMask) &&
		   abs(frameRect.origin.x + frameRect.size.width - visibleScreenRect.size.width) < 12.0f) {
		frameRect.size.width = visibleScreenRect.size.width - frameRect.origin.x;
	}
	if (frameRect.size.height < [window minSize].height) {
		frameRect.size.height = [window minSize].height;
	}
	frameRect.origin.y -= frameRect.size.height - originalHeight;
	// 画面下にフィット
	if (abs(frameRect.origin.y) < 12.0f) {
		frameRect.origin.y = 0.0f;
		frameRect.size.height += frameRect.origin.y;
	}
	if (frameRect.origin.y + frameRect.size.height != startTop) {
		frameRect.size.height = startTop - frameRect.origin.y;
	}
	// 新しいフレームをセット
	[window setFrame:frameRect display:YES];
}

- (void)setDoAdjust:(BOOL)flag {
	doAdjust = flag;
}

@end
