//
//  AppDelegate.m
//  Contxt
//
//  Created by Young Hoo Kim on 12/7/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import "AppDelegate.h"
#import "PXSourceList.h"
#import "SourceListItem.h"
#import "StylesController.h"
#import "SCEvents.h"
#import "SCEvent.h"
#import "NSFileManager+DirectoryLocations.h"

#import "WikiStorage.h"
#import "HistoryManager.h"
#import "NSString+Page.h"
#import "NoodleLineNumberView.h"
#import "NoodleLineNumberMarker.h"

#import "ContxtDefaultsKeys.h"

#include "discountWrapper.h"

@implementation AppDelegate

+ (void)initialize {
    [[NSUserDefaults standardUserDefaults] registerDefaults:[NSDictionary dictionaryWithObjectsAndKeys:
                                                             [NSNumber numberWithBool:NO], CTShowLineNumbersDefaultsKey, 
                                                             nil]];
}

@synthesize window = _window;
@synthesize editorView;
@synthesize currentPage;

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [pageToIndexDict release];
    [storageEvents release];
    [sourceListItems release];
    [super dealloc];
}

- (IBAction)openStylesFolder:(id)sender {
    [[NSWorkspace sharedWorkspace] openURL:[NSURL fileURLWithPath:[StylesController stylesFolderPath]]];
}

- (IBAction)selectPreviewStyle:(id)sender {
    NSMenuItem *selectedMenuItem = (NSMenuItem *)sender;
    [StylesController sharedStylesController].selectedStyle = [selectedMenuItem title];
    for (NSMenuItem *item in [[previewStylesMenuItem submenu] itemArray]) {
        if (item == selectedMenuItem) {
            [item setState:NSOnState];
        } else {
            [item setState:NSOffState];
        }
    }
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[[StylesController sharedStylesController] selectedPreviewURL]]];    
}

- (void)awakeFromNib {
    [sourceList registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]];
    NSUInteger count = 1;
    for (NSString *styleName in [StylesController sharedStylesController].styles) {
        NSString *keyEquivalent = count < 10 ? [NSString stringWithFormat:@"%i", count] : @"";
        NSMenuItem *styleMenuItem = [[[NSMenuItem alloc] initWithTitle:styleName action:@selector(selectPreviewStyle:) keyEquivalent:keyEquivalent] autorelease];
        [styleMenuItem setKeyEquivalentModifierMask:NSAlternateKeyMask];
        [[previewStylesMenuItem submenu] insertItem:styleMenuItem atIndex:count - 1];
        if ([styleName isEqualToString:[StylesController sharedStylesController].selectedStyle]) {
            [styleMenuItem setState:NSOnState];
        }
        count += 1;
    }
}

- (BOOL)application:(NSApplication *)theApplication openFile:(NSString *)filename {
    NSString *page = [[WikiStorage sharedWikiStorage] importFileToPage:filename];
    [self reloadSourceList];
    [self openWikiPage:page updateHistory:YES];
    return YES;
}

- (void)reloadSourceList {
    SourceListItem *pagesItem = [sourceListItems objectAtIndex:0];
    NSMutableArray *pages = [NSMutableArray array];
    NSUInteger row = 1;
    [pageToIndexDict removeAllObjects];
    for (NSString *fileName in [WikiStorage sharedWikiStorage].files) {
        if ([[fileName pathExtension] isEqualToString:@"txt"]) {
            NSString *page = fileName;
            SourceListItem *pageItem = [SourceListItem itemWithTitle:[page pageTitle] identifier:page icon:nil];
            [pageToIndexDict setObject:[NSNumber numberWithUnsignedInteger:row] forKey:page];
            [pages addObject: pageItem];
            row += 1;
        }
    }
    [pagesItem setChildren:pages];
    [pagesItem setBadgeValue:row - 1];
    [sourceList reloadData];
}


