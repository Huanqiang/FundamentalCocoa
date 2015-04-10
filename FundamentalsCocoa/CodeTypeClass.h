//
//  CodeTypeClass.h
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/8.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CodeTypeClass : NSObject

@property (nonatomic, strong) NSArray *keywordArray;        // 关键字
@property (nonatomic, strong) NSArray *operatorArray;       // 运算符
@property (nonatomic, strong) NSArray *boundaryRiverArray;  // 界符

- (NSInteger)isBelongsKeywordArray:(NSString *)keyWord ;
- (NSInteger)isBelongsOperatorArray:(NSString *)operatorString;
- (NSInteger)isBelongsBoundaryRiverArray:(NSString *)boundaryRiverString;

- (BOOL)isBelongsNumber:(char)number;
- (BOOL)isBelongsLetters:(char)letters;


- (BOOL)isNumericConstants:(NSString *)numberString;
- (NSInteger)isKeyWordOrVariate:(NSString *)wordString;
- (BOOL)isVariable:(NSString *)variableString;

@end
