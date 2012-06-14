//
//  WikiStorage.m
//  Contxt
//
//  Created by Young Hoo Kim on 12/10/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import "WikiStorage.h"
#import "SynthesizeSingleton.h"
#import "NSFileManager+DirectoryLocations.h"
#import "NSString+Page.h"

@implementation WikiStorage
SYNTHESIZE_SINGLETON_FOR_CLASS(WikiStorage)
@synthesize storageURL;

- (void)dealloc {
    [storageURL release];
    [super dealloc];
}

- (BOOL)empty {
    return [self.files count] == 0 || ([self.files count] == 1 && [[self.files objectAtIndex:0] isEqualToString:@".DS_Store"]);
}

- (void)makePageInBundle:(NSString *)title {
    NSString *page = [[NSBundle mainBundle] pathForResource:title ofType:@"txt"];
    NSString *content = [NSString stringWithContentsOfFile:page encoding:encoding error:nil];
    [content writeToURL:[storageURL URLByAppendingPathComponent:[NSString stringWithFormat:@"%@.txt", title]] atomically:YES encoding:encoding error:nil];  
}

- (id)init {
    self = [super init];
    if (self != nil) {
        encoding = NSUTF8StringEncoding;
        NSString *applicationSupportDirectory = [[NSFileManager defaultManager] applicationSupportDirectory];
        NSString *wiki = [applicationSupportDirectory stringByAppendingPathComponent:@"/wiki"];
        if (![[NSFileManager defaultManager] fileExistsAtPath:wiki isDirectory:nil]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:wiki withIntermediateDirectories:NO attributes:nil error:nil];
        }
        storageURL = [[NSURL fileURLWithPath:wiki isDirectory:YES] retain];
        
        if ([self empty]) {
            [self makePageInBundle:@"Home"];
            [self makePageInBundle:@"HowContxtWorks"];
        }
        
    }
    return self;
}

- (NSArray *)files {
    return [[NSFileManager defaultManager] contentsOfDirectoryAtPath:[storageURL path] error:nil];
}

- (NSURL *)pageURL:(NSString *)page {
    page = [page stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [storageURL URLByAppendingPathComponent:page];
}

- (NSString *)readWikiPage:(NSString *)page {
    return [NSString stringWithContentsOfURL:[self pageURL:page] encoding:encoding error:nil];
}

- (void)writeWikiPage:(NSString *)page content:(NSString *)content {
    [content writeToURL:[self pageURL:page] atomically:YES encoding:encoding error:nil];
}

- (BOOL)isExistingPage:(NSString *)page {
    return [[NSFileManager defaultManager] fileExistsAtPath:[[self pageURL:page] path]];
}

- (NSString *)addUntitledPageWithContent:(NSString *)content {
    NSUInteger count = 0;
    NSString *page = @"Untitled.txt";
    do {
        if (count > 0) {
            page = [NSString stringWithFormat:@"Untitled%u.txt", count];
        }
        count += 1;
    } while ([self isExistingPage:page]);
    [self writeWikiPage:page content:[NSString stringWithFormat:content, [page pageTitle]]];
    return page;
}

- (void)deletePage:(NSString *)page {
    [[NSFileManager defaultManager] removeItemAtURL:[self pageURL:page] error:nil];
}

- (void)renamePage:(NSString *)page toTitle:(NSString *)title {
    [[NSFileManager defaultManager] moveItemAtURL:[self pageURL:page] toURL:[self pageURL:[NSString stringWithFormat:@"%@.txt", title]] error:nil];
}

- (void)saveImageByURL:(NSURL *)imageURL {
    [[NSFileManager defaultManager] copyItemAtPath:[imageURL path] toPath:[NSString stringWithFormat:@"%@/%@", [storageURL path], [imageURL lastPathComponent]] error:nil];
}

- (NSDate *)lastModifiedDateForFile:(NSString *)fileName {
    NSDate *localModifiedDate;
    NSDictionary *fileInfo = [[NSFileManager defaultManager] attributesOfItemAtPath:fileName error:nil];
    localModifiedDate = [fileInfo objectForKey:NSFileModificationDate];
    return localModifiedDate;
}

- (NSString *)lastModifiedByPage:(NSString *)page {
    NSDate *date = [self lastModifiedDateForFile:[[self pageURL:page] path]];
    NSDateFormatter *df = [[[NSDateFormatter alloc] init] autorelease];
    [df setDateFormat:@"dd MMMM yyyy, HH:mm"];
    return [df stringFromDate:date];
}

- (NSString *)importFileToPage:(NSString *)file {
    NSUInteger count = 0;
    NSString *filename = [file lastPathComponent];
    NSString *page = [filename copy];
    do {
        if (count > 0) {
            page = [NSString stringWithFormat:@"%@%u.txt", [filename substringToIndex:filename.length - 4], count];
        }
        count += 1;
    } while ([self isExistingPage:page]);
    [[NSFileManager defaultManager] copyItemAtPath:file toPath:[NSString stringWithFormat:@"%@/%@", [storageURL path], page] error:nil];
    return page;
}

@end
