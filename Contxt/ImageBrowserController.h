//
//  ImageBrowserController.h
//  Contxt
//
//  Created by Young Hoo Kim on 12/31/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import <Quartz/Quartz.h>
#import <Cocoa/Cocoa.h>

@interface ImageBrowserController : NSWindowController {
    IBOutlet IKImageBrowserView *imageBrowser;    
    
    NSMutableArray *images;
	
    NSMutableArray *filteredOutImages;
	NSMutableIndexSet *filteredOutIndexes;
}

@end
