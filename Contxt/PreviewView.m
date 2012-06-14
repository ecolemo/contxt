//
//  PreviewView.m
//  Contxt
//
//  Created by Young Hoo Kim on 12/23/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import "PreviewView.h"
#import "WikiStorage.h"
#import "AppDelegate.h"
#import "NSString+Page.h"

@implementation PreviewView

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType] ) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        NSString *lastPathComponent = [fileURL lastPathComponent];
        AppDelegate *appDelegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
        if (lastPathComponent.length > 4 && [[lastPathComponent substringFromIndex:lastPathComponent.length - 3] isEqualToString:@"png"]) {
            [[WikiStorage sharedWikiStorage] saveImageByURL:fileURL];
            return YES;
        } else if (lastPathComponent.length > 4 && [[lastPathComponent substringFromIndex:lastPathComponent.length - 3] isEqualToString:@"txt"]) {
            NSString *page = [[WikiStorage sharedWikiStorage] importFileToPage:[fileURL path]];
            [appDelegate reloadSourceList];
            [appDelegate markdownMode:self];
            [appDelegate.editorView insertText:[NSString stringWithFormat:@"[[%@]]", [page pageTitle]]];
            return YES;
        }
    }
    return NO;
}

@end
