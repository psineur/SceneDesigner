//
//  SDDocument.m
//  SceneDesigner
//

#import "SDDocument.h"
#import "SDWindowController.h"
#import "HelloWorldLayer.h"
#import "SDNode.h"
#import "AppDelegate.h"

@implementation SDDocument

@synthesize drawingView = _drawingView;

- (id)init
{
    self = [super init];
    if (self)
    {
    }
    
    return self;
}

- (void)dealloc
{
    [super dealloc];
}

// TODO: put this logic in makeWindowControllers and set drawing view in init
- (void)setDrawingView:(HelloWorldLayer *)drawingView
{
    if (drawingView != _drawingView)
    {
        [_drawingView release];
        _drawingView = [drawingView retain];
        
        if ([[self windowControllers] count] > 0)
        {
            SDWindowController *wc = (SDWindowController *)[[self windowControllers] objectAtIndex:0];
            
            [[self undoManager] disableUndoRegistration];
            for (CCNode<SDNodeProtocol> *node in _nodesToAdd)
                [wc addNodeToLayer:node];
            [[self undoManager] enableUndoRegistration];
        }
        else
        {
            CCLOG(@"%s - no window controllers found", __FUNCTION__);
        }
        
        [_nodesToAdd release];
        _nodesToAdd = nil;
    }
}

- (void)makeWindowControllers
{
    SDWindowController *wc = [[SDWindowController alloc] initWithWindowNibName:@"SDDocument"];
    [self addWindowController:wc];
    [wc release];
}

- (NSString *)displayName
{
    // Apple's HIG say that untitled documents should say "untitled," not "Untitled"
    // NSDocument violates this, however. [self fileURL] will be nil if the file
    // is unsaved, which means it's untitled. In that case, we replace the first
    // character with a lowercase version
    
    NSMutableString *displayName = [NSMutableString stringWithString:[super displayName]];
    
    if ([self fileURL] == nil)
    {
        NSString *firstCharacter = [[displayName substringToIndex:1] lowercaseString];
        [displayName deleteCharactersInRange:NSMakeRange(0, 1)];
        [displayName insertString:firstCharacter atIndex:0];
    }
    
	return [NSString stringWithString:displayName];
}

- (NSData *)dataOfType:(NSString *)typeName error:(NSError **)outError
{
    NSMutableArray *array = [NSMutableArray arrayWithCapacity:[[_drawingView children] count]];
    
    for (CCNode<SDNodeProtocol> *child in [_drawingView children])
        if ([child isKindOfClass:[CCNode class]] && [child conformsToProtocol:@protocol(SDNodeProtocol)])
            [array addObject:[child dictionaryRepresentation]];
    
    return [NSPropertyListSerialization dataWithPropertyList:array format:NSPropertyListBinaryFormat_v1_0 options:0 error:NULL];
}

- (BOOL)readFromData:(NSData *)data ofType:(NSString *)typeName error:(NSError **)outError
{
    SceneDesignerAppDelegate *delegate = (SceneDesignerAppDelegate *)[NSApp delegate];
    if ([[CCDirector sharedDirector] runningScene] == nil)
        [delegate startCocos2D];
    
    NSArray *children = [NSPropertyListSerialization propertyListWithData:data options:NSPropertyListImmutable format:NULL error:outError];
    if (![children isKindOfClass:[NSArray class]])
    {
        CCLOG(@"%s - property list not an array", __FUNCTION__);
        return NO;
    }
    
    _nodesToAdd = [[NSMutableArray arrayWithCapacity:[children count]] retain];
    for (NSDictionary *child in children)
    {
        Class childClass = NSClassFromString([child objectForKey:@"className"]);
        if ([childClass isSubclassOfClass:[CCNode class]] && [childClass conformsToProtocol:@protocol(SDNodeProtocol)])
        {
            CCNode<SDNodeProtocol> *node = [childClass setupFromDictionaryRepresentation:child];
            [_nodesToAdd addObject:node];
        }
    }
    
    return YES;
}

+ (BOOL)autosavesInPlace
{
    return NO;
}

@end
