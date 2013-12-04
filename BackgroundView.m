#import "BackgroundView.h"

#import "ApplicationManager.h"
#import "ControllableScroller.h"

@implementation BackgroundView

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return YES;
}

- (id)initWithFrame:(NSRect)frameRect {
	self = [super initWithFrame:frameRect];
	if (self) {
		metalImage = [NSImage imageNamed:@"metal_back"];
		metalResizeImage = [NSImage imageNamed:@"metal_resize"];
		lightImage = [NSImage imageNamed:@"metal_light.tif"];
		isResizing = NO;
	}
	return self;
}

- (void)drawRect:(NSRect)rect {
	NSRect frameRect = [self frame];

//	[[NSColor colorWithPatternImage:metalImage] set];
//	NSRectFill(rect);
	
	int x;
	for (x = 0; x-128 < rect.size.width; x+=128) {
		[metalImage drawAtPoint:NSMakePoint(x, 0)
					   fromRect:NSMakeRect(0, 0, 128, 128)
					  operation:NSCompositeCopy
					   fraction:1.0f];
	}

	[lightImage drawInRect:NSMakeRect(0, 0, frameRect.size.width, frameRect.size.height)
				  fromRect:NSMakeRect(0, 0, 128, 128)
				 operation:NSCompositePlusLighter
				  fraction:0.5f];
	
	[[NSColor colorWithCalibratedWhite:0.4353f alpha:1.0f] set];
	NSRectFillUsingOperation(NSMakeRect(0, frameRect.size.height-28, frameRect.size.width, 1), NSCompositeSourceOver);
	[[NSColor colorWithCalibratedWhite:0.0f alpha:0.15f] set];
	NSRectFillUsingOperation(NSMakeRect(0, frameRect.size.height-27, 1, 27), NSCompositeSourceOver);
	NSRectFillUsingOperation(NSMakeRect(frameRect.size.width-1, frameRect.size.height-27, 1, 27), NSCompositeSourceOver);
	[[NSColor colorWithCalibratedWhite:1.0f alpha:0.7f] set];
	NSRectFillUsingOperation(NSMakeRect(1, frameRect.size.height-1, frameRect.size.width-2, 1), NSCompositeSourceOver);
	
	if (displayResizeIndicator) {
		[metalResizeImage compositeToPoint:NSMakePoint(frameRect.size.width-12, 1)
								 operation:NSCompositeSourceOver];
	}
}

- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint pos =
        [self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSRect frameRect = [self frame];
	NSRect hotSpotRect = NSMakeRect(frameRect.size.width-9, 0, 9, 9);
	if (displayResizeIndicator && NSPointInRect(pos, hotSpotRect)) {
		isResizing = YES;
	} else {
		oldPos = pos;
	}
	paddingSize = NSMakeSize(frameRect.size.width-pos.x, pos.y);
}

void outputRect(NSString *str, NSRect rect) {
	NSLog(@"%@: %f, %f, %f, %f", str, rect.origin.x, rect.origin.y, rect.size.width, rect.size.height);
}