- (void)setupStorageEventListener {
    if (storageEvents) return;
    
    storageEvents = [[SCEvents alloc] init];
    [storageEvents setDelegate:self];
    
    NSMutableArray *paths = [NSMutableArray arrayWithObject:[[WikiStorage sharedWikiStorage].storageURL path]];
	[storageEvents startWatchingPaths:paths];
	NSLog(@"%@", [storageEvents streamDescription]);	
}


- (void)focusAndSelectEditorView {
    [self markdownMode:self];
    [editorView performSelector:@selector(selectAll:) withObject:self afterDelay:0];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:CTShowLineNumbersDefaultsKey]) {
        if ([[NSUserDefaults standardUserDefaults] boolForKey:CTShowLineNumbersDefaultsKey]) {
            [[editorView enclosingScrollView] setRulersVisible:YES];        
        } else {
            [[editorView enclosingScrollView] setRulersVisible:NO];        
        }
    } 
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {    
    pageToIndexDict = [[NSMutableDictionary alloc] init];

    [HistoryManager sharedHistoryManager];
    [WikiStorage sharedWikiStorage];
    [self setupStorageEventListener];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textDidChange:)
                                                 name:@"kDidChangeText"
                                               object:nil];
    
    sourceListItems = [[NSMutableArray alloc] init];
    SourceListItem *pagesItem = [SourceListItem itemWithTitle:@"PAGES" identifier:@"Pages"];
    [sourceListItems addObject:pagesItem];
    [self reloadSourceList];
    
    NoodleLineNumberView * lineNumberView = [[[NoodleLineNumberView alloc] initWithScrollView:[editorView enclosingScrollView]] autorelease];
    [lineNumberView setBackgroundColor:[NSColor whiteColor]];
    [lineNumberView setTextColor:[NSColor colorWithCalibratedRed:0.22 
                                                           green:0.41 
                                                            blue:0.69 alpha:1]];
    [[editorView enclosingScrollView] setVerticalRulerView:lineNumberView];
    [[editorView enclosingScrollView] setHasHorizontalRuler:NO];
    [[editorView enclosingScrollView] setHasVerticalRuler:YES];
    if ([[NSUserDefaults standardUserDefaults] boolForKey:CTShowLineNumbersDefaultsKey]) {
        [[editorView enclosingScrollView] setRulersVisible:YES];
    }
    [[editorView textStorage] setDelegate:(id)self];
    editorView.delegate = self;
    
    [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:CTShowLineNumbersDefaultsKey options:NSKeyValueObservingOptionNew context:NULL];
    
    NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:1];
    [sourceList selectRowIndexes:indexSet byExtendingSelection:NO];
    [[webView mainFrame] loadRequest:[NSURLRequest requestWithURL:[[StylesController sharedStylesController] selectedPreviewURL]]];    
}

- (NSString *)markdownWikiExtensionProcess:(NSString *)markdown {
    NSString *replaceTemplate = @"\\[$1\\](wiki:\\/\\/$1.txt)";
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[\\[(.+)\\]\\]" options:NSRegularExpressionCaseInsensitive error:nil];
    markdown = [regex stringByReplacingMatchesInString:markdown options:0 range:NSMakeRange(0, markdown.length) withTemplate:replaceTemplate];
    
    //Local Image References
    replaceTemplate = [NSString stringWithFormat:@"!\\[$1\\]\\(%@$2\\)", [WikiStorage sharedWikiStorage].storageURL];
    regex = [NSRegularExpression regularExpressionWithPattern:@"!\\[(.*?)\\][ ]?\\((?!file://)(?!http://)(.+)\\)" options:NSRegularExpressionCaseInsensitive error:nil];    
    markdown = [regex stringByReplacingMatchesInString:markdown options:0 range:NSMakeRange(0, markdown.length) withTemplate:replaceTemplate];

    return markdown;
}

