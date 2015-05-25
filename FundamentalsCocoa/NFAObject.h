//
//  NFAObject.h
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/5/23.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NFAObject : NSObject

@property(nonatomic) NSInteger outWay;
@property(nonatomic) NSInteger inWay;
@property(nonatomic, strong) NSString *varch;

- (id)init:(NSInteger)iWay outWay:(NSInteger)oWay varch:(NSString *)v;

@end
