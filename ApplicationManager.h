/* ApplicationManager */

#import <Cocoa/Cocoa.h>

@class BackgroundView;
@class ControllableScroller;
@class MetalButton;
@class ResizeView;
@class ResultView;
@class SpeechManager;

@interface ApplicationManager : NSObject
{
    IBOutlet NSWindow		*mainWindow;
    IBOutlet NSSearchField  *searchWordField;
    IBOutlet NSScrollView   *scrollView;
    IBOutlet ResizeView		*resizeView;
    IBOutlet BackgroundView	*backgroundView;
    IBOutlet NSWindow		*preferencesWindow;
    IBOutlet NSTextField	*eijiroPathField;
    IBOutlet NSTextField	*ryakugoroPathField;
    IBOutlet NSTextField	*waeijiroPathField;
    IBOutlet NSTextField	*reijiroPathField;
	IBOutlet ResultView		*resultView;
    IBOutlet MetalButton	*pronounceButton;
	IBOutlet MetalButton	*backButton;
	IBOutlet MetalButton	*goButton;
	IBOutlet NSMenuItem		*moveButtonMenuItem;
	IBOutlet NSMenuItem		*pronounceButtonMenuItem;
	
	NSTextFieldCell			*fieldCell;
	ControllableScroller	*scroller;
	
	BOOL choosingStickyFont;

	NSString	*currentSearchWord;
	NSLock		*currentSearchWordLock;

	NSMutableArray *previousWordList;
	NSMutableArray *afterWordList;
	
	NSString *firstGuessWord;
	NSString *secondGuessWord;
	
	BOOL	isSearchResultShown;
	
	SpeechManager   *speechManager;
	NSTextView *speakingView;
	NSRange	selectionRange;			// 選択されている文字列の範囲
    long	speechStartPos;			// 読み上げ開始位置
	BOOL	existsLastWord;
}

+ (ApplicationManager *)sharedManager;

- (IBAction)showPreferences:(id)sender;
- (IBAction)savePreferences:(id)sender;
- (IBAction)revertPreferences:(id)sender;

- (IBAction)makeNewSticky:(id)sender;
- (IBAction)closeSticky:(id)sender;

- (IBAction)hideMoveButton:(id)sender;
- (IBAction)hidePronounceButton:(id)sender;

- (IBAction)referEIJIROPath:(id)sender;
- (IBAction)referRYAKUGOROPath:(id)sender;
- (IBAction)referWAEIJIROPath:(id)sender;
- (IBAction)referREIJIROPath:(id)sender;
- (IBAction)transparencyChanged:(NSSlider *)slider;

- (IBAction)pronounce:(id)sender;

- (IBAction)goPrevious:(id)sender;
- (IBAction)goAfter:(id)sender;

- (IBAction)resetPosition:(id)sender;

- (void)searchForWord:(NSString *)searchWord;
- (int)binarySearchForWord:(NSString *)searchWord
			searchWordData:(NSData *)searchWordData
				  fromData:(NSData *)data
			  removeRubies:(BOOL)removeRubies;
- (BOOL)checkIfActiveSearchWord:(NSString *)searchWord;

- (BOOL)isSearchResultShown;

- (void)clearResultForSearchWord:(NSString *)searchWord;
- (void)addSeparatorForSearchWord:(NSString *)searchWord;
- (void)addResult:(NSArray *)info;
- (void)flushResultForSearchWord:(NSString *)searchWord;

- (NSString *)correctPronunciationSymbolFromString:(NSString *)string;
- (NSString *)stringByRemoveRubiesFromString:(NSString *)string;
- (NSString *)fixVer80ExampleStr:(NSString *)string;

- (void)complementPathesFromOnePath:(NSString *)aPath;

- (void)showResultView;
- (void)hideResultView;

- (void)addHistory:(NSString *)word;
- (void)updateLastHistory:(NSString *)word;
- (void)updateHistoryUI;

- (void)clearGuesses;
- (void)setFirstGuess:(NSString *)guess;
- (void)setSecondGuess:(NSString *)guess;

@end
