//
//  CodeTypeOperating.h
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/8.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CodeTypeOperating : NSObject

@property (nonatomic, strong) NSMutableArray *symbolArr;
@property (nonatomic, strong) NSMutableArray *tokenArr;
@property (nonatomic, strong) NSMutableArray *falseWordArr;

- (void)dealWithCode:(NSString *)fileContext;

@end
