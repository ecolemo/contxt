//
//  HistoryManager.h
//  Contxt
//
//  Created by Young Hoo Kim on 12/11/11.
//  Copyright (c) 2011 Kim Young Hoo. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface HistoryManager : NSObject {
    
    NSMutableArray *backwardPages;
    NSMutableArray *forwardPages;
}

+ (HistoryManager *)sharedHistoryManager;

- (NSString *)back:(NSString *)currentPage;
- (NSString *)forward:(NSString *)currentPage;

@property (nonatomic, readonly) NSMutableArray *backwardPages;
@property (nonatomic, readonly) NSMutableArray *forwardPages;


@end
