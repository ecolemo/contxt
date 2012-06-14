//
//  CTSearchField.m
//  Contxt
//
//  Created by Young Hoo Kim on 12/18/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import "CTSearchField.h"
#import "GoToPageController.h"

@implementation CTSearchField

- (void)textDidChange:(NSNotification *)notification {
    [goToPageController updateSearch:self.stringValue];
}

@end
