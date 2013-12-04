//
//  StickyDocument.h
//  Mini EIJIRO
//
//  Created by numata on Sun Jan 18 2004.
//  Copyright (c) 2004 Satoshi NUMATA. All rights reserved.
//

#import <AppKit/AppKit.h>

@class ControllableScroller;
@class StickyBackgroundView;
@class StickyView;
@class StickyTitleView;

@interface StickyDocument : NSDocument {
	IBOutlet NSWindow			*mainWindow;
    IBOutlet NSScrollView		*scrollView;
    IBOutlet NSView				*resizeView;
	IBOutlet StickyView			*stickyView;
	IBOutlet StickyTitleView	*titleView;
	IBOutlet StickyBackgroundView   *backgroundView;

	NSMutableDictionary *normalTextAttrDict;

	ControllableScroller  *scroller;
	
	NSWindow		*searchWindow;
	
	NSString	*title;
	NSMutableAttributedString	*attrStr;
}

- (void)setTitle:(NSString *)str;

- (void)setStickyAlphaValue:(float)alphaValue;

- (void)setSearchWindow:(NSWindow *)window;

- (void)setAttrStr:(NSAttributedString *)attrStr;

- (void)changeFont:(NSFont *)font;

@end
