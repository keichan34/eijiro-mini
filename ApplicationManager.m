#import "ApplicationManager.h"

#import "BackgroundView.h"
#import "ControllableScroller.h"
#import "MetalButton.h"
#import "ResizeView.h"
#import "ResultView.h"
#import "SpeechManager.h"
#import "StickyDocument.h"
#import "StickyWindow.h"
#import "StringUtil.h"

static const int SEARCH_RESULT_MAX = 20;

@interface MySearchFieldCell : NSSearchFieldCell
@end

@implementation MySearchFieldCell

- (id)init {
	self = [super initTextCell:@""];
	if (self) {
		[self setDrawsBackground:YES];
		[self setBezeled:YES];
		[self setEditable:YES];
		[self setPlaceholderString:@"EIJIRO"];
	}
    return self;
}

- (BOOL)showsFirstResponder {
	return NO;
}

- (BOOL)wraps {
    return NO;
}

- (BOOL)isScrollable {
    return YES;
}

@end

static ApplicationManager *_instance;

@implementation ApplicationManager

+ (ApplicationManager *)sharedManager {
	return _instance;
}

- (void)awakeFromNib {
	_instance = self;
	
	existsLastWord = NO;
	
	previousWordList = [[NSMutableArray array] retain];
	afterWordList = [[NSMutableArray array] retain];
	
	currentSearchWordLock = [[NSLock alloc] init];
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];
	NSString *frameStr = [defaults stringForKey:@"WINDOW_FRAME"];
	if (frameStr) {
		[mainWindow setFrame:NSRectFromString(frameStr) display:NO];
	} else {
		[mainWindow center];
	}
	
	[moveButtonMenuItem setIndentationLevel:1];
	if ([defaults boolForKey:@"HIDE_MOVE_BUTTON"]) {
		[self hideMoveButton:self];
	} else {
		[moveButtonMenuItem setState:NSOnState];
	}

	[pronounceButtonMenuItem setIndentationLevel:1];
	if ([defaults boolForKey:@"HIDE_PRONUNCIATION_BUTTON"]) {
		[self hidePronounceButton:self];
	} else {
		[pronounceButtonMenuItem setState:NSOnState];
	}
	
	speechManager = [[SpeechManager alloc] initWithStopMode:kImmediate
													 target:self
									  speakingStartedMethod:@selector(speakingStarted)
								   speakingPosChangedMethod:@selector(speakingPosChanged:)
										 speakingDoneMethod:@selector(speakingDone)
										 errorOccuredMethod:@selector(speakingErrorOccured:)];
	
	fieldCell = [[MySearchFieldCell alloc] init];
	[searchWordField setCell:fieldCell];
	
	scroller = [[ControllableScroller alloc] initWithFrame:NSMakeRect(0, 10, 11, 100)];
	[scroller setControlSize:NSSmallControlSize];
	[scrollView setVerticalScroller:scroller];
	[scroller setScrollView:scrollView];
	[scroller setResizeView:resizeView];
	[scroller setFrame:NSMakeRect(0, 0, 0, 0)];

	[backgroundView setScrollView:scrollView];
	[backgroundView setScroller:scroller];

	[resizeView setDoAdjust:YES];
	
	[backButton setEnabledImage:[NSImage imageNamed:@"back_button"]];
	[backButton setDisabledImage:[NSImage imageNamed:@"back_button_disabled"]];
	[backButton setEnabled:NO];

	[goButton setEnabledImage:[NSImage imageNamed:@"go_button"]];
	[goButton setDisabledImage:[NSImage imageNamed:@"go_button_disabled"]];
	[goButton setEnabled:NO];
	
	[pronounceButton setEnabledImage:[NSImage imageNamed:@"sound_button"]];
	[pronounceButton setDisabledImage:[NSImage imageNamed:@"sound_button_disabled"]];
	[pronounceButton setEnabled:NO];
	
	[mainWindow setMovableByWindowBackground:NO];
	
	if ([defaults boolForKey:@"alwaysOnTop"]) {
		[mainWindow setLevel:NSStatusWindowLevel];
	} else {
		[mainWindow setLevel:NSNormalWindowLevel];
	}
	
	isSearchResultShown = NO;
	[self hideResultView];
	
	[mainWindow makeKeyAndOrderFront:self];
}

- (void)dealloc {
	[firstGuessWord release];
	[secondGuessWord release];
	[previousWordList release];
	[afterWordList release];
	[currentSearchWordLock release];
	[fieldCell release];
	[scroller release];
	[speechManager release];
	[currentSearchWord release];
	[super dealloc];
}

- (IBAction)showPreferences:(id)sender {
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];
	NSString *eijiroPath = [defaults stringForKey:@"eijiroPath"];
	if (eijiroPath) {
		[eijiroPathField setStringValue:eijiroPath];
	}
	
	[preferencesWindow center];
	[preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)savePreferences:(id)sender {
//	[NSApp stopModalWithCode:NSOKButton];
	[preferencesWindow orderOut:self];
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	[userDefaultsController save:self];
}

- (IBAction)revertPreferences:(id)sender {
//	[NSApp stopModalWithCode:NSCancelButton];
	[preferencesWindow orderOut:self];
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	[userDefaultsController revert:self];
}

- (void)showResultView {
	isSearchResultShown = YES;
	if (![scroller isHidden]) {
		return;
	}
	NSRect frameRect = [mainWindow frame];
	float scrollerWidth = [scroller frame].size.width;
	[scroller setFrame:NSMakeRect(frameRect.size.width-scrollerWidth, 0, scrollerWidth, frameRect.size.height-28)];
	[scroller setHidden:NO];
	[scrollView setVerticalScroller:scroller];
	[scrollView setHidden:NO];
	[resizeView setHidden:NO];
	// 画面下に張り付いていた場合
	if (frameRect.origin.y == 28 - frameRect.size.height) {
		frameRect.origin.y = 0;
		[mainWindow setFrame:frameRect display:YES animate:YES];
	}
	// 下のDockに張り付いていた場合（あまり使われなさそうな気がするので、とりあえずOFF）
	/*else if (screenRect.origin.y < visibleScreenRect.origin.y &&
			 frameRect.origin.y == 28 + visibleScreenRect.origin.y - screenRect.origin.y - frameRect.size.height)
	{
		frameRect.origin.y = visibleScreenRect.origin.y - screenRect.origin.y;
		[mainWindow setFrame:frameRect display:YES];
	}*/
	[backgroundView setDisplayResizeIndicator:NO];
	[mainWindow display];
	[mainWindow invalidateShadow];
}

