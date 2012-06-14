//
//  NSString+Page.m
//  Contxt
//
//  Created by Young Hoo Kim on 12/10/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import "NSString+Page.h"

@implementation NSString (Page)

- (NSString*)pageTitle {
    if ([self length] > 4) {
        return [self substringToIndex:self.length - 4];
    }
    return nil;
}

@end
