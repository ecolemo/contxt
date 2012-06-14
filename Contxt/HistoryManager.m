//
//  HistoryManager.m
//  Contxt
//
//  Created by Young Hoo Kim on 12/11/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import "HistoryManager.h"
#import "WikiStorage.h"
#import "SynthesizeSingleton.h"

@implementation HistoryManager
SYNTHESIZE_SINGLETON_FOR_CLASS(HistoryManager)
@synthesize backwardPages, forwardPages;


- (void)dealloc {
    [backwardPages release];
    [forwardPages release];
    [super dealloc];
}

- (id)init {
    self = [super init];
    if (self != nil) {
        backwardPages = [[NSMutableArray alloc] init];
        forwardPages = [[NSMutableArray alloc] init];
    }
    return self;
}

- (NSString *)back:(NSString *)currentPage {
    NSUInteger index = backwardPages.count - 1;
    NSString *page = [[backwardPages objectAtIndex:index] copy];
    [forwardPages addObject:currentPage];
    [backwardPages removeObjectAtIndex:index];
    if ([[WikiStorage sharedWikiStorage] isExistingPage:page]) {
        return page;
    }
    return nil;
}

- (NSString *)forward:(NSString *)currentPage {
    NSUInteger index = forwardPages.count - 1;
    NSString *page = [[forwardPages objectAtIndex:index] copy];
    [backwardPages addObject:currentPage];
    [forwardPages removeObjectAtIndex:index];
    if ([[WikiStorage sharedWikiStorage] isExistingPage:page]) {
        return page;
    }
    return nil;
}


@end