- (void)hideResultView {
	NSRect frameRect = [mainWindow frame];
	// 画面下に張り付いている場合
	if (frameRect.origin.y == 0) {
		frameRect.origin.y = 28 - frameRect.size.height;
		[mainWindow setFrame:frameRect display:YES animate:YES];
	}
	// 下のDockに張り付いていた場合（あまり使われなさそうな気がするので、とりあえずOFF）
	/*else if (screenRect.origin.y < visibleScreenRect.origin.y &&
			 frameRect.origin.y == visibleScreenRect.origin.y - screenRect.origin.y)
	{
		frameRect.origin.y = 28 + visibleScreenRect.origin.y - screenRect.origin.y - frameRect.size.height;
		[mainWindow setFrame:frameRect display:YES];
	}*/		
	isSearchResultShown = NO;
	[scrollView setVerticalScroller:nil];
	[scroller removeFromSuperview];
	[scroller setHidden:YES];
	[scrollView setHidden:YES];
	[resizeView setHidden:YES];
	[backgroundView setDisplayResizeIndicator:YES];
	[mainWindow display];
	[mainWindow invalidateShadow];
}

- (BOOL)isSearchResultShown {
	return isSearchResultShown;
}

- (IBAction)hideMoveButton:(id)sender {
	if ([backButton isHidden]) {
		[moveButtonMenuItem setState:NSOnState];
		[backButton setEnabled:YES];
		[backButton setHidden:NO];
		[goButton setEnabled:YES];
		[goButton setHidden:NO];
		NSRect searchWordFieldFrame = [searchWordField frame];
		searchWordFieldFrame.size.width -= 50;
		searchWordFieldFrame.origin.x += 50;
		[searchWordField setFrame:searchWordFieldFrame];
		NSRect pronounceButtonFrame = [pronounceButton frame];
		pronounceButtonFrame.origin.x += 50;
		[pronounceButton setFrameOrigin:pronounceButtonFrame.origin];
		[mainWindow display];
	} else {
		[moveButtonMenuItem setState:NSOffState];
		[backButton setEnabled:NO];
		[backButton setHidden:YES];
		[goButton setEnabled:NO];
		[goButton setHidden:YES];
		NSRect searchWordFieldFrame = [searchWordField frame];
		searchWordFieldFrame.size.width += 50;
		searchWordFieldFrame.origin.x -= 50;
		[searchWordField setFrame:searchWordFieldFrame];
		NSRect pronounceButtonFrame = [pronounceButton frame];
		pronounceButtonFrame.origin.x -= 50;
		[pronounceButton setFrameOrigin:pronounceButtonFrame.origin];
		[mainWindow display];
	}
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];
	[defaults setBool:[pronounceButton isHidden] forKey:@"HIDE_MOVE_BUTTON"];
	[defaults synchronize];
}

- (IBAction)hidePronounceButton:(id)sender {
	if ([pronounceButton isHidden]) {
		[pronounceButtonMenuItem setState:NSOnState];
		[pronounceButton setEnabled:YES];
		[pronounceButton setHidden:NO];
		NSRect frame = [searchWordField frame];
		frame.size.width -= 27;
		frame.origin.x += 27;
		[searchWordField setFrame:frame];
		[mainWindow display];
	} else {
		[pronounceButtonMenuItem setState:NSOffState];
		[pronounceButton setEnabled:NO];
		[pronounceButton setHidden:YES];
		NSRect frame = [searchWordField frame];
		frame.size.width += 27;
		frame.origin.x -= 27;
		[searchWordField setFrame:frame];
		[mainWindow display];
	}
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];
	[defaults setBool:[pronounceButton isHidden] forKey:@"HIDE_PRONUNCIATION_BUTTON"];
	[defaults synchronize];
}

- (void)applicationDidResignActive:(NSNotification *)aNotification {
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];
	
	if ([defaults boolForKey:@"hideResultsOnDeactivation"]) {
		[self hideResultView];
		if ([defaults boolForKey:@"clearSearchWordOnDeactivation"]) {
			[searchWordField setStringValue:@""];
			[pronounceButton setEnabled:NO];
		}
	}
}

- (void)applicationDidBecomeActive:(NSNotification *)aNotification {
	NSString *searchWord = [searchWordField stringValue];
	[self addHistory:searchWord];
	[mainWindow makeFirstResponder:searchWordField];
	if ([[searchWordField stringValue] length] > 0) {
		[self showResultView];
	}
}

- (void)windowDidBecomeKey:(NSNotification *)aNotification {
	[mainWindow makeFirstResponder:searchWordField];
}

- (void)applicationWillResignActive:(NSNotification *)aNotification {
	[mainWindow makeFirstResponder:searchWordField];
}

- (void)controlTextDidChange:(NSNotification *)aNotification {
	NSString *searchWord = [searchWordField stringValue];
	[self updateLastHistory:searchWord];
	[currentSearchWordLock lock];
	[currentSearchWord release];
	currentSearchWord = [searchWord retain];
	[currentSearchWordLock unlock];
	if ([searchWord length] > 0) {
		[self showResultView];
		[pronounceButton setEnabled:YES];
		[speechManager stopSpeaking];
		[NSThread detachNewThreadSelector:@selector(searchForWord:) toTarget:self withObject:searchWord];
	} else {
		[self hideResultView];
		[pronounceButton setEnabled:NO];
	}
}

- (void)clearResultForSearchWord:(NSString *)searchWord {
	if ([self checkIfActiveSearchWord:searchWord]) {
		[resultView clearResult];
	}
}

- (void)addSeparatorForSearchWord:(NSString *)searchWord {
	if ([self checkIfActiveSearchWord:searchWord]) {
		[resultView addSeparator];
	}
}

- (void)addResult:(NSArray *)info {
	NSString *searchWord = [info objectAtIndex:0];
	NSString *result = [info objectAtIndex:1];
	if ([self checkIfActiveSearchWord:searchWord]) {
		[resultView addResult:result];
	}
}

- (void)flushResultForSearchWord:(NSString *)searchWord {
	if ([self checkIfActiveSearchWord:searchWord]) {
		[resultView flushResultForSearchWord:searchWord];
	}
}

