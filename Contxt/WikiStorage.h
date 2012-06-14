//
//  WikiStorage.h
//  Contxt
//
//  Created by Young Hoo Kim on 12/10/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import <Foundation/Foundation.h>
@interface WikiStorage : NSObject {
    
    NSStringEncoding encoding;
    NSURL *storageURL;
}

+ (WikiStorage *)sharedWikiStorage;

- (NSString *)readWikiPage:(NSString *)page;
- (void)writeWikiPage:(NSString *)page content:(NSString *)content;
- (BOOL)isExistingPage:(NSString *)page;
- (NSString *)addUntitledPageWithContent:(NSString *)content;
- (void)deletePage:(NSString *)page;
- (void)renamePage:(NSString *)page toTitle:(NSString *)title;

- (void)saveImageByURL:(NSURL *)imageURL;
- (NSString *)lastModifiedByPage:(NSString *)page;
- (NSString *)importFileToPage:(NSString *)file;

@property (nonatomic, readonly) NSURL *storageURL;
@property (nonatomic, readonly) NSArray *files;

@end
