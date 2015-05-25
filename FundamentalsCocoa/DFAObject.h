//
//  DFAObject.h
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/5/24.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DFAObject : NSObject

@property (nonatomic) NSInteger collectionName;
@property (nonatomic, strong) NSArray *stateList;
@property (nonatomic, strong) NSMutableDictionary *stateListByVarch;
@property (nonatomic) BOOL isEndState;

- (id)init:(NSInteger)name stateList:(NSArray *)list varchList:(NSArray *)varchList;

@end
