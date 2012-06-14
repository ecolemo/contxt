//
//  EditorView.m
//  MarkdownWiki
//
//  Created by Young Hoo Kim on 11/4/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import "EditorView.h"
#import "ContxtDefaultsKeys.h"
#import "WikiStorage.h"
#import "NSString+Page.h"
#import "AppDelegate.h"

@implementation EditorView

- (void)awakeFromNib {
    [self setRichText:NO];
    [self setFont:[NSFont fontWithName:@"Cochin" size:17]];
    [self setTextContainerInset:NSMakeSize(5, 10)];
    [self setTextColor:[self.backgroundColor blendedColorWithFraction:0.85 ofColor:[NSColor blackColor]]];        
}

- (void)didChangeText {
    [super didChangeText];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"kDidChangeText" object:self];
}

- (BOOL)performDragOperation:(id < NSDraggingInfo >)sender {
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ([[pboard types] containsObject:NSURLPboardType] ) {
        NSURL *fileURL = [NSURL URLFromPasteboard:pboard];
        NSString *lastPathComponent = [fileURL lastPathComponent];
        if (lastPathComponent.length > 4 && [[lastPathComponent substringFromIndex:lastPathComponent.length - 3] isEqualToString:@"png"]) {
            [[WikiStorage sharedWikiStorage] saveImageByURL:fileURL];
            [self insertText:[NSString stringWithFormat:@"![alt text](%@)", [fileURL lastPathComponent]]];
            return YES;
        } else if (lastPathComponent.length > 4 && [[lastPathComponent substringFromIndex:lastPathComponent.length - 3] isEqualToString:@"txt"]) {
            NSString *page = [[WikiStorage sharedWikiStorage] importFileToPage:[fileURL path]];
            AppDelegate *appDelegate = (AppDelegate *)[NSApplication sharedApplication].delegate;
            [appDelegate reloadSourceList];
            [self insertText:[NSString stringWithFormat:@"[[%@]]", [page pageTitle]]];
            return YES;
        }
    }
    return [super performDragOperation:sender];
}

@end