- (void)updatePreview {
    NSString *markdown = [editorView.textStorage string];
    markdown = [self markdownWikiExtensionProcess:markdown];
    NSString *html = discountToHTML(markdown);
    html = [html stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
	NSString *noDoubleQutation = [html stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
	NSString *jsCommand = [NSString stringWithFormat:@"preview(\"%@\");", noDoubleQutation];
    [webView stringByEvaluatingJavaScriptFromString:jsCommand];
}

- (IBAction)addUntitledPage:(id)sender {
    NSString *page = [[WikiStorage sharedWikiStorage] addUntitledPageWithContent:@"Describe %@ Here"];
    [self reloadSourceList];
    [self openWikiPage:page];
    [self focusAndSelectEditorView];
}

- (void)selectPageByTitle:(NSString *)title {
    SourceListItem *pagesItem = [sourceListItems objectAtIndex:0];
    NSUInteger row = 1;
    for (SourceListItem *item in pagesItem.children) {
        if ([[item title] isEqualToString:title]) {
            [sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:row] byExtendingSelection:NO];
            break;
        }
        row += 1;
    }
}

- (IBAction)markdownMode:(id)sender {
    [markdownSegmentedControl setSelectedSegment:0];
    [markdownTabView selectTabViewItemAtIndex:0];
    [self.window makeFirstResponder:editorView];
}

- (IBAction)previewMode:(id)sender {
    [markdownSegmentedControl setSelectedSegment:1];
    [markdownTabView selectTabViewItemAtIndex:1];
}

- (void)updateLastModified {
    [lastModifiedTextField setStringValue:[NSString stringWithFormat:@"This page was last modified on %@", [[WikiStorage sharedWikiStorage] lastModifiedByPage:self.currentPage]]];
}

- (void)setCurrentPage:(NSString *)newCurrentPage {
    [currentPage autorelease];
    currentPage = [newCurrentPage retain];
    [self updateLastModified];
}


#pragma mark -
#pragma makr History
- (void)openWikiPageByURL:(NSURL *)pageURL updateHistory:(BOOL)updateHistory {
    NSString *path = [[pageURL resourceSpecifier] substringFromIndex:2];
    [self openWikiPage:path updateHistory:updateHistory];

}

- (void)openWikiPage:(NSString *)page {
    [self updateBrowsingSegmentedControl];
    if (page == nil) {
        return;
    }
    
    self.currentPage = page;
    if ([[WikiStorage sharedWikiStorage] isExistingPage:page]) {
        NSString *content = [[WikiStorage sharedWikiStorage] readWikiPage:page];
        if (content) {
            [editorView setString:content];
            [self performSelector:@selector(updatePreview) withObject:nil afterDelay:0.1];
            
            NSUInteger pageIndex = [[pageToIndexDict valueForKey:page] intValue];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:pageIndex];
            [sourceList selectRowIndexes:indexSet byExtendingSelection:NO];
            
        }        
    } else {
        [[WikiStorage sharedWikiStorage] writeWikiPage:page content:[NSString stringWithFormat:@"Describe %@ Here", page]];
        [self reloadSourceList];
        [self openWikiPage:page updateHistory:YES];
        [self focusAndSelectEditorView];
    }
}

- (void)openWikiPage:(NSString *)page updateHistory:(BOOL)updateHistory {
    if (self.currentPage != nil) {
        [[HistoryManager sharedHistoryManager].backwardPages addObject:[self.currentPage copy]];
    }
    [self openWikiPage:page];
}

- (void)updateBrowsingSegmentedControl {
    if ([[HistoryManager sharedHistoryManager].backwardPages count] > 0) {
        [browsingSegmentedControl setEnabled:YES forSegment:0];
    } else {
        [browsingSegmentedControl setEnabled:NO forSegment:0];        
    }
    if ([[HistoryManager sharedHistoryManager].forwardPages count] > 0) {
        [browsingSegmentedControl setEnabled:YES forSegment:1];
    } else {
        [browsingSegmentedControl setEnabled:NO forSegment:1];        
    }
}

- (BOOL)canBack {
    return [HistoryManager sharedHistoryManager].backwardPages.count > 0;
}

- (IBAction)back:(id)sender {
    [self openWikiPage:[[HistoryManager sharedHistoryManager] back:[self.currentPage copy]]];
}

