//
//  ImageBrowserController.m
//  Contxt
//
//  Created by Young Hoo Kim on 12/31/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import "ImageBrowserController.h"
#import "WikiStorage.h"

@interface MyImageObject : NSObject{
    NSString *path; 
}
@end

@implementation MyImageObject

- (void) dealloc {
    [path release];
    [super dealloc];
}

- (void) setPath:(NSString *) aPath {
    if(path != aPath){
        [path release];
        path = [aPath retain];
    }
}

#pragma mark -
#pragma mark item data source protocol
- (NSString *)imageRepresentationType {
	return IKImageBrowserPathRepresentationType;
}

- (id)imageRepresentation {
	return path;
}

- (NSString *)imageUID {
    return path;
}

- (id)imageTitle {
	return [path lastPathComponent];
}

@end

@implementation ImageBrowserController 

- (void)dealloc {
    [images release];
    [filteredOutImages release];
    [super dealloc];
}

static NSArray *openFiles() { 
    NSOpenPanel *panel;
    
    panel = [NSOpenPanel openPanel];        
    [panel setFloatingPanel:YES];
    [panel setCanChooseDirectories:YES];
    [panel setCanChooseFiles:YES];
	int i = [panel runModalForTypes:nil];
	if(i == NSOKButton){
		return [panel filenames];
    }
    
    return nil;
}    

- (void)addImageWithPath:(NSString *)path {   
    MyImageObject *item;
    
    NSString *filename = [path lastPathComponent];
    
	/* skip '.*' */ 
	if([filename length] > 0){
        if ([filename hasSuffix:@".txt"]) {
            return;
        }
        
		char *ch = (char*) [filename UTF8String];
		
		if(ch)
			if(ch[0] == '.')
				return;
	}
	
	item = [[MyImageObject alloc] init];	
	[item setPath:path];
	[images addObject:item];
	[item release];
}

- (void)addImagesFromDirectory:(NSString *)path {
    NSUInteger i, n;
    BOOL dir;
	
    [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&dir];
    
    if(dir){
        NSArray *content = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path error:nil];
        
        n = [content count];
        
        for(i=0; i<n; i++)
			[self addImageWithPath:[path stringByAppendingPathComponent:[content objectAtIndex:i]]];
    }
    else
        [self addImageWithPath:path];
	
	[imageBrowser reloadData];
}

#pragma mark -
#pragma mark setupBrowsing
- (void) setupBrowsing {
	//allocate our datasource array: will contain instances of MyImageObject
    images = [[NSMutableArray alloc] init];
    
	[self addImagesFromDirectory:[[WikiStorage sharedWikiStorage].storageURL path]];
}



- (void)awakeFromNib {
    [self setupBrowsing];
}

#pragma mark -
#pragma mark IKImageBrowserDataSource
- (NSUInteger) numberOfItemsInImageBrowser:(IKImageBrowserView *) view {
    return [images count];
}

- (id) imageBrowser:(IKImageBrowserView *) aBrowser itemAtIndex:(NSUInteger)index {
    return [images objectAtIndex:index];
}


@end
