//
//  AppDelegate.h
//  Contxt
//
//  Created by Young Hoo Kim on 12/7/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "PXSourceList.h"
#import "SCEventListenerProtocol.h"

//Page = filename.txt (include .txt)
//Title = filename

@class CRClickableTextField;

@interface AppDelegate : NSObject <NSApplicationDelegate, NSTextViewDelegate, PXSourceListDataSource, PXSourceListDelegate, SCEventListenerProtocol> {
    IBOutlet NSTextView *editorView;
    IBOutlet WebView *webView;
    IBOutlet NSSegmentedControl *markdownSegmentedControl;
    IBOutlet NSSegmentedControl *browsingSegmentedControl;
    IBOutlet NSTabView *markdownTabView;
    IBOutlet PXSourceList *sourceList;
    IBOutlet CRClickableTextField *lastModifiedTextField;
    IBOutlet NSMenuItem *previewStylesMenuItem;


    NSMutableArray *sourceListItems;
    NSMutableDictionary *pageToIndexDict;
    NSString *currentPage;
    
    SCEvents *storageEvents;
}

@property (nonatomic, readonly) NSTextView *editorView;
@property (nonatomic, retain) NSString *currentPage;
@property (assign) IBOutlet NSWindow *window;
@property (readonly) BOOL canBack;
@property (readonly) BOOL canForward;

- (IBAction)openStylesFolder:(id)sender;
- (IBAction)selectPreviewStyle:(id)sender;
- (IBAction)browsing:(id)sender;
- (IBAction)back:(id)sender;
- (IBAction)forward:(id)sender;
- (IBAction)addUntitledPage:(id)sender;
- (IBAction)markdownMode:(id)sender;
- (IBAction)previewMode:(id)sender;
- (IBAction)importFile:(id)sender;

- (void)openWikiPage:(NSString*)page;
- (void)openWikiPage:(NSString*)page updateHistory:(BOOL)updateHistory;
- (void)openWikiPageByURL:(NSURL *)pageURL updateHistory:(BOOL)updateHistory;
- (void)updateBrowsingSegmentedControl;
- (void)updateLastModified;

- (void)back;
- (void)forward;

- (void)reloadSourceList;

@end
