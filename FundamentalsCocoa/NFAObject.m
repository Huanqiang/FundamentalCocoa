//
//  NFAObject.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/5/23.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "NFAObject.h"

@implementation NFAObject
@synthesize outWay;
@synthesize inWay;
@synthesize varch;

- (id)init {
    self  = [super init];
    return self;
}

- (id)init:(NSInteger)iWay outWay:(NSInteger)oWay varch:(NSString *)v {
    self = [self init];
    self.outWay = oWay;
    self.inWay = iWay;
    self.varch = v;
    return self;
}

@end
