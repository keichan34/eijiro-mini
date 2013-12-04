//
//  StickyDocument.m
//  Mini EIJIRO
//
//  Created by numata on Sun Jan 18 2004.
//  Copyright (c) 2004 Satoshi NUMATA. All rights reserved.
//

#import "StickyDocument.h"

#import "ControllableScroller.h"
#import "StickyBackgroundView.h"
#import "StickyTitleView.h"
#import "StickyView.h"


@implementation StickyDocument

- (void)dealloc {
	[title release];
	[normalTextAttrDict release];
	[super dealloc];
}

- (NSString *)windowNibName {
    return @"StickyDocument";
}

- (void)windowControllerDidLoadNib:(NSWindowController *)windowController {
	[[stickyView textStorage] setAttributedString:attrStr];
	[attrStr release];

	[titleView setTitle:title];
	scroller = [[ControllableScroller alloc] initWithFrame:NSMakeRect(0, 10, 11, 100)];
	[scroller setControlSize:NSSmallControlSize];
	[scrollView setVerticalScroller:scroller];
	[scroller setScrollView:scrollView];
	[scroller setResizeView:resizeView];
	[scroller setFrame:NSMakeRect(0, 0, 0, 0)];
	
	[titleView setScrollView:scrollView];
	[titleView setResizeView:resizeView];
	[titleView setBackgroundView:backgroundView];
	
	NSRect visibleScreenRect = [[NSScreen mainScreen] visibleFrame];
	[mainWindow setFrame:NSMakeRect(10, visibleScreenRect.size.height-110, 190, 124) display:NO];

	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];
	float alphaValue = [defaults floatForKey:@"stickyTransparency"];
	if (alphaValue == 0.0f) {
		alphaValue = 1.0f;
	} else if (alphaValue < 0.1f) {
		alphaValue = 0.1f;
	}
	[self setStickyAlphaValue:alphaValue];
	
	if ([defaults boolForKey:@"shadeStickyOnCreation"]) {
		[titleView doShade];
	}
}

- (void)setTitle:(NSString *)str {
	title = [str retain];
}

- (NSData *)dataRepresentationOfType:(NSString *)type {
    return nil;
}

- (BOOL)loadDataRepresentation:(NSData *)data ofType:(NSString *)type {
    // Implement to load a persistent data representation of your document OR remove this and implement the file-wrapper or file path based load methods.
    return YES;
}

- (void)setStickyAlphaValue:(float)alphaValue {
	[stickyView setBackgroundColor:[NSColor colorWithCalibratedWhite:1.0f alpha:alphaValue]];
	alphaValue += 0.3f;
	if (alphaValue > 1.0f) {
		alphaValue = 1.0f;
	}
	[titleView setBackgroundColor:[NSColor colorWithCalibratedWhite:1.0f alpha:alphaValue]];
	[backgroundView setAlphaValue:alphaValue];
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
	if (aSelector == @selector(insertTab:) ||
			aSelector == @selector(insertBacktab:) ||
			aSelector == @selector(insertNewline:)) {
		[searchWindow makeKeyAndOrderFront:self];
		return YES;
	}
	return NO;
}

- (void)setSearchWindow:(NSWindow *)window {
	searchWindow = window;
}

- (void)setAttrStr:(NSAttributedString *)attrStr_ {
	NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
	NSString *fontName = [defaults stringForKey:@"stickyFontName"];
	if (!fontName || [fontName length] == 0) {
		fontName = @"HiraKakuPro-W3";
	}
	float fontSize = [defaults floatForKey:@"stickyFontSize"];
	if (fontSize == 0.0f) {
		fontSize = 10.0f;
	}

	// 通常のテキストの属性
	normalTextAttrDict = [[NSMutableDictionary alloc] initWithCapacity:3];
	[normalTextAttrDict setObject:[NSColor blackColor] forKey:NSForegroundColorAttributeName];
	[normalTextAttrDict setObject:
		[NSFont fontWithName:fontName size:fontSize] forKey:NSFontAttributeName];
	attrStr = [[NSMutableAttributedString alloc] initWithAttributedString:attrStr_];
	[attrStr setAttributes:normalTextAttrDict range:NSMakeRange(0, [attrStr length])];
}

- (void)changeFont:(NSFont *)font {
	[[stickyView textStorage] setFont:font];
}

@end
