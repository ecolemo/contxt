//
//  StylesController.h
//  MarkdownNote
//
//  Created by Kim Young Hoo on 10. 12. 8..
//  Copyright 2010 Kim Young Hoo. All rights reserved.
//
#import <Cocoa/Cocoa.h>

@interface StylesController : NSObject {

	NSMutableArray *_styles;
}

+ (NSString *)stylesFolderPath;
+ (StylesController *)sharedStylesController;

@property (nonatomic, retain) NSMutableArray *styles;
@property (nonatomic, retain) NSString *selectedStyle;


- (void)loadStyles;
- (NSURL *)selectedPreviewURL;

@end