- (BOOL)canForward {
    return [HistoryManager sharedHistoryManager].forwardPages.count > 0;    
}

- (IBAction)forward:(id)sender {
    [self openWikiPage:[[HistoryManager sharedHistoryManager] forward:[self.currentPage copy]]];
}

- (IBAction)browsing:(id)sender {
    if ([browsingSegmentedControl selectedSegment] == 0) {
        [self back:self];
    } else if ([browsingSegmentedControl selectedSegment] == 1) { 
        [self forward:self];
    } else if ([browsingSegmentedControl selectedSegment] == 2) {
        [self addUntitledPage:self];
    } else if ([browsingSegmentedControl selectedSegment] == 3) {

    }
    [self updateBrowsingSegmentedControl];
}

- (IBAction)importFile:(id)sender {
    NSOpenPanel* openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:YES];
    if ([openPanel runModal] == NSFileHandlingPanelOKButton) {
        NSArray *URLs = [openPanel URLs];
        NSString *page;
        for (NSURL *fileURL in URLs) {
            page = [[WikiStorage sharedWikiStorage] importFileToPage:[fileURL path]];            
        }
        [self reloadSourceList];
        [self openWikiPage:page updateHistory:YES];
    }
}

#pragma mark - 
#pragma mark NSTextView delegate
- (BOOL)textView:(NSTextView *)aTextView clickedOnLink:(id)link atIndex:(NSUInteger)charIndex {
    [self openWikiPageByURL:link updateHistory:YES];
    return YES;
}

- (void)textDidChange:(NSNotification *)notification {
    [self updatePreview];
    [[WikiStorage sharedWikiStorage] writeWikiPage:currentPage content:[editorView string]];
    [self updateLastModified];
}


