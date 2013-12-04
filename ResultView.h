/* ResultView */

#import "NSTextViewWithLinks.h"

@interface ResultView : NSTextViewWithLinks {
	NSMutableArray *resultBuffer;
	NSMutableDictionary *normalTextAttrDict;
}

- (void)clearResult;
- (void)addResult:(NSString *)result;
- (void)flushResultForSearchWord:(NSString *)searchWord;
- (NSAttributedString *)attrStr;
- (void)rebuildFont;
- (void)addGuess:(NSString *)guess atIndex:(int)index;
- (void)addSeparator;

@end
