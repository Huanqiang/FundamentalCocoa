//
//  DFAObject.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/5/24.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "DFAObject.h"

@implementation DFAObject
@synthesize collectionName;
@synthesize stateList;
@synthesize stateListByVarch;

- (id)init {
    self = [super init];
    return self;
}

- (id)init:(NSInteger)name stateList:(NSArray *)list varchList:(NSArray *)varchList {
    self = [self init];
    
    self.collectionName = name;
    self.stateList = list;
    stateListByVarch = [NSMutableDictionary dictionary];
    self.isEndState = NO;
    for (NSString *varch in varchList) {
        [stateListByVarch setObject:@(-1) forKey:varch];
    }
    
    return self;
}


@end
