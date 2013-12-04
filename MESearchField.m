#import "MESearchField.h"

@implementation MESearchField

- (void)awakeFromNib {
//	[self registerForDraggedTypes:[NSArray arrayWithObject:NSStringPboardType]];
}

- (BOOL)acceptsFirstMouse:(NSEvent *)theEvent {
	return NO;
}

/*- (NSDragOperation)draggingEntered:(id <NSDraggingInfo>)sender {
	return NSDragOperationCopy;
}

- (void)draggingExited:(id <NSDraggingInfo>)sender {
}

- (void)draggingEnded:(id <NSDraggingInfo>)sender {
}

- (NSDragOperation)draggingUpdated:(id <NSDraggingInfo>)sender {
	return NSDragOperationCopy;
}

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender {
	return YES;
}

- (void)concludeDragOperation:(id <NSDraggingInfo>)sender {
}*/

@end
