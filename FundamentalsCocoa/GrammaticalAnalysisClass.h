//
//  GrammaticalAnalysisClass.h
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/22.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface GrammaticalAnalysisClass : NSObject

@property (nonatomic, strong) NSMutableArray *analyzeResultList;
@property (nonatomic, strong) NSMutableArray *symbolAnalyzeResultList;
@property (nonatomic, strong) NSMutableArray *falseList;
@property (nonatomic, strong) NSMutableArray *quaternionList;

- (void)grammaticalAnalysis:(NSArray *)fileContext symbolInfoList:(NSArray *)SymbolInfoList;

@end
