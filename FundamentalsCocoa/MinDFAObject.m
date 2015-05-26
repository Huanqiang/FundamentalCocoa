//
//  MinDFAObject.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/5/25.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "MinDFAObject.h"

@implementation MinDFAObject
@synthesize collectionName;
@synthesize isEndState;
@synthesize priStateList;

- (id)init {
    self = [super init];
    return self;
}

- (id)initWithName:(NSInteger)name {
    self = [self init];
    self.collectionName = name;
    self.isEndState = NO;
    self.priStateList = [NSMutableArray array];
    return self;
}

- (void)addObjectToPriStateList:(NSInteger)state {
    [self.priStateList addObject:@(state)];
}

@end