#pragma mark - 
#pragma mark Text Storage delegate
- (void)textStorageDidProcessEditing:(NSNotification*)notification {
    NSTextStorage *storage = [editorView textStorage];
    NSString *string = [storage string];
    NSRange editedRange = [storage editedRange];
    NSRange lineRange = [string lineRangeForRange:editedRange];
    
    NSString *line = [string substringWithRange:lineRange];
    
    [storage removeAttribute:NSLinkAttributeName range:lineRange];
    [storage removeAttribute:NSForegroundColorAttributeName range:lineRange];
    
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\\[\\[(\\w+)\\]\\]" options:NSRegularExpressionCaseInsensitive error:nil];
    
    NSArray *matches = [regex matchesInString:line
                                      options:0
                                        range:NSMakeRange(0, [line length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange linkRange = [match rangeAtIndex:0];
        NSString *page = [line substringWithRange:[match rangeAtIndex:1]];
        linkRange = NSMakeRange(lineRange.location + linkRange.location, linkRange.length);
        page = [page stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        [storage addAttribute:NSLinkAttributeName value:[NSURL URLWithString:[NSString stringWithFormat:@"wiki://%@.txt", page]] range:linkRange];
    }
    
    //*Italic*
    regex = [NSRegularExpression regularExpressionWithPattern:@"(\\*|\\_)(?=\\S)(.+?)(?<=\\S)(\\*|\\_)" options:NSRegularExpressionCaseInsensitive error:nil];
    matches = [regex matchesInString:line
                             options:0
                               range:NSMakeRange(0, [line length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:2];
        matchRange = NSMakeRange(lineRange.location + matchRange.location, matchRange.length);
        NSFont *italicFont = [[NSFontManager sharedFontManager] convertFont:editorView.font toHaveTrait:NSFontItalicTrait];
        [storage addAttribute:NSFontAttributeName value:italicFont range:matchRange];
        [storage fixFontAttributeInRange:lineRange];
        [storage addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(matchRange.location - 1, 1)];
        [storage addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(matchRange.location + matchRange.length, 1)];        
    }
        
    //**Bold**
    regex = [NSRegularExpression regularExpressionWithPattern:@"(\\*\\*|\\_\\_)(?=\\S)(.+?)(?<=\\S)(\\*\\*|\\_\\_)" options:NSRegularExpressionCaseInsensitive error:nil];
    matches = [regex matchesInString:line
                             options:0
                               range:NSMakeRange(0, [line length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:2];
        matchRange = NSMakeRange(lineRange.location + matchRange.location, matchRange.length);
        NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:editorView.font toHaveTrait:NSFontBoldTrait];
        [storage addAttribute:NSFontAttributeName value:boldFont range:matchRange];
        [storage fixFontAttributeInRange:lineRange];
        [storage addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(matchRange.location - 2, 2)];
        [storage addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:NSMakeRange(matchRange.location + matchRange.length, 2)];        
    }
    
    //List
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s*(\\*|[0-9]+\\.)\\s" options:NSRegularExpressionCaseInsensitive error:nil];
    matches = [regex matchesInString:line
                             options:0
                               range:NSMakeRange(0, [line length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:0];
        matchRange = NSMakeRange(lineRange.location + matchRange.location, matchRange.length);
        [storage addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:matchRange];
    }
    
    //Blockquotes
    regex = [NSRegularExpression regularExpressionWithPattern:@"\\s*(>+[\\s*>*]+)" options:NSRegularExpressionCaseInsensitive error:nil];
    matches = [regex matchesInString:line
                             options:0
                               range:NSMakeRange(0, [line length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:0];
        matchRange = NSMakeRange(lineRange.location + matchRange.location, matchRange.length);
        [storage addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:matchRange];
    }
    
    //Heading
    regex = [NSRegularExpression regularExpressionWithPattern:@"(\\#{1,6})[ \\t]*(.+?)[ \\t]*\\#*\\n+" options:NSRegularExpressionCaseInsensitive error:nil];
    matches = [regex matchesInString:line
                             options:0
                               range:NSMakeRange(0, [line length])];
    for (NSTextCheckingResult *match in matches) {
        NSRange matchRange = [match rangeAtIndex:1];
        matchRange = NSMakeRange(lineRange.location + matchRange.location, matchRange.length);
        [storage addAttribute:NSForegroundColorAttributeName value:[NSColor grayColor] range:matchRange];
        
        matchRange = [match rangeAtIndex:2];
        matchRange = NSMakeRange(lineRange.location + matchRange.location, matchRange.length);
        NSFont *boldFont = [[NSFontManager sharedFontManager] convertFont:editorView.font toHaveTrait:NSFontBoldTrait];
        [storage addAttribute:NSFontAttributeName value:boldFont range:matchRange];
        [storage fixFontAttributeInRange:lineRange];

    }

}


#pragma mark -
#pragma mark WebView
- (void)webView:(WebView *)sender didFinishLoadForFrame:(WebFrame *)frame {
    [self performSelector:@selector(updatePreview) withObject:nil afterDelay:0.35];
}

- (void)webView:(WebView *)webView decidePolicyForNavigationAction:(NSDictionary *)actionInformation request:(NSURLRequest *)request frame:(WebFrame *)frame decisionListener:(id < WebPolicyDecisionListener >)listener {
    if ([[[request URL] scheme] isEqualToString: @"file"]) {
        [listener use];
    } else if ([[[request URL] scheme] isEqualToString:@"wiki"]) {
        if ([[actionInformation valueForKey:WebActionModifierFlagsKey] unsignedIntValue] == NSCommandKeyMask) {
            //Handle Command + Click
        }
        [self openWikiPageByURL:[request URL] updateHistory:YES];
        [listener ignore];        
    } else {
        [[NSWorkspace sharedWorkspace] openURL:[request URL]];
        [listener ignore];        
    }
}

#pragma mark -
#pragma mark Source List Data Source Methods
- (NSUInteger)sourceList:(PXSourceList*)sourceList numberOfChildrenOfItem:(id)item {
	//Works the same way as the NSOutlineView data source: `nil` means a parent item
	if (item == nil) {
		return [sourceListItems count];
	} else {
		return [[item children] count];
	}
}


- (id)sourceList:(PXSourceList*)aSourceList child:(NSUInteger)index ofItem:(id)item {
	//Works the same way as the NSOutlineView data source: `nil` means a parent item
	if(item == nil) {
		return [sourceListItems objectAtIndex:index];
	} else {
		return [[item children] objectAtIndex:index];
	}
}

- (id)sourceList:(PXSourceList*)aSourceList objectValueForItem:(id)item {
	return [item title];
}


- (void)sourceList:(PXSourceList*)aSourceList setObjectValue:(id)object forItem:(id)item {
    if ([object length] > 0) {
        [[WikiStorage sharedWikiStorage] renamePage:[item identifier] toTitle:object];
        [self reloadSourceList];
        [self selectPageByTitle:object];
    }
}

- (BOOL)sourceList:(PXSourceList*)aSourceList isItemExpandable:(id)item {
	return [item hasChildren];
}


- (BOOL)sourceList:(PXSourceList*)aSourceList itemHasBadge:(id)item {
	return [item hasBadge];
}

- (NSInteger)sourceList:(PXSourceList*)aSourceList badgeValueForItem:(id)item {
	return [item badgeValue];
}


- (BOOL)sourceList:(PXSourceList*)aSourceList itemHasIcon:(id)item {
	return [item hasIcon];
}


- (NSImage*)sourceList:(PXSourceList*)aSourceList iconForItem:(id)item {
	return [item icon];
}

#pragma mark -
#pragma mark Source List Delegate Methods
- (BOOL)sourceList:(PXSourceList*)aSourceList isGroupAlwaysExpanded:(id)group {
    return YES;
}

- (void)sourceListSelectionDidChange:(NSNotification *)notification {               
	NSIndexSet *selectedIndexes = [sourceList selectedRowIndexes];
	if ([selectedIndexes count] == 1) {
        NSString *identifier = [[sourceList itemAtRow:[selectedIndexes firstIndex]] identifier];
        if (![identifier isEqualToString:self.currentPage]) {
            identifier = [identifier stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            [self openWikiPage:identifier updateHistory:YES];
        }
    }
}

- (void)sourceListDeleteKeyPressedOnRows:(NSNotification *)notification {
    NSIndexSet *selectedIndexes = [sourceList selectedRowIndexes];
    if ([selectedIndexes count] == 1) {
        NSUInteger index = [selectedIndexes firstIndex];
        NSString *identifier = [[sourceList itemAtRow:index] identifier];
        [[WikiStorage sharedWikiStorage] deletePage:identifier];
        [self reloadSourceList];
        [sourceList selectRowIndexes:[NSIndexSet indexSetWithIndex:index-1] byExtendingSelection:NO];
    }
}

- (BOOL)sourceList:(PXSourceList*)aSourceList shouldEditItem:(id)item {
    return YES;
}

- (NSDragOperation)sourceList:(PXSourceList*)sourceList validateDrop:(id < NSDraggingInfo >)info proposedItem:(id)item proposedChildIndex:(NSInteger)index {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType] ) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        if ([[fileURL lastPathComponent] hasSuffix:@".txt"]) {
            return NSDragOperationCopy;
        }
    }
    return NSDragOperationNone;
}

- (BOOL)sourceList:(PXSourceList*)aSourceList acceptDrop:(id < NSDraggingInfo >)info item:(id)item childIndex:(NSInteger)index {
    NSPasteboard *pboard = [info draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType] ) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        NSString *page = [[WikiStorage sharedWikiStorage] importFileToPage:[fileURL path]];
        [self reloadSourceList];
        [self openWikiPage:page updateHistory:YES];
        return YES;
    }
    return NO;
}

#pragma mark- 
#pragma mark SCEventListenerProtocol
- (void)pathWatcher:(SCEvents *)pathWatcher eventOccurred:(SCEvent *)event {
    NSUInteger count = [[[sourceListItems objectAtIndex:0] children] count];
    [self reloadSourceList];
    if (count != [[[sourceListItems objectAtIndex:0] children] count]) {
        [self sourceListSelectionDidChange:nil];
    }
}



@end
