#import "ResultView.h"
#import "StringUtil.h"
#import "ApplicationManager.h"

@implementation ResultView

- (void)awakeFromNib {
	resultBuffer = [[NSMutableArray arrayWithCapacity:10] retain];
	[self rebuildFont];
}

- (void)dealloc {
	[resultBuffer release];
	[normalTextAttrDict release];
	[super dealloc];
}

- (void)clearResult {
	[[ApplicationManager sharedManager] clearGuesses];
	[resultBuffer removeAllObjects];
	[self setString:@""];
}

- (void)addResult:(NSString *)result {
	NSAttributedString *attrStr =
		[[NSAttributedString alloc] initWithString:result attributes:normalTextAttrDict];
	[resultBuffer addObject:attrStr];
	[attrStr release];
}

- (void)addSeparator {
	[self addResult:@"--------\n"];
}

- (void)addGuess:(NSString *)guess atIndex:(int)index {
	if (index == 0) {
		[[ApplicationManager sharedManager] setFirstGuess:guess];
	} else if (index == 1) {
		[[ApplicationManager sharedManager] setSecondGuess:guess];
	}
	
	NSMutableDictionary *linkAttrDict = [NSMutableDictionary dictionary];
	[linkAttrDict addEntriesFromDictionary:normalTextAttrDict];
	[linkAttrDict setObject:guess forKey:NSLinkAttributeName];
	[self addResult:[NSString stringWithFormat:@"\t%d. ", index+1]];

	NSAttributedString *attrStr =
		[[NSAttributedString alloc] initWithString:guess attributes:linkAttrDict];
	[resultBuffer addObject:attrStr];
	[attrStr release];
	
	[self addResult:@"\n"];
}

- (void)flushResultForSearchWord:(NSString *)searchWord {
	if ([resultBuffer count] == 0) {
		[self addResult:[NSString stringWithFormat:
			NSLocalizedString(@"Not found '%@'.", @""), searchWord]];
		BOOL isAllCapital;
		if (isEnglishWord(searchWord, &isAllCapital)) {
			NSSpellChecker *spellChecker = [NSSpellChecker sharedSpellChecker];
			NSArray *guesses = [spellChecker guessesForWord:searchWord];
			if ([guesses count] > 0) {
				[self addResult:NSLocalizedString(@"\n\nGuesses:\n", @"")];
				for (int i = 0; i < [guesses count]; i++) {
					NSString *guess = [guesses objectAtIndex:i];
					[self addGuess:guess atIndex:i];
				}
			} else {
				[self addResult:NSLocalizedString(@"\n\nNo guess.", @"")];
			}
		}
	}
	for (int i = 0; i < [resultBuffer count]; i++) {
		NSAttributedString *attrStr = [resultBuffer objectAtIndex:i];
		[[self textStorage] appendAttributedString:attrStr];
	}
	[resultBuffer removeAllObjects];
	[[self window] resetCursorRects];
}

- (NSAttributedString *)attrStr {
	return [self textStorage];
}

- (void)rebuildFont {
	[normalTextAttrDict release];
	NSUserDefaults *defaults = [[NSUserDefaultsController sharedUserDefaultsController] defaults];
	NSString *fontName = [defaults stringForKey:@"fontName"];
	if (!fontName) {
		fontName = @"HiraKakuPro-W3";
	}
	float fontSize = [defaults floatForKey:@"fontSize"];
	if (fontSize == 0) {
		fontSize = 11;
	}
	normalTextAttrDict = [[NSMutableDictionary dictionary] retain];
	[normalTextAttrDict setObject:[NSFont fontWithName:fontName size:fontSize] forKey:NSFontAttributeName];
	
	NSMutableAttributedString *toAttrStr = [self textStorage];
	//	[toAttrStr setAttributes:normalTextAttrDict range:NSMakeRange(0, [toAttrStr length])];
	[toAttrStr addAttribute:NSFontAttributeName
					  value:[NSFont fontWithName:fontName size:fontSize]
					  range:NSMakeRange(0, [toAttrStr length])];
}

@end
