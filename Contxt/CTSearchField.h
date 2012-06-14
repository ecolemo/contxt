//
//  CTSearchField.h
//  Contxt
//
//  Created by Young Hoo Kim on 12/18/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import <AppKit/AppKit.h>

@class GoToPageController;

@interface CTSearchField : NSSearchField {
    IBOutlet GoToPageController *goToPageController;
}

@end
