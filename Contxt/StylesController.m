//
//  StylesController.m
//  MarkdownNote
//
//  Created by Kim Young Hoo on 10. 12. 8..
//  Copyright 2010 Kim Young Hoo. All rights reserved.
//

#import "SynthesizeSingleton.h"
#import "StylesController.h"
#import "ContxtDefaultsKeys.h"

@implementation StylesController

SYNTHESIZE_SINGLETON_FOR_CLASS(StylesController);
@synthesize styles = _styles;

+ (NSString *)stylesFolderPath {
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSURL *applicationSupport = [[NSFileManager defaultManager] URLForDirectory:NSApplicationSupportDirectory inDomain:NSUserDomainMask appropriateForURL:NULL create:YES error:NULL];
    NSString *folderPath = [[[applicationSupport path] stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]] stringByAppendingPathComponent:@"Styles"];
    
    BOOL isDirectory;
    
    if ([fileManager fileExistsAtPath:folderPath isDirectory:&isDirectory] && isDirectory) {
        return folderPath;
    }
    
    [fileManager createDirectoryAtPath:[folderPath stringByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:NULL];
    [fileManager copyItemAtPath:[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"EmbeddedStyles"]
                         toPath:folderPath
                          error:NULL];
    
    return folderPath;
}

- (id)init {
	self = [super init];
	if (self != nil) {
		_styles = [[NSMutableArray alloc] init];
		[self loadStyles];
	}
	return self;
}

- (void)setSelectedStyle:(NSString *)newSelectedStyle {
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	[prefs setValue:newSelectedStyle forKey:CTPreviewStyleDefaultsKey];
	[prefs synchronize];
}

- (NSString *)selectedStyle {
	NSUserDefaults *prefs = [NSUserDefaults standardUserDefaults];
	return [prefs valueForKey:CTPreviewStyleDefaultsKey];
}


- (void)loadStyles {
	NSString *stylesPath = [StylesController stylesFolderPath];	
	NSDirectoryEnumerator *stylesEnumerator = [[NSFileManager defaultManager] enumeratorAtPath:stylesPath];
	
	NSString *styleName;
	while (styleName = [stylesEnumerator nextObject]) {
		if ([stylesEnumerator respondsToSelector:@selector(skipDescendents)]) {
			[stylesEnumerator performSelector:@selector(skipDescendents)];
		}
        NSString *stylePath = [stylesPath stringByAppendingPathComponent:styleName];
		//NSString *stylePath = [[NSBundle mainBundle] pathForResource:styleName ofType:nil inDirectory:@"styles"];
		BOOL isDirectory;
		
		if ([[NSFileManager defaultManager] fileExistsAtPath:stylePath isDirectory:&isDirectory]) {
			if (isDirectory) {
				[self.styles addObject:styleName];
			}
		}
	}
}

- (NSURL *)selectedPreviewURL {
	NSString *stylePath = [[StylesController stylesFolderPath] stringByAppendingPathComponent:self.selectedStyle];
    NSString *previewPath = [stylePath stringByAppendingPathComponent:@"preview.html"];	
	if (![[NSFileManager defaultManager] fileExistsAtPath:previewPath]) {
		self.selectedStyle = @"Default";
		return [self selectedPreviewURL];
	} else {
		return  [NSURL fileURLWithPath:previewPath];
	}
}

- (void)dealloc {
	[_styles release], _styles = nil;
	[super dealloc];
}

@end