- (void)searchForWord:(NSString *)searchWord {
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];
	NSString *eijiroPath = [defaults stringForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [defaults stringForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [defaults stringForKey:@"waeijiroPath"];
	BOOL removeRubies = [defaults boolForKey:@"removeRubies"];
	NSString *eijiroSearchWord =
		[[NSString alloc] initWithFormat:NSLocalizedString(@"EIJIRO_SEARCH", @""),
			searchWord];
	NSData *searchWordData = [eijiroSearchWord dataUsingEncoding:NSShiftJISStringEncoding];
	[eijiroSearchWord release];
	BOOL isAllCapital;
	[self performSelectorOnMainThread:@selector(clearResultForSearchWord:)
						   withObject:searchWord
						waitUntilDone:NO];
	if (isEnglishWord(searchWord, &isAllCapital)) {
		// Search RYAKUGORO iff all characters in the search word are capital
		if (isAllCapital && ryakugoroPath) {
			int count = [self binarySearchForWord:searchWord
								   searchWordData:searchWordData
										 fromData:[NSData dataWithContentsOfMappedFile:ryakugoroPath]
									 removeRubies:removeRubies];
			if  (count > 0) {
				[self performSelectorOnMainThread:@selector(addSeparatorForSearchWord:)
									   withObject:searchWord
									waitUntilDone:NO];
			}
		}
		// Search EIJIRO
		[self binarySearchForWord:searchWord
				   searchWordData:searchWordData
						 fromData:[NSData dataWithContentsOfMappedFile:eijiroPath]
					 removeRubies:removeRubies];
	} else {
		// Search WAEIJIRO
		[self binarySearchForWord:searchWord
				   searchWordData:searchWordData
						 fromData:[NSData dataWithContentsOfMappedFile:waeijiroPath]
					 removeRubies:removeRubies];
	}
	[self performSelectorOnMainThread:@selector(flushResultForSearchWord:)
						   withObject:searchWord
						waitUntilDone:NO];	
	[pool release];
}

- (int)binarySearchForWord:(NSString *)searchWord
			 searchWordData:(NSData *)searchWordData
				   fromData:(NSData *)data
			   removeRubies:(BOOL)removeRubies
{
	if (!data) {
		return 0;
	}
	if (![self checkIfActiveSearchWord:searchWord]) {
		return 0;
	}
	int dataSize = [data length];
	if (dataSize <= 0) {
		return 0;
	}
	int targetLength = [searchWordData length];
	if (targetLength <= 0) {
		return 0;
	}
	int startPos = 0;
	int endPos = dataSize - 1;
	int middlePos = 0;
	unsigned char *p = (unsigned char *) [data bytes];
	unsigned char *searchWordC = malloc(targetLength + 1);
	[searchWordData getBytes:searchWordC length:targetLength];
	searchWordC[targetLength] = 0;

	while (startPos < endPos) {
		if (![self checkIfActiveSearchWord:searchWord]) {
			free(searchWordC);
			return 0;
		}
		// Calculate middle pos of data
		middlePos = startPos + (endPos - startPos) / 2;
		// Move backword until return code or start position appears
		while (middlePos > startPos &&
			   ((p[middlePos-1] != 0x0a && p[middlePos-1] != 0x0d) ||
				p[middlePos] == 0x0a || p[middlePos] == 0x0d)) {
			middlePos--;
		}
		// Do compare
		int comparisonResult = mystrncmp((p + middlePos), searchWordC, targetLength, YES);
		if (comparisonResult == 0) {
			// 検索文字列が見つかった。
			// middlePos 変数が先頭のインデクスを保持している。
			//[debugManager addDebugString:@"[Found]"];
			break;
		} else if (comparisonResult < 0) {
			// 現在のインデクスよりも後ろの部分にしか検索文字列は存在しない
			startPos = middlePos;
			// その行の最後までインデクスを送る
			while (startPos < endPos && p[startPos] != 0x0a && p[startPos] != 0x0d) {
				if (isFirst2BytesCharacter(p[startPos])) {
					startPos++;
				}
				startPos++;
			}
			while (p[startPos] == 0x0a || p[startPos] == 0x0d) {
				startPos++;
			}
		} else {
			// 現在のインデクスよりも前の部分にしか検索文字列は存在しない
			endPos = middlePos - 1;
		}
	}

	// Next search word is appered.
	if (![self checkIfActiveSearchWord:searchWord]) {
		free(searchWordC);
		return 0;
	}
	
	// Not found.
	if (startPos >= endPos) {
		free(searchWordC);
		return 0;
	}

	// Found.
	// Set endPos to the end of the first line at this point.
	endPos = middlePos + 1;
	while (endPos < dataSize-1 && p[endPos] != 0x0a && p[endPos] != 0x0d) {
		endPos++;
	}	

	// 同じレベルの文字列を上方向に検索し、startPos 変数をそのレベルの文字列が
	// 最初に現れる行の先頭のインデクス値とする。
	startPos = middlePos - 1;
	while (startPos > 0) {
		// Next search word is appered.
		if (![self checkIfActiveSearchWord:searchWord]) {
			free(searchWordC);
			return 0;
		}
		while (startPos > 0 &&
			   ((p[startPos-1] != 0x0a && p[startPos-1] != 0x0d) ||
				(p[startPos] == 0x0a || p[startPos] == 0x0d))) {
			startPos--;
		}
		int comparisonResult = mystrncmp((p + startPos), searchWordC, targetLength, YES);
		if (comparisonResult == 0) {
			middlePos = startPos;
			startPos = middlePos - 1;
		} else {
			break;
		}
	}
	startPos = middlePos;

	// 同じレベルの文字列が見つかる間、endPos 変数を送っていく。
	middlePos = startPos;
	endPos = startPos + 1;
	int count = 0;
	while (endPos < dataSize-1) {
		// Next search word is appered.
		if (![self checkIfActiveSearchWord:searchWord]) {
			free(searchWordC);
			return count;
		}
		while (endPos < dataSize-1 &&
			   (p[endPos] != 0x0a && p[endPos] != 0x0d)) {
			endPos++;
		}
		// Add a result
		NSData *resultData = [data subdataWithRange:NSMakeRange(middlePos, endPos-middlePos+1)];
		NSString *addStr = [[NSString alloc] initWithData:resultData encoding:NSShiftJISStringEncoding];
		NSString *correctedStr = [self correctPronunciationSymbolFromString:addStr];
		if (removeRubies) {
			NSString *noRubyStr = [self stringByRemoveRubiesFromString:correctedStr];
			[correctedStr release];
			correctedStr = noRubyStr;
		}
		NSString *ver80Str = [self fixVer80ExampleStr:correctedStr];
		[self performSelectorOnMainThread:@selector(addResult:)
							   withObject:[NSArray arrayWithObjects:searchWord, ver80Str, nil]
							waitUntilDone:NO];
		[ver80Str release];
		[correctedStr release];
		[addStr release];
		count++;
		if (count >= SEARCH_RESULT_MAX) {
			break;
		}
		// Next search
		while (endPos < dataSize-1 &&
			   (p[endPos] == 0x0a || p[endPos] == 0x0d)) {
			endPos++;
		}
		int comparisonResult = mystrncmp((p + endPos), searchWordC, targetLength, YES);
		if (comparisonResult != 0) {
			break;
		}
		middlePos = endPos;
		endPos++;
	}
	free(searchWordC);
	return count;
}

- (BOOL)checkIfActiveSearchWord:(NSString *)searchWord {
	BOOL ret;
	[currentSearchWordLock lock];
	ret = [currentSearchWord isEqualToString:searchWord];
	[currentSearchWordLock unlock];
	return ret;
}

- (BOOL)textView:(NSTextView *)aTextView doCommandBySelector:(SEL)aSelector {
	if (aSelector == @selector(insertTab:) ||
			aSelector == @selector(insertBacktab:) ||
			aSelector == @selector(insertNewline:)) {
		[mainWindow makeFirstResponder:searchWordField];
		return YES;
	}
	return NO;
}

- (BOOL)control:(NSControl *)control textView:(NSTextView *)textView doCommandBySelector:(SEL)command {
	if (command == @selector(insertNewline:)) {
		NSString *searchWord = [searchWordField stringValue];
		[self addHistory:searchWord];
	} else if (command == @selector(scrollToBeginningOfDocument:)) {
		[resultView doCommandBySelector:@selector(scrollToBeginningOfDocument:)];
		return YES;
	} else if (command == @selector(scrollToEndOfDocument:)) {
		[resultView doCommandBySelector:@selector(scrollToEndOfDocument:)];
		return YES;
	} else if (command == @selector(scrollPageDown:)) {
		[resultView doCommandBySelector:@selector(scrollPageDown:)];
		return YES;
	} else if (command == @selector(scrollPageUp:)) {
		[resultView doCommandBySelector:@selector(scrollPageUp:)];
		return YES;
	} else if (command == @selector(moveToBeginningOfLine:)) {
		[self goPrevious:self];
		return YES;
	} else if (command == @selector(moveToEndOfLine:)) {
		[self goAfter:self];
		return YES;
	}
		/*	if (command == @selector(cancel:)) {
		// Insert codes here for switching to next application
		return YES;
	}*/
//	[mainWindow display];
//	[mainWindow invalidateShadow];
	return NO;
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];

	[defaults addObserver:self 
			   forKeyPath:@"alwaysOnTop"
				  options:NSKeyValueObservingOptionNew 
				  context:NULL];
	
	if (![defaults objectForKey:@"alwaysOnTop"]) {
		[defaults setBool:YES forKey:@"alwaysOnTop"];
	}
	if (![defaults objectForKey:@"HIDE_PRONUNCIATION_BUTTON"]) {
		[defaults setBool:NO forKey:@"HIDE_PRONUNCIATION_BUTTON"];
	}
	if (![defaults objectForKey:@"stickyTransparency"]) {
		[defaults setFloat:1.0f forKey:@"stickyTransparency"];
	}
	if (![defaults objectForKey:@"shadeStickyOnCreation"]) {
		[defaults setBool:NO forKey:@"shadeStickyOnCreation"];
	}
	if (![defaults objectForKey:@"removeRubies"]) {
		[defaults setBool:YES forKey:@"removeRubies"];
	}
	if (![defaults objectForKey:@"hideResultsOnDeactivation"]) {
		[defaults setBool:YES forKey:@"hideResultsOnDeactivation"];
	}
	if (![defaults objectForKey:@"clearSearchWordOnDeactivation"]) {
		[defaults setBool:NO forKey:@"clearSearchWordOnDeactivation"];
	}
	if (![defaults objectForKey:@"fontName"]) {
		[defaults setObject:@"HiraKakuPro-W3" forKey:@"fontName"];
	}
	if (![defaults objectForKey:@"fontSize"]) {
		[defaults setFloat:11.0f forKey:@"fontSize"];
	}
	if (![defaults objectForKey:@"stickyFontName"]) {
		[defaults setObject:@"HiraKakuPro-W3" forKey:@"stickyFontName"];
	}
	if (![defaults objectForKey:@"stickyFontSize"]) {
		[defaults setFloat:10.0f forKey:@"stickyFontSize"];
	}
	if (![defaults objectForKey:@"fontDescription"]) {
		NSFont *resultFont =
			[NSFont fontWithName:[defaults objectForKey:@"fontName"]
							size:[defaults floatForKey:@"fontSize"]];
		NSString *fontDescription =
			[NSString stringWithFormat:@"%@ - %3.1fpt",
				[resultFont displayName], [resultFont pointSize]];
		[defaults setObject:fontDescription forKey:@"fontDescription"];
	}
	if (![defaults objectForKey:@"stickyFontDescription"]) {
		NSFont *stickyFont =
			[NSFont fontWithName:[defaults objectForKey:@"stickyFontName"]
							size:[defaults floatForKey:@"stickyFontSize"]];
		NSString *fontDescription =
			[NSString stringWithFormat:@"%@ - %3.1fpt",
				[stickyFont displayName], [stickyFont pointSize]];
		[defaults setObject:fontDescription forKey:@"stickyFontDescription"];
	}
	[defaults synchronize];
	[resultView rebuildFont];
	
	NSString *eijiroPath = [defaults stringForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [defaults stringForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [defaults stringForKey:@"waeijiroPath"];
	NSString *reijiroPath = [defaults stringForKey:@"reijiroPath"];
	if (!eijiroPath && !ryakugoroPath && !waeijiroPath && !reijiroPath) {
		[self showPreferences:self];
	}
}

- (IBAction)makeNewSticky:(id)sender {
	NSDocumentController *documentController =
		[NSDocumentController sharedDocumentController];
    StickyDocument *doc = [documentController openUntitledDocumentAndDisplay:NO error:nil];
	[doc setTitle:[searchWordField stringValue]];
	[doc setSearchWindow:mainWindow];
	[doc setAttrStr:[resultView attrStr]];
	[doc showWindows];
}

- (IBAction)pronounce:(id)sender {
	if ([speechManager isSpeaking]) {
		[speechManager stopSpeaking];
	} else {
		BOOL searchWordFieldFocused =
			[[searchWordField window] firstResponder] == [searchWordField currentEditor];
		speakingView = searchWordFieldFocused?
			((NSTextView *) [searchWordField currentEditor]): resultView;
		if (!speakingView) {
			return;
		}
        selectionRange = [speakingView selectedRange];
		NSString *targetText;
        if (selectionRange.length == 0) {
            targetText = [speakingView string];
            speechStartPos = 0;
        } else {
            targetText = [[speakingView string] substringWithRange:selectionRange];
            speechStartPos = selectionRange.location;
        }
		if ([targetText length] == 0) {
			return;
		}
		[speechManager speakText:targetText];
	}
}

- (IBAction)referEIJIROPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];

	NSUserDefaults *defaults = [userDefaultsController defaults];
	NSString *eijiroPath = [defaults stringForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [defaults stringForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [defaults stringForKey:@"waeijiroPath"];
	NSString *reijiroPath = [defaults stringForKey:@"reijiroPath"];
	NSString *searchDir = NSHomeDirectory();
	if (eijiroPath) {
		searchDir = [eijiroPath stringByDeletingLastPathComponent];
	} else if (ryakugoroPath) {
		searchDir = [ryakugoroPath stringByDeletingLastPathComponent];
	} else if (waeijiroPath) {
		searchDir = [waeijiroPath stringByDeletingLastPathComponent];
	} else if (reijiroPath) {
		searchDir = [reijiroPath stringByDeletingLastPathComponent];
	}

    openPanel.directoryURL = [NSURL URLWithString:searchDir];
    openPanel.allowedFileTypes = [NSArray arrayWithObject:@"txt"];

	NSInteger ret = [openPanel runModal];

	if (ret == NSOKButton) {
		NSUserDefaults *defaults = [userDefaultsController defaults];
		eijiroPath = [[openPanel URL] path];
		[eijiroPathField setStringValue:eijiroPath];
		[defaults setObject:eijiroPath forKey:@"eijiroPath"];
		[self complementPathesFromOnePath:eijiroPath];
	}
	[preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)referRYAKUGOROPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	
	NSUserDefaults *defaults = [userDefaultsController defaults];
	NSString *eijiroPath = [defaults stringForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [defaults stringForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [defaults stringForKey:@"waeijiroPath"];
	NSString *reijiroPath = [defaults stringForKey:@"reijiroPath"];
	NSString *searchDir = NSHomeDirectory();
	if (eijiroPath) {
		searchDir = [eijiroPath stringByDeletingLastPathComponent];
	} else if (ryakugoroPath) {
		searchDir = [ryakugoroPath stringByDeletingLastPathComponent];
	} else if (waeijiroPath) {
		searchDir = [waeijiroPath stringByDeletingLastPathComponent];
	} else if (reijiroPath) {
		searchDir = [reijiroPath stringByDeletingLastPathComponent];
	}


    openPanel.directoryURL = [NSURL URLWithString:searchDir];
    openPanel.allowedFileTypes = [NSArray arrayWithObject:@"txt"];

	NSInteger ret = [openPanel runModal];

	if (ret == NSOKButton) {
		NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
		NSUserDefaults *defaults = [userDefaultsController defaults];
		ryakugoroPath = [[openPanel URL] path];
		[ryakugoroPathField setStringValue:ryakugoroPath];
		[defaults setObject:ryakugoroPath forKey:@"ryakugoroPath"];
		[self complementPathesFromOnePath:ryakugoroPath];
	}
	[preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)referWAEIJIROPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	
	NSUserDefaults *defaults = [userDefaultsController defaults];
	NSString *eijiroPath = [defaults stringForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [defaults stringForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [defaults stringForKey:@"waeijiroPath"];
	NSString *reijiroPath = [defaults stringForKey:@"reijiroPath"];
	NSString *searchDir = NSHomeDirectory();
	if (eijiroPath) {
		searchDir = [eijiroPath stringByDeletingLastPathComponent];
	} else if (ryakugoroPath) {
		searchDir = [ryakugoroPath stringByDeletingLastPathComponent];
	} else if (waeijiroPath) {
		searchDir = [waeijiroPath stringByDeletingLastPathComponent];
	} else if (reijiroPath) {
		searchDir = [reijiroPath stringByDeletingLastPathComponent];
	}

    openPanel.directoryURL = [NSURL URLWithString:searchDir];
    openPanel.allowedFileTypes = [NSArray arrayWithObject:@"txt"];

	NSInteger ret = [openPanel runModal];

	if (ret == NSOKButton) {
		NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
		NSUserDefaults *defaults = [userDefaultsController defaults];
		waeijiroPath = [[openPanel URL] path];
		[waeijiroPathField setStringValue:waeijiroPath];
		[defaults setObject:waeijiroPath forKey:@"waeijiroPath"];
		[self complementPathesFromOnePath:waeijiroPath];
	}
	[preferencesWindow makeKeyAndOrderFront:self];
}

- (IBAction)referREIJIROPath:(id)sender {
	NSOpenPanel *openPanel = [NSOpenPanel openPanel];
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	
	NSUserDefaults *defaults = [userDefaultsController defaults];
	NSString *eijiroPath = [defaults stringForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [defaults stringForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [defaults stringForKey:@"waeijiroPath"];
	NSString *reijiroPath = [defaults stringForKey:@"reijiroPath"];
	NSString *searchDir = NSHomeDirectory();
	if (eijiroPath) {
		searchDir = [eijiroPath stringByDeletingLastPathComponent];
	} else if (ryakugoroPath) {
		searchDir = [ryakugoroPath stringByDeletingLastPathComponent];
	} else if (waeijiroPath) {
		searchDir = [waeijiroPath stringByDeletingLastPathComponent];
	} else if (reijiroPath) {
		searchDir = [reijiroPath stringByDeletingLastPathComponent];
	}

    openPanel.directoryURL = [NSURL URLWithString:searchDir];
    openPanel.allowedFileTypes = [NSArray arrayWithObject:@"txt"];

	NSInteger ret = [openPanel runModal];

	if (ret == NSOKButton) {
		NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
		NSUserDefaults *defaults = [userDefaultsController defaults];
		reijiroPath = [[openPanel URL] path];
		[reijiroPathField setStringValue:reijiroPath];
		[defaults setObject:reijiroPath forKey:@"reijiroPath"];
		[self complementPathesFromOnePath:reijiroPath];
	}
	[preferencesWindow makeKeyAndOrderFront:self];
}

- (void)speakingStarted {
	[pronounceButton setImage:[NSImage imageNamed:@"sound_button_pressed"]];
}

- (void)speakingPosChanged:(id)sender
{
	NSRange currentRange = NSMakeRange(
		[speechManager currentPos] + speechStartPos,
		[speechManager currentLength]);
	
    dispatch_sync(dispatch_get_main_queue(), ^{
        [speakingView scrollRangeToVisible:currentRange];
        [speakingView setSelectedRange:currentRange];
        [speakingView display];
    });
}

- (void)speakingDone {
    dispatch_sync(dispatch_get_main_queue(), ^{
        [pronounceButton setImage:[NSImage imageNamed:@"sound_button"]];
        [speakingView setSelectedRange:selectionRange];
    });
}

- (void)speakingErrorOccured:(id)sender
{
	NSRunAlertPanel(
		@"Speech Error",
                    @"%@", [NSString stringWithFormat:@"Error %d occurred.", [speechManager lastError]],
		@"OK", nil, nil);
}

- (IBAction)setResultFont:(id)sender {
	choosingStickyFont = NO;
	
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
	NSString *fontName = [defaults stringForKey:@"fontName"];
	float fontSize = [defaults floatForKey:@"fontSize"];
	NSFont *selectedFont = (fontName && fontSize > 0.0)?
		[NSFont fontWithName:fontName size:fontSize]: [NSFont systemFontOfSize:12.0];
	[fontManager setSelectedFont:selectedFont isMultiple:NO];
	[fontManager setDelegate:self];
	[fontManager orderFrontFontPanel:self];
}

- (IBAction)setStickyFont:(id)sender {
	choosingStickyFont = YES;
	
	NSFontManager *fontManager = [NSFontManager sharedFontManager];
	NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
	NSString *fontName = [defaults stringForKey:@"stickyFontName"];
	float fontSize = [defaults floatForKey:@"stickyFontSize"];
	NSFont *selectedFont = (fontName && fontSize > 0.0)?
		[NSFont fontWithName:fontName size:fontSize]: [NSFont systemFontOfSize:12.0];
	[fontManager setSelectedFont:selectedFont isMultiple:NO];
	[fontManager setDelegate:self];
	[fontManager orderFrontFontPanel:self];
}

- (void)changeFont:(NSFontManager *)fontManager {
	NSFont *selectedFont = [fontManager convertFont:[NSFont systemFontOfSize:12.0]];
	NSString *fontDescription =
		[NSString stringWithFormat:@"%@ - %3.1fpt",
			[selectedFont displayName], [selectedFont pointSize]];
	NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
	if (choosingStickyFont) {
		[defaults setObject:fontDescription forKey:@"stickyFontDescription"];
		[defaults setObject:[selectedFont fontName] forKey:@"stickyFontName"];
		[defaults setFloat:[selectedFont pointSize] forKey:@"stickyFontSize"];
		NSDocumentController *documentController =
			[NSDocumentController sharedDocumentController];
		NSArray *docs = [documentController documents];
		for (int i = 0; i < [docs count]; i++) {
			StickyDocument *document = [docs objectAtIndex:i];
			[document changeFont:selectedFont];
		}
	} else {
		[defaults setObject:fontDescription forKey:@"fontDescription"];
		[defaults setObject:[selectedFont fontName] forKey:@"fontName"];
		[defaults setFloat:[selectedFont pointSize] forKey:@"fontSize"];
		[resultView rebuildFont];
	}
}

- (void)windowDidMove:(NSNotification *)aNotification {
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];
	[defaults setObject:NSStringFromRect([mainWindow frame]) forKey:@"WINDOW_FRAME"];
}

- (void)windowDidResize:(NSNotification *)aNotification {
	NSUserDefaultsController *userDefaultsController =
		[NSUserDefaultsController sharedUserDefaultsController];
	NSUserDefaults *defaults = [userDefaultsController defaults];
	[defaults setObject:NSStringFromRect([mainWindow frame]) forKey:@"WINDOW_FRAME"];
}

/*
- (BOOL)validateMenuItem:(id <NSMenuItem>)menuItem {
	switch ([menuItem tag]) {
		// New Sticky
		case 1:
			return ([[searchWordField stringValue] length] > 0);
		// Close
		case 2:
			return ([NSApp keyWindow] == preferencesWindow ||
				[[[NSApp keyWindow] className] isEqualToString:@"StickyWindow"]);
		// Go Back
		case 30:
			return ([previousWordList count] > 1);
		// Go Forward
		case 31:
			return ([afterWordList count] > 0);
		// Search First Guess
		case 32:
			return (firstGuessWord != nil);
		// Search Second Guess
		case 33:
			return (secondGuessWord != nil);
	}
	return YES;
}
 */

- (IBAction)closeSticky:(id)sender {
	if ([NSApp keyWindow] != mainWindow) {
		[[NSApp keyWindow] orderOut:self];
	}
}

- (IBAction)transparencyChanged:(NSSlider *)slider {
	float alphaValue = [slider floatValue];
	NSDocumentController *documentController =
		[NSDocumentController sharedDocumentController];
	NSArray *docs = [documentController documents];
	int i;
	for (i = 0; i < [docs count]; i++) {
		StickyDocument *document = [docs objectAtIndex:i];
		[document setStickyAlphaValue:alphaValue];
	}
}

// 発音記号の補正
- (NSString *)correctPronunciationSymbolFromString:(NSString *)string {
	int i;
	int length = [string length];
	unichar *buffer = malloc(sizeof(unichar) * length);
	NSString *result;
	BOOL pronunciation = NO;
	int pos = 0;
	for (i = 0; i < length; i++) {
		if (!pronunciation && i+3 < length) {
			unichar c[5];
			c[0] = [string characterAtIndex:i];
			c[1] = [string characterAtIndex:i+1];
			c[2] = [string characterAtIndex:i+2];
			c[3] = [string characterAtIndex:i+3];
			if (c[0] == 0x3010 && c[1] == 0x767a && c[2] == 0x97f3 && c[3] == 0x3011) {
				pronunciation = YES;
				buffer[pos++] = c[0];
				buffer[pos++] = c[1];
				buffer[pos++] = c[2];
				buffer[pos++] = c[3];
				i += 3;
			} else if (i+4 < length) {
				c[4] = [string characterAtIndex:i+4];
				if (c[0] == 0x3010 && c[1] == 0x767a && c[2] == 0x97f3 && c[3] == 0xff01 && c[4] == 0x3011) {
					pronunciation = YES;
					buffer[pos++] = c[0];
					buffer[pos++] = c[1];
					buffer[pos++] = c[2];
					buffer[pos++] = c[3];
					buffer[pos++] = c[4];
					i += 4;
				} else {
					buffer[pos++] = c[0];
				}
			} else {
				buffer[pos++] = c[0];
			}
		} else if (pronunciation) {
			unichar c1 = [string characterAtIndex:i];
			if (c1 == 0x3001) {
				buffer[pos++] = c1;
				pronunciation = NO;
			}
			if (pronunciation) {
				unichar c = c1;
				BOOL pass = NO;
				switch (c1) {
					case 0x0027:	// '
						c = 0x0301;
						break;
					case 0x003a:	// :
						c = 0x02d0;
						break;
					case 0x0060:	// `
						c = 0x0300;
						break;
					case 0x0061: // 傘の付いたa
								 // ae
						if (i+1 < length && [string characterAtIndex:i+1] == 0x65) {
							c = 0x00e6;
							i++;
						}
						break;
					case 0x044d:	// eのひっくり返ったa
						c = 0x0259;
						break;
					case 0x039b:	// ターンA
						c = 0x028c;
						break;
					case 0x03b1:	// a
						c = 0x0251;
						break;
					case 0x03b4:	// th（濁音）
						c = 0x00f0;
						break;
					case 0x03b7:	// ng
						c = 0x014b;
						break;
					case 0x03b8:	// th
						c = 0x03b8;
						break;
					case 0x0437:	// zg
						c = 0x0292;
						break;
					case 0x20dd:	// sh
						c = 0x0283;
						break;
					case 0x5c0f:	// 間に挟まっている正体不明の文字（ハイフン？）
						pass = YES;
						break;
					case 0xff4f:	// cがひっくり返ったo
						c = 0x0254;
						break;
				}
				// 変換した結果を追加
				if (!pass) {
					buffer[pos++] = c;
				}
			}
		} else {
			// 追加
			buffer[pos++] = [string characterAtIndex:i];
		}
	}
	result = [[NSString alloc] initWithCharacters:buffer length:pos];
	free(buffer);
	return result;
}

- (NSString *)stringByRemoveRubiesFromString:(NSString *)string {
	int i;
	int pos = 0;
	int length = [string length];
	unichar *buffer = malloc(sizeof(unichar) * length);
	NSString *result;
	BOOL ignoring = NO;
	
	for (i = 0; i < length; i++) {
		unichar c = [string characterAtIndex:i];
		if (c == 0xff5b) {	// 全角の「｛」
			ignoring = YES;
		}
		if (!ignoring) {
			buffer[pos++] = c;
		}
		if (c == 0xff5d) {	// 全角の「｝」
			ignoring = NO;
		}
	}
	
	result = [[NSString alloc] initWithCharacters:buffer length:pos];
	free(buffer);
	return result;
}

- (void)observeValueForKeyPath:(NSString *)keyPath
					  ofObject:(id)defaults 
                        change:(NSDictionary *)change
					   context:(void *)context
{
	if ([keyPath isEqualToString:@"alwaysOnTop"]) {
		if ([defaults boolForKey:@"alwaysOnTop"]) {
			[mainWindow setLevel:NSStatusWindowLevel];
		} else {
			[mainWindow setLevel:NSNormalWindowLevel];
		}
	}
}

- (void)complementPathesFromOnePath:(NSString *)aPath {
	NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
	NSString *eijiroPath = [defaults stringForKey:@"eijiroPath"];
	NSString *ryakugoroPath = [defaults stringForKey:@"ryakugoroPath"];
	NSString *waeijiroPath = [defaults stringForKey:@"waeijiroPath"];
	NSString *reijiroPath = [defaults stringForKey:@"reijiroPath"];
	
	NSString *basePath = [aPath stringByDeletingLastPathComponent];
	NSString *versionStr =
		[[aPath stringByDeletingPathExtension] substringFromIndex:[aPath length]-6];
	NSFileManager *fileManager = [NSFileManager defaultManager];
	
	if (!eijiroPath) {
		eijiroPath = [basePath stringByAppendingPathComponent:
			[NSString stringWithFormat:@"EIJIRO%@.TXT", versionStr]];
		if ([fileManager fileExistsAtPath:eijiroPath]) {
			[defaults setObject:eijiroPath forKey:@"eijiroPath"];
			[eijiroPathField setStringValue:eijiroPath];
		}
	}
	if (!ryakugoroPath) {
		ryakugoroPath = [basePath stringByAppendingPathComponent:
			[NSString stringWithFormat:@"RYAKU%@.TXT", versionStr]];
		if ([fileManager fileExistsAtPath:ryakugoroPath]) {
			[defaults setObject:ryakugoroPath forKey:@"ryakugoroPath"];
			[ryakugoroPathField setStringValue:ryakugoroPath];
		}
	}
	if (!waeijiroPath) {
		waeijiroPath = [basePath stringByAppendingPathComponent:
			[NSString stringWithFormat:@"WAEIJI%@.TXT", versionStr]];
		if ([fileManager fileExistsAtPath:waeijiroPath]) {
			[defaults setObject:waeijiroPath forKey:@"waeijiroPath"];
			[waeijiroPathField setStringValue:waeijiroPath];
		}
	}
	if (!reijiroPath) {
		reijiroPath = [basePath stringByAppendingPathComponent:
			[NSString stringWithFormat:@"REIJI%@.TXT", versionStr]];
		if ([fileManager fileExistsAtPath:reijiroPath]) {
			[defaults setObject:reijiroPath forKey:@"reijiroPath"];
			[reijiroPathField setStringValue:reijiroPath];
		}
	}
}

- (void)addHistory:(NSString *)word {
	if (!word || [word length] == 0) {
		return;
	}
	[afterWordList removeAllObjects];
	if (existsLastWord) {
		[previousWordList removeObjectAtIndex:[previousWordList count]-1];
		existsLastWord = NO;
	}
	BOOL isSameOfLast = NO;
	if ([previousWordList count] > 0) {
		NSString *lastWord = [previousWordList objectAtIndex:[previousWordList count]-1];
		isSameOfLast = [lastWord isEqualToString:word];
	}
	if (!isSameOfLast) {
		[previousWordList addObject:word];
	}
	[self updateHistoryUI];
}

- (void)updateLastHistory:(NSString *)word {
	if (existsLastWord) {
		[previousWordList removeObjectAtIndex:[previousWordList count]-1];
	}
	[afterWordList removeAllObjects];
	[previousWordList addObject:word];
	existsLastWord = YES;
	[self updateHistoryUI];
}

- (void)updateHistoryUI {
	[backButton setEnabled:([previousWordList count] > 1)? NSOnState: NSOffState];
	[goButton setEnabled:([afterWordList count] > 0)? NSOnState: NSOffState];
}

- (IBAction)goPrevious:(id)sender {
	if ([previousWordList count] < 2) {
		return;
	}
	NSString *lastWord = [previousWordList objectAtIndex:[previousWordList count]-1];
	[afterWordList addObject:lastWord];
	[previousWordList removeObjectAtIndex:[previousWordList count]-1];
	NSString *previousWord = [previousWordList objectAtIndex:[previousWordList count]-1];

	[currentSearchWordLock lock];
	[currentSearchWord release];
	currentSearchWord = [previousWord retain];
	[currentSearchWordLock unlock];
	[self showResultView];
	[pronounceButton setEnabled:YES];
	[speechManager stopSpeaking];
	[searchWordField setStringValue:previousWord];
	[searchWordField selectText:self];
	[NSThread detachNewThreadSelector:@selector(searchForWord:) toTarget:self withObject:previousWord];

	existsLastWord = NO;
	[self updateHistoryUI];
}

- (IBAction)goAfter:(id)sender {
	if ([afterWordList count] < 1) {
		return;
	}

	NSString *nextWord = [afterWordList objectAtIndex:[afterWordList count]-1];
	[previousWordList addObject:nextWord];
	[afterWordList removeObjectAtIndex:[afterWordList count]-1];
	
	[currentSearchWordLock lock];
	[currentSearchWord release];
	currentSearchWord = [nextWord retain];
	[currentSearchWordLock unlock];
	[self showResultView];
	[pronounceButton setEnabled:YES];
	[speechManager stopSpeaking];
	[searchWordField setStringValue:nextWord];
	[searchWordField selectText:self];
	[NSThread detachNewThreadSelector:@selector(searchForWord:) toTarget:self withObject:nextWord];
	
	[self updateHistoryUI];
}

- (IBAction)searchFirstGuess:(id)sender {
	if (!firstGuessWord) {
		return;
	}
	NSString *searchWord = [searchWordField stringValue];
	[self addHistory:searchWord];
	
	[self addHistory:firstGuessWord];
	
	[currentSearchWordLock lock];
	[currentSearchWord release];
	currentSearchWord = [firstGuessWord retain];
	[currentSearchWordLock unlock];
	[self showResultView];
	[pronounceButton setEnabled:YES];
	[speechManager stopSpeaking];
	[searchWordField setStringValue:currentSearchWord];
	[searchWordField selectText:self];
	[NSThread detachNewThreadSelector:@selector(searchForWord:) toTarget:self withObject:currentSearchWord];	
}

- (IBAction)searchSecondGuess:(id)sender {
	if (!secondGuessWord) {
		return;
	}
	NSString *searchWord = [searchWordField stringValue];
	[self addHistory:searchWord];
	
	[self addHistory:secondGuessWord];
	
	[currentSearchWordLock lock];
	[currentSearchWord release];
	currentSearchWord = [secondGuessWord retain];
	[currentSearchWordLock unlock];
	[self showResultView];
	[pronounceButton setEnabled:YES];
	[speechManager stopSpeaking];
	[searchWordField setStringValue:currentSearchWord];
	[searchWordField selectText:self];
	[NSThread detachNewThreadSelector:@selector(searchForWord:) toTarget:self withObject:currentSearchWord];	
}

- (void)clearGuesses {
	[firstGuessWord release];
	firstGuessWord = nil;
	[secondGuessWord release];
	secondGuessWord = nil;
}

- (void)setFirstGuess:(NSString *)guess {
	[firstGuessWord release];
	firstGuessWord = [guess retain];
}

- (void)setSecondGuess:(NSString *)guess {
	[secondGuessWord release];
	secondGuessWord = [guess retain];
}

- (BOOL)textView:(NSTextView *)textView
   clickedOnLink:(id)link atIndex:(unsigned)charIndex
{
	NSString *searchWord = [searchWordField stringValue];
	[self addHistory:searchWord];

	[self addHistory:link];

	[currentSearchWordLock lock];
	[currentSearchWord release];
	currentSearchWord = [link retain];
	[currentSearchWordLock unlock];
	[self showResultView];
	[pronounceButton setEnabled:YES];
	[speechManager stopSpeaking];
	[searchWordField setStringValue:currentSearchWord];
	[searchWordField selectText:self];
	[NSThread detachNewThreadSelector:@selector(searchForWord:) toTarget:self withObject:currentSearchWord];	
	
	return YES;
}

- (NSString *)fixVer80ExampleStr:(NSString *)string {
	NSMutableString *ret = [[NSMutableString alloc] init];
	NSString *prefixStr = NSLocalizedString(@"VER80_EXAMPLE_PREFIX", @"VER80_EXAMPLE_PREFIX");
	int count = 0;
	while (YES) {
		NSRange prefixRange = [string rangeOfString:prefixStr];
		if (prefixRange.location == NSNotFound) {
			[ret appendString:string];
			break;
		}
		[ret appendString:[string substringToIndex:prefixRange.location]];
		if (count == 0) {
			[ret appendString:NSLocalizedString(@"EXAMPLE_FIRST_PREFIX", @"EXAMPLE_FIRST_PREFIX")];
		} else {
			[ret appendString:@" / "];
		}
		count++;
		string = [string substringFromIndex:prefixRange.location+2];
		//		NSLog(@"--%@", string);
		//		break;
	}
	return ret;
}

- (IBAction)resetPosition:(id)sender {
    [mainWindow setFrameTopLeftPoint:NSMakePoint(10, 40)];
}

@end