- (void)mouseDragged:(NSEvent *)theEvent {
	NSPoint pos =
		[self convertPoint:[theEvent locationInWindow] fromView:nil];
	NSWindow *window = [self window];
	if (isResizing) {
		NSRect frameRect = [window frame];
		frameRect.size.width = pos.x + paddingSize.width;
		if (frameRect.size.width < 180.0f) {
			frameRect.size.width = 180.0f;
		}
		NSRect screenRect = [[NSScreen mainScreen] frame];
		NSRect visibleScreenRect = [[NSScreen mainScreen] visibleFrame];
		if (frameRect.origin.x + frameRect.size.width > screenRect.size.width) {
			frameRect.size.width = screenRect.size.width - frameRect.origin.x;
		} else if (!([theEvent modifierFlags] & NSCommandKeyMask) &&
			   abs(frameRect.origin.x + frameRect.size.width - visibleScreenRect.size.width) < 12.0f) {
			frameRect.size.width = visibleScreenRect.size.width - frameRect.origin.x;
		}
		[window setFrame:frameRect display:YES];
	} else {
		// マウスの移動量を計算
		NSSize moveSize = NSMakeSize(pos.x - oldPos.x, pos.y - oldPos.y);

		// ウィンドウを移動
		NSRect frameRect = [window frame];
		frameRect.origin.x += moveSize.width;
		frameRect.origin.y += moveSize.height;

		// コマンドキーが押されていればコーナーにフィットさせない
		BOOL commandKeyPressed = ([theEvent modifierFlags] & NSCommandKeyMask)? YES: NO;

		// 複数のスクリーンに対応させる
		NSArray *screens = [NSScreen screens];
		NSScreen *currentScreen = [NSScreen mainScreen];
		for (int i = 0; i < [screens count]; i++) {
			NSScreen *screen = [screens objectAtIndex:i];
			NSRect screenRect = [screen frame];
			if (frameRect.origin.x >= screenRect.origin.x &&
					frameRect.origin.x < screenRect.origin.x + screenRect.size.width)
			{
				currentScreen = screen;
				break;
			}
		}

		NSRect screenRect = [currentScreen frame];
		NSRect visibleScreenRect = [currentScreen visibleFrame];
		
		if ((screenRect.origin.x == 0 && frameRect.origin.x < 0) ||
				(!commandKeyPressed && abs(frameRect.origin.x - screenRect.origin.x) < 12)) {
			frameRect.origin.x = screenRect.origin.x;
		} else if (!commandKeyPressed && abs(frameRect.origin.x+frameRect.size.width-(screenRect.origin.x+screenRect.size.width)) < 12) {
			frameRect.origin.x = screenRect.origin.x + screenRect.size.width - frameRect.size.width;
		}
		// Dock is on left or right side of current screen
		else if (!commandKeyPressed && screenRect.size.width > visibleScreenRect.size.width) {
			// Dock is on left
			if (screenRect.origin.x < visibleScreenRect.origin.x) {
				if (abs(frameRect.origin.x-visibleScreenRect.origin.x) < 12) {
					frameRect.origin.x = visibleScreenRect.origin.x;
				}
			}
			// Dock is on right
			else {
				if (abs(frameRect.origin.x+frameRect.size.width-(visibleScreenRect.origin.x+visibleScreenRect.size.width)) < 12) {
					frameRect.origin.x = visibleScreenRect.origin.x + visibleScreenRect.size.width - frameRect.size.width + 1;
				}
			}
		}

		// 検索結果が表示されている場合
		if ([[ApplicationManager sharedManager] isSearchResultShown]) {
			// コマンドキーが押されている場合にはコーナーにフィットさせない
			if (!commandKeyPressed) {
				// 画面下にくっつく場合
				if (abs(frameRect.origin.y) < 12.0f) {
					frameRect.origin.y = 0.0f;
				} else if (abs(frameRect.origin.y + frameRect.size.height - 28.0f) < 12.0f) {
					frameRect.origin.y = 28.0f - frameRect.size.height;
				}
				// 下のDockにくっつく場合
				else if (screenRect.origin.y < visibleScreenRect.origin.y &&
						 abs(frameRect.origin.y-visibleScreenRect.origin.y) < 12)
				{
					frameRect.origin.y = visibleScreenRect.origin.y - screenRect.origin.y;
				}
				// 画面上にくっつく場合
				if (frameRect.origin.y + frameRect.size.height > visibleScreenRect.origin.y + visibleScreenRect.size.height ||
					(!commandKeyPressed && abs(frameRect.origin.y + frameRect.size.height - (visibleScreenRect.origin.y + visibleScreenRect.size.height)) < 12))
				{
					frameRect.origin.y = visibleScreenRect.origin.y + visibleScreenRect.size.height - frameRect.size.height;
				}
			}
		}
		// 検索結果が表示されていない場合
		else {
			// 画面下にくっつく場合
			if (frameRect.origin.y + frameRect.size.height - 28 < screenRect.origin.y ||
				(!commandKeyPressed && abs(frameRect.origin.y + frameRect.size.height - 28) < 12)) {
				frameRect.origin.y = screenRect.origin.y + 28 - frameRect.size.height;
			}
			// 下のDockにくっつく場合
			else if (visibleScreenRect.origin.y > 0 &&
					 !commandKeyPressed && abs((frameRect.origin.y + frameRect.size.height - 28) - visibleScreenRect.origin.y) < 12) {
				frameRect.origin.y = visibleScreenRect.origin.y + 28 - frameRect.size.height;
			}
			// 画面上にくっつく場合
			else if (frameRect.origin.y + frameRect.size.height > visibleScreenRect.origin.y + visibleScreenRect.size.height ||
					   (!commandKeyPressed && abs(frameRect.origin.y + frameRect.size.height - (visibleScreenRect.origin.y + visibleScreenRect.size.height)) < 12)) {
				frameRect.origin.y = visibleScreenRect.origin.y + visibleScreenRect.size.height - frameRect.size.height;
			}
		}
		
		[window setFrameOrigin:frameRect.origin];
	}
}

- (void)mouseUp:(NSEvent *)theEvent {
	isResizing = NO;
}

- (void)setDisplayResizeIndicator:(BOOL)flag {
	displayResizeIndicator = flag;
	[self setNeedsDisplay:YES];
}

- (void)setScroller:(ControllableScroller *)scroller_ {
	scroller = scroller_;
}

- (void)setScrollView:(NSScrollView *)view {
	scrollView = view;
}

@end
