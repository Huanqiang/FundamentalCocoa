//
//  MinDFAObject.h
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/5/25.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface MinDFAObject : NSObject

@property (nonatomic) NSInteger collectionName;
@property (nonatomic) BOOL isEndState;
@property (nonatomic, strong) NSMutableArray *priStateList;

- (id)initWithName:(NSInteger)name;
- (void)addObjectToPriStateList:(NSInteger)state;

@end
