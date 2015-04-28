//
//  LLFirstForecast.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/21.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "LLFirstForecast.h"
#import "FileOperateClass.h"

@interface LLFirstForecast () {
    NSDictionary *firstCollectionDictionary;
    NSDictionary *followCollectionDictionary;
    
    // 预测分析表的 终结符集合
    NSDictionary *forecastAnalyzeTableDictionary;
    NSMutableArray *terminalSymbols;
    BOOL forecastAnalyzeHasData;
}

@property (unsafe_unretained) IBOutlet NSTextView *grammarDataTextView;
@property (unsafe_unretained) IBOutlet NSTextView *firstCollectionResultTextView;
@property (unsafe_unretained) IBOutlet NSTextView *followCollectionResultTextView;
@property (weak) IBOutlet NSTableView *forecastAnalyzeTableView;

@end

@implementation LLFirstForecast

- (void)windowDidLoad {
    [super windowDidLoad];
    
    firstCollectionDictionary = [NSDictionary dictionary];
    followCollectionDictionary = [NSDictionary dictionary];
    forecastAnalyzeTableDictionary = [NSDictionary dictionary];
    terminalSymbols = [NSMutableArray array];
    forecastAnalyzeHasData = NO;
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma 打开文件、确认文件、保存文件
- (IBAction)openFile:(id)sender {
    [[[FileOperateClass alloc] init] openFileWithSelectFolder:self.window gainData:^(NSString *result) {
        self.grammarDataTextView.string = result;
    }];
}

- (IBAction)saveFile:(id)sender {
    
}

// 确认文法的格式：去除空格 和 箭头（->）
- (IBAction)sureFileFormat:(id)sender {
    NSArray *fileContextArr = [self separateFileContextWithRow:self.grammarDataTextView.string];
    NSMutableString *newFileContext = [NSMutableString string];
    NSInteger arrowheadCount = 0;
    NSMutableString *arrowheadError = [NSMutableString string];
    
    // 错误判断
    for (int i = 0; i < [fileContextArr count]; i++) {
        NSString *rowContext = fileContextArr[i];
        if (![rowContext isEqualToString:@""]) {
            // 出去空格
            NSString *newRowContext = [self removeBlank:rowContext];
            [newFileContext appendString:newRowContext];
            
            // 判断| 两边是否都存在数据
            if (![self foundSignalWithOr:newRowContext]) {
                [arrowheadError appendFormat:@"第%d行：'|' 符号旁边可能不存在数据\n",i];
            }
            
            // 判断箭头个数
            if ([self foundArrowhead:newRowContext] != 1) {
                arrowheadCount ++;
                if ([self foundArrowhead:newRowContext] == 2) {
                    [arrowheadError appendFormat:@"第%d行：本行无箭头\n",i];
                }else {
                    [arrowheadError appendFormat:@"第%d行：本行有%d箭头\n",i, [self foundArrowhead:newRowContext] - 1];
                }
            }
        }
    }
    
    // 将结果复制给 文法框
    self.grammarDataTextView.string = newFileContext;
    
    // 错误处理
    if (arrowheadCount == 0) {
        [self createAlertView:@"文法正确!" infomativeText:@""];
    }else {
        [self createAlertView:@"文法错误!" infomativeText:arrowheadError];
    }
    
}

// 按行截取文件内容
- (NSArray *)separateFileContextWithRow:(NSString *)separateString {
    NSArray *fileInfoArr = [separateString componentsSeparatedByString:@"\r\n"];
    return fileInfoArr;
}

// 查找箭头（->）：一个箭头说明文法正确，没有或者两个及其以上剪头说明文法错误
- (int)foundArrowhead:(NSString *)rowContext {
    NSArray *arrowHeadArr = [rowContext componentsSeparatedByString:@"->"];
    if ([arrowHeadArr count] == 1) {
        return 2;
    }else if ([arrowHeadArr count] > 2) {
        return 3;
    }else {
        return 1;
    }
}

// 去除 空格
- (NSString *)removeBlank:(NSString *)rowContext {
    NSArray *blankOtherArr = [rowContext componentsSeparatedByString:@" "];
    NSMutableString *newRowContext = [NSMutableString string];
    
    for (NSString *otherString in blankOtherArr) {
        [newRowContext appendString:otherString];
    }
    // 增加 换行符
    [newRowContext appendString:@"\r\n"];
    
    return newRowContext;
}

// 查找 | 两边是否都存在数据：存在返回YES 不存在返回NO；
- (BOOL)foundSignalWithOr:(NSString *)rowContext {
    NSArray *arrowHeadArr = [rowContext componentsSeparatedByString:@"->"];
    NSArray *signalWithOrArr = [arrowHeadArr[1] componentsSeparatedByString:@"|"];
    
    for (NSString *signalWithOrString in signalWithOrArr) {
        if ([signalWithOrString isEqualToString:@""]) {
            return NO;
        }
    }
    
    return YES;
}


#pragma mark - 求 first 集
- (IBAction)foundFirstCollection:(id)sender {
    // 先做初步 判断 p->t | B
    NSArray *fileContextArr = [self separateFileContextWithRow:self.grammarDataTextView.string];
    NSMutableDictionary *firstCollection = [NSMutableDictionary dictionary];
    
    // 获取 起始符 和 起对应的终结符（箭头的右侧）
    for (NSString *rowContext in fileContextArr) {
        if (![rowContext isEqualToString:@""]) {
            NSDictionary *dic = [self separateFirstCollection:rowContext];
            [firstCollection setObject:[dic allValues][0] forKey:[dic allKeys][0]];
        }
    }

    // 循环处理： 只要有一个 起始符对应的终结符的集合中 含有起始符， 就要进行一次循环， 直到完成所有的循环。
    while (![self isFinishWithFirstCollection:firstCollection]) {
        NSArray *keys = [firstCollection allKeys];
        for (NSString *key in keys) {
            if ([[[firstCollection objectForKey:key] objectForKey:@"IsFinish"] isEqualTo: @(0)]) {
                [firstCollection setValue:[self dealWithFirstCollection:key firstCollection:firstCollection] forKey:key];
            }
        }
    }

    // 去除 终结符集合中的 重复的 符号
    NSArray *keys = [firstCollection allKeys];
    for (NSString *key in keys) {
        [firstCollection setValue:[self removeRepetitionSignal:key firstCollection:firstCollection] forKey:key];
    }
    
    firstCollectionDictionary = [NSDictionary dictionaryWithDictionary:firstCollection];
    // 最后进行文法的 展示
    self.firstCollectionResultTextView.string = [self fileContextShow:firstCollection];
}

// 获取 first集 每一个结束符的第一个字符，并组成字典类型
- (NSDictionary *)separateFirstCollection:(NSString *)rowContext {
    NSArray *arrowHeadArr = [self separateCollection:rowContext];
    
    // 获取每一个 结束符的 第一个符号
    NSMutableArray *endSignals = [NSMutableArray array];
    for (NSString *signal in arrowHeadArr[1]) {
        [endSignals addObject:[NSString stringWithFormat:@"%c", [signal characterAtIndex:0]]];
    }
    
    // 将每一个起始符 和 其到达分离
    // IsFinish： 1表示完成 0表示未完成
    return @{arrowHeadArr[0]: @{@"IsFinish": @(0), @"EndSignalValues":endSignals}};
}

// 分离数据（依据：-> 和 |）
- (NSArray *)separateCollection:(NSString *)rowContext {
    // 先根据 -> 分离 起始符
    NSArray *arrowHeadArr = [rowContext componentsSeparatedByString:@"->"];
    NSArray *orSignalsArr = [arrowHeadArr[1] componentsSeparatedByString:@"|"];

    return @[arrowHeadArr[0], orSignalsArr];
}

// first集 数据处理
- (NSDictionary *)dealWithFirstCollection:(NSString *)key firstCollection:(NSMutableDictionary *)firstCollection {
    NSArray *keys = [firstCollection allKeys];
    NSArray *values = [[firstCollection objectForKey:key] objectForKey:@"EndSignalValues"];
    NSMutableArray *newValues = [NSMutableArray arrayWithArray:[[firstCollection objectForKey:key] objectForKey:@"EndSignalValues"]];
    NSNumber *isFinish = @(1);
    
    for (NSString *value in values) {
        for (NSString *keyStr in keys) {
            if ([keyStr isEqualToString:value]) {
                isFinish = @(0);
                [newValues removeObject:value];
                [newValues addObjectsFromArray:[[[firstCollection objectForKey:keyStr] objectForKey:@"EndSignalValues"] copy]];
            }
        }
    }
    
    return @{@"IsFinish": isFinish, @"EndSignalValues": newValues};
}

// 判断 循环是否结束： 即只要有一个 起始符对应的终结符的集合中 含有起始符， 就认为未完成返回NO，否则返回YES
- (BOOL)isFinishWithFirstCollection:(NSDictionary *)firstCollection {
    BOOL isFinish = YES;
    
    NSArray *keys = [firstCollection allKeys];
    for (NSString *key in keys) {
        if ([[[firstCollection objectForKey:key] objectForKey:@"IsFinish"] isEqualTo:@(0)]) {
            isFinish = NO;
            break;
        }
    }
    
    return isFinish;
}

// 去除 终结符集合中的 重复的 符号
- (NSArray *)removeRepetitionSignal:(NSString *)key firstCollection:(NSMutableDictionary *)firstCollection {
    NSArray *values = [[firstCollection objectForKey:key] objectForKey:@"EndSignalValues"];
    NSSet *newValues = [NSSet setWithArray:values];
    return [newValues allObjects];
}

// 数据展示
- (NSString *)fileContextShow:(NSDictionary *)firstCollection {
    NSMutableString *newFileContext = [NSMutableString string];
    NSArray *keys = [firstCollection allKeys];
    
    for (NSString *key in keys) {
        
        // 对数据进行处理
        NSMutableString *allValue = [NSMutableString string];
        NSArray *values = [firstCollection objectForKey:key];
        for (NSString *value in values) {
            if ([[values lastObject] isEqualToString:value]) {
                [allValue appendFormat:@" %@ ", value];
            }else {
                [allValue appendFormat:@" %@ ,", value];
            }
        }
        
        // 处理每一个的最终数据
        [newFileContext appendFormat:@"%@ 的first集为：{%@}\n", key, allValue];
    }
    
    return newFileContext;
    
}

#pragma mark - 求 follow 集
- (IBAction)foundFollowCollection:(id)sender {
    NSString *fileContext = self.grammarDataTextView.string;
    NSDictionary *baseFollowCollectionData = [self separateFollowCollection:fileContext];
    NSMutableDictionary *followCollection = [self createFollowCollectionData:baseFollowCollectionData];
    
    // 获取开始字符
    NSString *startSignal = [NSString stringWithFormat:@"%c", [fileContext characterAtIndex:0]];
    
    // 按规则进行处理
    for (NSString *key in [followCollection allKeys]) {
        // 判断是不是 开始符号
        [self dealWithFirstRule:followCollection currentKey:key startSignal:startSignal];
        
        // 进行 剩余3个规则 的判断
        [self dealWithOtherRule:followCollection currentKey:key baseFollowCollectionData:baseFollowCollectionData];
    }
    
    // 将 FollowX 替换成 相应的 Follow 集
    // 循环处理： 只要有一个 起始符对应的终结符的集合中 含有起始符， 就要进行一次循环， 直到完成所有的循环。
    while (![self isFinishWithFirstCollection:followCollection]) {
        NSArray *keys = [followCollection allKeys];
        for (NSString *key in keys) {
            if ([[[followCollection objectForKey:key] objectForKey:@"IsFinish"] isEqualTo: @(0)]) {
                [followCollection setValue:[self replaceFollowCollectionFolloWX:followCollection currentKey:key] forKey:key];
                
            }
        }
    }
    
    // 去除 终结符集合中的 重复的 符号
    NSArray *keys = [followCollection allKeys];
    for (NSString *key in keys) {
        [followCollection setValue:[self removeRepetitionSignal:key firstCollection:followCollection] forKey:key];
    }

    followCollectionDictionary = [NSDictionary dictionaryWithDictionary:followCollection];
    self.followCollectionResultTextView.string = [self fileContextShow:followCollection];
    
}

// 获取follow集的基础数据
- (NSDictionary *)separateFollowCollection:(NSString *)fileContext {
    NSArray *fileContextArr = [self separateFileContextWithRow:fileContext];
    NSMutableDictionary *baseFollowCollectionData = [NSMutableDictionary dictionary];
    
    // 获取 起始符 和 起对应的终结符（箭头的右侧）
    for (NSString *rowContext in fileContextArr) {
        if (![rowContext isEqualToString:@""]) {
            NSArray *arrowHeadArr = [self separateCollection:rowContext];
            [baseFollowCollectionData setObject:arrowHeadArr[1] forKey:arrowHeadArr[0]];
        }
    }
    // 将每一个起始符 和 其结束符分离
    return baseFollowCollectionData;
}

// 建立 follow集的 结束符数据
- (NSMutableDictionary *)createFollowCollectionData:(NSDictionary *)baseFollowCollectionData {
    NSMutableDictionary *followCollection  = [NSMutableDictionary dictionary];
    
    for (NSString *key in [baseFollowCollectionData allKeys]) {
        // IsFinish： 1表示完成 0表示未完成
        [followCollection setValue:@{@"IsFinish": @(0), @"EndSignalValues":@[]} forKey:key];
    }
    
    return followCollection;
}

// 确定开始符号
- (BOOL)dealWithFirstRule:(NSMutableDictionary *)followCollection currentKey:(NSString *)currentKey startSignal:(NSString *)startSignal {
    
    if ([currentKey isEqualToString:startSignal]) {
       [self saveFollowCollectionData:followCollection currentKey:currentKey followChar:@"#"];
        return YES;
    }
    
    return NO;
}

// 进行规则2、3、4的判断
- (void)dealWithOtherRule:(NSMutableDictionary *)followCollection currentKey:(NSString *)currentKey baseFollowCollectionData:(NSDictionary *)baseFollowCollectionData {
    
    // 循环整个字典
    for (NSString *key in [baseFollowCollectionData allKeys]) {
        NSArray *BaseEndSignalValues = [baseFollowCollectionData objectForKey:key];
        
        // 循环每一个的结束符
        for (NSString *value in BaseEndSignalValues) {
            // 按规则要求进行每一个字符的判断
            for (int i = 0; i < [value length]; i++) {
                NSString *currentChar = [NSString stringWithFormat:@"%c", [value characterAtIndex:i]];
                // 进行规则2、3、4的判断
                if ([currentKey isEqualToString:currentChar]) {
                    // 进行第4条规则的判断
                    if (i == [value length] - 1) {
                        [self dealWithFourthRule:followCollection currentKey:currentKey followChar:key];
                    }else {
                        NSString *nextChar = [NSString stringWithFormat:@"%c", [value characterAtIndex:i + 1]];
                        // 判断下一个字符是不是 起始符 或者 空字符（$），如果是运用第三、四条规则，不是则运用第二条规则。
                        int nextCharIsKey = NO;
                        for (NSString *key in [baseFollowCollectionData allKeys]) {
                            if ([nextChar isEqualToString:key]) {
                                nextCharIsKey = YES;
                            }
                        }
                        
                        if (nextCharIsKey) {
                            // 处理第三条规则
                            [self dealWithThirdRule:followCollection currentKey:currentKey followChar:nextChar];
                            
                            // 处理第四条规则
                            NSArray *nextCharEndValues = [baseFollowCollectionData objectForKey:nextChar];
                            for (NSString *value in nextCharEndValues) {
                                if ([value isEqualToString:@"$"]) {
                                    [self dealWithFourthRule:followCollection currentKey:currentKey followChar:key];
                                }
                            }
                        }else {
                            // 第二条规则
                            [self dealWithSecondRule:followCollection currentKey:currentKey followChar:nextChar];
                        }
                    }
                }
            }
        }
    }
}

// 规则2 结果处理
- (void)dealWithSecondRule:(NSMutableDictionary *)followCollection currentKey:(NSString *)currentKey followChar:(NSString *)followChar  {
    [self saveFollowCollectionData:followCollection currentKey:currentKey followChar:followChar];
}

// 规则3 结果处理
- (void)dealWithThirdRule:(NSMutableDictionary *)followCollection currentKey:(NSString *)currentKey followChar:(NSString *)followChar {
    // 获取 first集
    NSArray *firtCollectionValues = [firstCollectionDictionary objectForKey:followChar];
    for (NSString *value in firtCollectionValues) {
        if (![value isEqualToString:@"$"]) {
            [self saveFollowCollectionData:followCollection currentKey:currentKey followChar:value];
        }
    }
}

// 规则4 结果处理
- (void)dealWithFourthRule:(NSMutableDictionary *)followCollection currentKey:(NSString *)currentKey followChar:(NSString *)followChar {
    [self saveFollowCollectionData:followCollection currentKey:currentKey followChar:[NSString stringWithFormat:@"Follow%@", followChar]];
}

// 将 FollowX 替换成 相应的 Follow 集
- (NSDictionary *)replaceFollowCollectionFolloWX:(NSMutableDictionary *)followCollection currentKey:(NSString *)currentKey {
    NSArray *values = [[followCollection objectForKey:currentKey] objectForKey:@"EndSignalValues"];
    NSMutableArray *newValues = [NSMutableArray arrayWithArray:[[followCollection objectForKey:currentKey] objectForKey:@"EndSignalValues"]];
    NSNumber *isFinish = @(1);
    
    for (NSString *value in values) {
        if ([value hasPrefix:@"Follow"]) {
            NSString *key = [NSString stringWithFormat:@"%c",[value characterAtIndex:6]];
            isFinish = @(0);
            [newValues removeObject:value];
            [newValues addObjectsFromArray:[[[followCollection objectForKey:key] objectForKey:@"EndSignalValues"] copy]];
        }
    }
    
    NSMutableArray *newValuesNoSelf = [NSMutableArray array];
    // 去除本身的 Follow 集
    for (NSString *value in newValues) {
        if (![value isEqualToString:[NSString stringWithFormat:@"Follow%@",currentKey]]) {
            [newValuesNoSelf addObject:value];
        }
    }
    
    return @{@"IsFinish": isFinish, @"EndSignalValues": newValuesNoSelf};
}

// 保存 新数据 至 follow 集
- (void)saveFollowCollectionData:(NSMutableDictionary *)followCollection currentKey:(NSString *)currentKey followChar:(NSString *)followChar  {
    NSMutableArray *EndSignalValues = [self valuesAddObject:[[followCollection objectForKey:currentKey] objectForKey:@"EndSignalValues"] newChar:followChar];
    
    [followCollection setObject:@{@"IsFinish": @(0), @"EndSignalValues":EndSignalValues} forKey:currentKey];
}

- (NSMutableArray *)valuesAddObject:(NSArray *)values newChar:(NSString *)newChar {
    NSMutableArray *EndSignalValues = [NSMutableArray arrayWithArray:values];
    [EndSignalValues addObject:newChar];
    
    return EndSignalValues;
}

#pragma mark - 求预测分析表

- (IBAction)createForecastAnalyzeTable:(id)sender {
    NSDictionary *baseFileContextDic = [self separateFollowCollection:self.grammarDataTextView.string];
    // 创建一个 保存数据的字典
    NSMutableDictionary *forecastAnalyzeTableDic = [self createDictionaryForSaveForecastAnalyzeTableData:baseFileContextDic];

    // 进行规则二、三的判断
    for (NSString *key in firstCollectionDictionary) {
        NSArray *firstCResultArr = [firstCollectionDictionary objectForKey:key];
        for (NSString *firstCResult in firstCResultArr) {
            // 数据处理
            [self foundFirstCExpression:key firstCResult:firstCResult baseFileContextDic:baseFileContextDic forecastAnalyzeTableDic:forecastAnalyzeTableDic];
        }
    }
    
    forecastAnalyzeTableDictionary = [NSDictionary dictionaryWithDictionary:forecastAnalyzeTableDic];
    [self showForecastAnalyzeTableData:forecastAnalyzeTableDic];
    
}


// 创建初始数据：一个用于保存数据的字典
- (NSMutableDictionary *)createDictionaryForSaveForecastAnalyzeTableData:(NSDictionary *)baseFileContextDic {
    
    // 获取 所有的非终结符
    NSArray *nonterminalSymbols = [baseFileContextDic allKeys];
    
    // 获取 所有的终结符
    terminalSymbols = [NSMutableArray array];
    BOOL isTerminalSymbol = YES;
    
    for (NSString *key in nonterminalSymbols) {
        NSArray *values = [baseFileContextDic objectForKey:key];
        for (NSString *value in values) {
            for (int i = 0; i < [value length]; i++) {
                // 将要判断的符号 默认为终结符
                isTerminalSymbol = YES;
                NSString *symbol = [NSString stringWithFormat:@"%c",[value characterAtIndex:i]];
                
                // 判断是不是终结符，不是的话，将判断符设置为非终结符（NO）
                for (NSString *nonterminalSymbol in nonterminalSymbols) {
                    if ([nonterminalSymbol isEqualToString:symbol]) {
                        isTerminalSymbol = NO;
                    }
                }
                
                // 如果symbol 为空，也不是终结符
                if ([symbol isEqualToString:@"$"]) {
                    isTerminalSymbol = NO;
                }
                
                if (isTerminalSymbol) {
                    [terminalSymbols addObject:symbol];
                }
            }
        }
    }
    // 额外加上结束标识符#
    [terminalSymbols addObject:@"#"];
    
    // 将非终结符作为key，终结符作为内容创建Dictionary
    NSMutableDictionary *forecastAnalyzeTableDic = [NSMutableDictionary dictionary];
    for (NSString *nonterminalSymbol in nonterminalSymbols) {
        NSMutableDictionary *terminalSymbolsDic = [NSMutableDictionary dictionary];
        for (NSString *terminalSymbol in terminalSymbols) {
            [terminalSymbolsDic setValue:@"" forKey:terminalSymbol];
        }
        [forecastAnalyzeTableDic setValue:terminalSymbolsDic forKey:nonterminalSymbol];
    }
    
    return forecastAnalyzeTableDic;
}

// 规则二、三判断 主函数
- (void)foundFirstCExpression:(NSString *)firstCKey
                 firstCResult:(NSString *)firstCResult
           baseFileContextDic:(NSDictionary *)baseFileContextDic
      forecastAnalyzeTableDic:(NSMutableDictionary *)forecastAnalyzeTableDic {

    NSArray *values = [baseFileContextDic objectForKey:firstCKey];
    
    for (NSString *value in values) {
        NSString *firstCharWithValue = [NSString stringWithFormat:@"%c",[value characterAtIndex: 0]];
        
        // 判断是否等于 非终结符，如果是非终结符，则找出其对应的最后的终结符，并进行判断
        for (NSString *key in [baseFileContextDic allKeys]) {
            if ([key isEqualToString:firstCharWithValue]) {
                if ([firstCResult isEqualToString:[self foundFirstC:key firstCResult:firstCResult baseFileContextDic:baseFileContextDic]]) {
                    if ([firstCResult isEqualToString:@"$"]) {
                        // 规则三 的处理
                        [self dealWithThirdRulesWithForecastAnalyze:firstCKey value:value forecastAnalyzeTableDic:forecastAnalyzeTableDic];
                    }else {
                        // 规则二 的保存
                        [self saveFirstCExpression:firstCKey firstCResult:firstCResult firstCExpression:value forecastAnalyzeTableDic:forecastAnalyzeTableDic];
                    }
                }
            }
        }
        
        if ([firstCharWithValue isEqualToString:firstCResult]) {
            if ([firstCResult isEqualToString:@"$"]) {
                // 规则三 的处理
                [self dealWithThirdRulesWithForecastAnalyze:firstCKey value:value forecastAnalyzeTableDic:forecastAnalyzeTableDic];
            }else {
                // 规则二 的保存
                [self saveFirstCExpression:firstCKey firstCResult:firstCResult firstCExpression:value forecastAnalyzeTableDic:forecastAnalyzeTableDic];
            }
        }
    }
    
}

// 找到 终结符
- (NSString *)foundFirstC:(NSString *)firstCKey firstCResult:(NSString *)firstCResult
       baseFileContextDic:(NSDictionary *)baseFileContextDic {
    
    NSArray *values = [baseFileContextDic objectForKey:firstCKey];
    
    for (NSString *value in values) {
        NSString *firstCharWithValue = [NSString stringWithFormat:@"%c",[value characterAtIndex: 0]];
        BOOL isNonKey = YES;
        
        for (NSString *key in [baseFileContextDic allKeys]) {
            if ([key isEqualToString:firstCharWithValue]) {
                isNonKey = NO;
                return [self foundFirstC:key firstCResult:firstCResult baseFileContextDic:baseFileContextDic];
            }
        }
        
        if (isNonKey) {
            if ([firstCResult isEqualToString:firstCharWithValue]) {
                return firstCharWithValue;
            }
        }
    }
    
    return nil;
}

// 规则三
- (void)dealWithThirdRulesWithForecastAnalyze:(NSString *)firstCKey value:(NSString *)value forecastAnalyzeTableDic:(NSMutableDictionary *)forecastAnalyzeTableDic  {
    
    for (NSString *key in [followCollectionDictionary allKeys]) {
        if ([key isEqualToString:firstCKey]) {
            NSArray *followCResults = [followCollectionDictionary objectForKey:key];
            for (NSString *followCResult in followCResults) {
                [self saveFirstCExpression:firstCKey firstCResult:followCResult firstCExpression:value forecastAnalyzeTableDic:forecastAnalyzeTableDic];
            }
        }
    }
}

// 在保存数据 的字典中，加入 找出的表达式
- (void)saveFirstCExpression:(NSString *)firstCKey firstCResult:(NSString *)firstCResult firstCExpression:(NSString *)firstCExpression forecastAnalyzeTableDic:(NSMutableDictionary *)forecastAnalyzeTableDic {
    NSMutableDictionary *dic = [forecastAnalyzeTableDic objectForKey:firstCKey];
    
    for (NSString *key in [dic allKeys]) {
        if ([key isEqualToString:firstCResult]) {
            [dic setObject:[NSString stringWithFormat:@"%@->%@", firstCKey, firstCExpression] forKey:firstCResult];
        }
    }
    
    [forecastAnalyzeTableDic setObject:dic forKey:firstCKey];
}

// 展示预测分析表
- (void)showForecastAnalyzeTableData:(NSDictionary *)forecastAnalyzeTableDic {
    if (!forecastAnalyzeHasData) {
        forecastAnalyzeHasData = YES;
        // 删除原有的 TableColumn
        for (NSTableColumn *tableColumn in self.forecastAnalyzeTableView.tableColumns) {
            [self.forecastAnalyzeTableView removeTableColumn:tableColumn];
        }

        // 创建 新的 TableColumn
        for (int i = 0; i < [terminalSymbols count] + 1; i++) {
            NSTableColumn * channTableColumn = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"channels%d",i]];
            channTableColumn.maxWidth = 65;
            if (i != 0) {
                channTableColumn.title = terminalSymbols[i - 1];
            }else {
                channTableColumn.title = @"";
            }
            [self.forecastAnalyzeTableView addTableColumn:channTableColumn];
        }
    }
    
    [self.forecastAnalyzeTableView reloadData];
}


#pragma mark - 预测分析表的 TableView
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return  [[forecastAnalyzeTableDictionary allKeys] count];
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    NSString *key = [forecastAnalyzeTableDictionary allKeys][row];
    NSDictionary *dic = [forecastAnalyzeTableDictionary objectForKey:key];
    
    if( [tableColumn.identifier isEqualToString:@"channels0"] ) {
        return key;
    }else {
        NSString *channelsTitle = tableColumn.title;
        return [dic objectForKey:channelsTitle];
    }
}


#pragma mark - 私有工具方法
- (void)createAlertView:(NSString *)msgText infomativeText:(NSString *)infomativeText {
    NSAlert *alert = [[NSAlert alloc] init];
    [alert addButtonWithTitle:@"确定"];
    [alert setMessageText:msgText];
    [alert setInformativeText:infomativeText];
    [alert setAlertStyle:NSCriticalAlertStyle];
    [alert beginSheetModalForWindow:self.window completionHandler:nil];
}






@end
