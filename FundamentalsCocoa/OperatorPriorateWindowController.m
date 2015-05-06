//
//  OperatorPriorateWindowController.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/29.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "OperatorPriorateWindowController.h"
#import "FileOperateClass.h"

@interface OperatorPriorateWindowController () {
    NSDictionary *firstVTValuesDic;
    NSDictionary *lastVTValuesDic;
    NSDictionary *operatorPriorDic;
    NSArray *operatorPriorResultArr;
    
    // 获取 终结符/非终结符数组
    NSArray *terminalSymbols;
    NSArray *nonTerminalSymbols;
}


@property (unsafe_unretained) IBOutlet NSTextView *grammarDataTextView;
@property (unsafe_unretained) IBOutlet NSTextView *firstVTResultTextView;
@property (unsafe_unretained) IBOutlet NSTextView *lastVTResultTextView;
@property (weak) IBOutlet NSTableView *operatorPriorateDataTableView;
@property (weak) IBOutlet NSTableView *operatorPriorateResultWithContextTableView;
@property (weak) IBOutlet NSTextField *contextNeedAnalyzeTextField;

@end

@implementation OperatorPriorateWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    firstVTValuesDic = [NSDictionary dictionary];
    lastVTValuesDic = [NSDictionary dictionary];
    operatorPriorDic = [NSDictionary dictionary];
    operatorPriorResultArr = [NSArray array];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - 文件操作：打开、保存、文法确认
- (IBAction)openFile:(id)sender {
    [[[FileOperateClass alloc] init] openFileWithSelectFolder:self.window gainData:^(NSString *result) {
        self.grammarDataTextView.string = result;
    }];
}

- (IBAction)saveFile:(id)sender {
    
}

// 确认文法的格式
- (IBAction)sureFileFormat:(id)sender {
    self.grammarDataTextView.string = [self removeBlank:self.grammarDataTextView.string];
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

#pragma mark - 求 FirstVT集 和 LastVT集
- (IBAction)foundFirstVTCollection:(id)sender {
    NSDictionary *baseDataWithFirstVT = [self gainBaseCollectionDataBySeparateVT:self.grammarDataTextView.string];
    NSMutableDictionary *firstVTCollection = [self createFollowCollectionData:baseDataWithFirstVT];
    // 获取 非终结符数组
    nonTerminalSymbols = [baseDataWithFirstVT allKeys];
    
    // 按规则一找出 该文法的 FirstVT
    for (NSString *key in [baseDataWithFirstVT allKeys]) {
        NSArray *values = [baseDataWithFirstVT objectForKey:key];
        for (NSString *value in values) {
            [self dealWithFirstVTWithRules:firstVTCollection currentKey:key currentValue:value];
        }
    }
    
    
    // 从VT集替换非终结符元素和删除重复元素
    [self removeNonTerminalAndRepeatSymbolFormVT:firstVTCollection keys:[baseDataWithFirstVT allKeys]];
    
    firstVTValuesDic = [NSDictionary dictionaryWithDictionary:firstVTCollection];
    // 最后进行文法的 展示
    self.firstVTResultTextView.string = [self fileContextShow:firstVTCollection vtName:@"FirstVt"];
    
}

// 按规则处理 firstVT
- (void)dealWithFirstVTWithRules:(NSMutableDictionary *)firstVTCollection currentKey:(NSString *)currentKey currentValue:(NSString *)currentValue {
    NSString *currentChar = [NSString stringWithFormat:@"%c", [currentValue characterAtIndex:0]];
    
    if ([self currentCharIsNonTerminalSymbol:currentChar]) {
        // 将 该非终结符的FirstVT 加入 所求的非终结符的 FirstVT
        [self saveCurrentCharToVTCollection:currentKey currentChar:currentChar vtCollection:firstVTCollection];
        
        // 再判断 其下一个字符是不是终结符
        // 在此之前要先判断 currentValue 是不是只有一个字符，只有一个的话直接函数结束
        if ([currentValue length] < 2) {
            return;
        }
        
        NSString *nextChar = [NSString stringWithFormat:@"%c", [currentValue characterAtIndex:1]];
        if (![self currentCharIsNonTerminalSymbol:nextChar]) {
            // 将该字符(nextChar)加入 所求的非终结符的 FirstVT
            [self saveCurrentCharToVTCollection:currentKey currentChar:nextChar vtCollection:firstVTCollection];
        }
    }else {
        // 将该字符(currentChar)加入 所求的非终结符的 FirstVT
        [self saveCurrentCharToVTCollection:currentKey currentChar:currentChar vtCollection:firstVTCollection];
    }
    
}

// LastVT 集
- (IBAction)foundLastVTCollection:(id)sender {
    NSDictionary *baseDataWithlastVT = [self gainBaseCollectionDataBySeparateVT:self.grammarDataTextView.string];
    NSMutableDictionary *lastVTCollection = [self createFollowCollectionData:baseDataWithlastVT];
    
    // 按规则找出 该文法的 lastVT
    for (NSString *key in [baseDataWithlastVT allKeys]) {
        NSArray *values = [baseDataWithlastVT objectForKey:key];
        for (NSString *value in values) {
            [self dealWithLastVTWithRules:lastVTCollection currentKey:key currentValue:value];
        }
    }
    
    // 从VT集替换非终结符元素和删除重复元素
    [self removeNonTerminalAndRepeatSymbolFormVT:lastVTCollection keys:[baseDataWithlastVT allKeys]];
    
   lastVTValuesDic = [NSDictionary dictionaryWithDictionary:lastVTCollection];
    // 最后进行文法的 展示
    self.lastVTResultTextView.string = [self fileContextShow:lastVTCollection vtName:@"LastVt"];
}

// 按规则一处理 lastVT
- (void)dealWithLastVTWithRules:(NSMutableDictionary *)lastVTCollection currentKey:(NSString *)currentKey currentValue:(NSString *)currentValue {
    NSUInteger lastIndex = [currentValue length] - 1;
    NSString *lastChar = [NSString stringWithFormat:@"%c", [currentValue characterAtIndex:lastIndex]];
    
    if ([self currentCharIsNonTerminalSymbol:lastChar]) {
        [self saveCurrentCharToVTCollection:currentKey currentChar:lastChar vtCollection:lastVTCollection];
        // 判断如果最后一个元素是非终结符，则判断最后第二个元素是不是终结符，是的话加入
        if ([currentValue length] < 2) {
            return;
        }
        
        NSString *proChar = [NSString stringWithFormat:@"%c", [currentValue characterAtIndex:lastIndex - 1]];
        if (![self currentCharIsNonTerminalSymbol:proChar]) {
            [self saveCurrentCharToVTCollection:currentKey currentChar:proChar vtCollection:lastVTCollection];
        }
    }else {
        // 将该字符(currentChar)加入 所求的非终结符的 FirstVT
        [self saveCurrentCharToVTCollection:currentKey currentChar:lastChar vtCollection:lastVTCollection];
    }
}




// 建立 firstVT/lastVT 集的 结束符数据
- (NSMutableDictionary *)createFollowCollectionData:(NSDictionary *)baseFollowCollectionData {
    NSMutableDictionary *followCollection  = [NSMutableDictionary dictionary];
    
    for (NSString *key in [baseFollowCollectionData allKeys]) {
        // IsFinish： 1表示完成 0表示未完成
        [followCollection setValue:@{@"IsFinish": @(0), @"EndSignalValues":@[]} forKey:key];
    }
    
    return followCollection;
}

// 判断 求解VT集是否结束
- (BOOL)isFinishWithDealWithVTCollection:(NSDictionary *)vtCollection {
    BOOL isFinish = YES;
    
    NSArray *keys = [vtCollection allKeys];
    for (NSString *key in keys) {
        if ([[[vtCollection objectForKey:key] objectForKey:@"IsFinish"] isEqualTo:@(0)]) {
            isFinish = NO;
            break;
        }
    }
    
    return isFinish;
}

// 将数据保存至该非终结符的First集
- (void)saveCurrentCharToVTCollection:(NSString *)currentKey currentChar:(NSString *)currentChar vtCollection:(NSMutableDictionary *)vtCollection {
    NSMutableArray *firstVTValues = [NSMutableArray arrayWithArray:[[vtCollection objectForKey:currentKey] objectForKey:@"EndSignalValues"]];
    [firstVTValues addObject:currentChar];
    [vtCollection setValue:@{@"IsFinish": @(0), @"EndSignalValues":firstVTValues} forKey:currentKey];
}

// 从VT集替换非终结符元素和删除重复元素
- (void)removeNonTerminalAndRepeatSymbolFormVT:(NSMutableDictionary *)firstVTCollection keys:(NSArray *)baseKeys {
    // 将 FirstVT 集中的非终结符替换成相应的终结符（该终结符的FirstVT集）
    while (![self isFinishWithDealWithVTCollection:firstVTCollection]) {
        for (NSString *key in baseKeys) {
            if ([[[firstVTCollection objectForKey:key] objectForKey:@"IsFinish"] isEqualTo: @(0)]) {
                [firstVTCollection setValue:[self dealWithNonTerminalSymbolInVT:key firstVTCollection:firstVTCollection] forKey:key];
            }
        }
    }
    
    // 去除 终结符集合中的 重复的 符号
    NSArray *keys = [firstVTCollection allKeys];
    for (NSString *key in keys) {
        [firstVTCollection setValue:[self removeRepetitionSignal:key firstCollection:firstVTCollection] forKey:key];
    }
}

// 将该所求的终结符的fitst集中的非终结符替换成它的firstVT集，并从first集中删除自己
- (NSDictionary *)dealWithNonTerminalSymbolInVT:(NSString *)currentKey firstVTCollection:(NSMutableDictionary *)firstVTCollection {
    NSArray *values = [[firstVTCollection objectForKey:currentKey] objectForKey:@"EndSignalValues"];
    NSMutableArray *newValues = [NSMutableArray arrayWithArray:[[firstVTCollection objectForKey:currentKey] objectForKey:@"EndSignalValues"]];
    NSNumber *isFinish = @(1);
    
    for (NSString *value in values) {
        if ([self currentCharIsNonTerminalSymbol:value]) {
            isFinish = @(0);
            [newValues removeObject:value];
            [newValues addObjectsFromArray:[[[firstVTCollection objectForKey:value] objectForKey:@"EndSignalValues"] copy]];
        }
    }
    
    NSMutableArray *newValuesNoSelf = [NSMutableArray array];
    // 去除本身的 Follow 集
    for (NSString *value in newValues) {
        if (![value isEqualToString:currentKey]) {
            [newValuesNoSelf addObject:value];
        }
    }
    
    return @{@"IsFinish": isFinish, @"EndSignalValues": newValuesNoSelf};
}

// 去除 终结符集合中的 重复的 符号
- (NSArray *)removeRepetitionSignal:(NSString *)key firstCollection:(NSMutableDictionary *)firstCollection {
    NSArray *values = [[firstCollection objectForKey:key] objectForKey:@"EndSignalValues"];
    NSSet *newValues = [NSSet setWithArray:values];
    return [newValues allObjects];
}

// 数据展示
- (NSString *)fileContextShow:(NSDictionary *)firstCollection vtName:(NSString *)vtName {
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
        [newFileContext appendFormat:@"%@ 的%@集为：{%@}\n", key, vtName, allValue];
    }
    
    return newFileContext;
    
}


#pragma mark - 创建算符优先表
- (IBAction)createOperatorPriorData:(id)sender {
     NSDictionary *contextDic = [self gainBaseCollectionDataBySeparateVT:self.grammarDataTextView.string];
    // 获取 终结符数组
    terminalSymbols = [self gainTerminalSymbols:contextDic];
    // 创建 最终数据存储字典
    NSMutableDictionary *operatorPriorDictionary = [self createOperatorPriorDic];
    
    // 进行规则的判断并处理
    for (NSString *nonTerminalSymbol in nonTerminalSymbols) {
        NSArray *values = [contextDic objectForKey:nonTerminalSymbol];
        // 循环每一个表达式
        for (NSString *value in values) {
            // 循环每一个表达式的每一个字符
            for (int i = 0; i < [value length] - 1; i++) {
                
                NSString *currentChar = [NSString stringWithFormat:@"%c",[value characterAtIndex:i]];
                NSString *nextChar = [NSString stringWithFormat:@"%c",[value characterAtIndex:i + 1]];
                // 判断当前字符是不是非终结符，是的话，进行规则四的判断
                if ([self currentCharIsNonTerminalSymbol:currentChar]) {
                    // 规则四判断
                    if(![self currentCharIsNonTerminalSymbol:nextChar]) {
                        // 规则四处理
                        [self dealWithOperatorPriorWithFourthRules:operatorPriorDictionary fatherChar:currentChar sonChar:nextChar];
                    }
                }else {
                    // 判断下一个字符是不是非终结符， 是的话，进行规则二、三的判断
                    if ([self currentCharIsNonTerminalSymbol:nextChar]) {
                        // 规则三处理
                        [self dealWithOperatorPriorWithThirdRules:operatorPriorDictionary fatherChar:currentChar sonChar:nextChar];
                        
                        // 规则二判断
                        if(i < [value length] - 2) {
                            NSString *nextNextChar = [NSString stringWithFormat:@"%c",[value characterAtIndex:i + 2]];
                            if (![self currentCharIsNonTerminalSymbol:nextNextChar]) {
                                // 规则二处理
                                [self dealWithOperatorPriorWithFirstAndSecondRules:operatorPriorDictionary fatherChar:currentChar sonChar:nextNextChar];
                            }
                        }
                        
                    }else {
                        // 规则一处理
                        [self dealWithOperatorPriorWithFirstAndSecondRules:operatorPriorDictionary fatherChar:currentChar sonChar:nextChar];
                    }
                }
            }
        }
    }
    
    operatorPriorDic = [NSMutableDictionary dictionaryWithDictionary:operatorPriorDictionary];
    [self showOperatorPriorTableData:operatorPriorDictionary];
}

// 获取 所有的终结符
- (NSArray *)gainTerminalSymbols:(NSDictionary *)contextDic {
    NSArray *keys = [contextDic allKeys];
    NSMutableArray *newTerminalSymbols = [NSMutableArray array];
    
    for (NSString *key in keys) {
        for (NSString *value in [contextDic objectForKey:key]) {
            for (int i = 0; i < [value length]; i++) {
                NSString *currentChar = [NSString stringWithFormat:@"%c",[value characterAtIndex:i]];
                if (![self currentCharIsNonTerminalSymbol:currentChar]) {
                    [newTerminalSymbols addObject:currentChar];
                }
            }
        }
    }
    
    // 删除可能有的重复数据
    NSSet *newTerminalSymbolsWithNonRepeat = [NSSet setWithArray:newTerminalSymbols];
    return [newTerminalSymbolsWithNonRepeat allObjects];
}

// 创建 最终数据存储字典
- (NSMutableDictionary *)createOperatorPriorDic {
    NSMutableDictionary *operatorPriorDic1 = [NSMutableDictionary dictionary];
    
    for (NSString *terminalSymbolFather in terminalSymbols) {
        NSMutableDictionary *dic = [NSMutableDictionary dictionary];
        for (NSString *terminalSymbolSon in terminalSymbols) {
            [dic setValue:@"" forKey:terminalSymbolSon];
        }
        [operatorPriorDic1 setObject:dic forKey:terminalSymbolFather];
    }
    
    return operatorPriorDic1;
}

// 规则一、二
- (void)dealWithOperatorPriorWithFirstAndSecondRules:(NSMutableDictionary *)operatorPriorDictionary fatherChar:(NSString *)fatherChar sonChar:(NSString *)sonChar {
    [self saveOperatorPriorResult:operatorPriorDictionary fatherChar:fatherChar sonChar:sonChar result:@"="];
}

// 规则三
- (void)dealWithOperatorPriorWithThirdRules:(NSMutableDictionary *)operatorPriorDictionary fatherChar:(NSString *)fatherChar sonChar:(NSString *)sonChar {
    NSArray *firstVTWithSonChar = [firstVTValuesDic objectForKey:sonChar];
    
    for (NSString *firstVTElement in firstVTWithSonChar) {
        [self saveOperatorPriorResult:operatorPriorDictionary fatherChar:fatherChar sonChar:firstVTElement result:@"<"];
    }
}

// 规则四
- (void)dealWithOperatorPriorWithFourthRules:(NSMutableDictionary *)operatorPriorDictionary fatherChar:(NSString *)fatherChar sonChar:(NSString *)sonChar {
    NSArray *lastVTWithSonChar = [lastVTValuesDic objectForKey:fatherChar];
    
    for (NSString *lastVTElement in lastVTWithSonChar) {
        [self saveOperatorPriorResult:operatorPriorDictionary fatherChar:lastVTElement sonChar:sonChar result:@">"];
    }
}

// 保存结果
- (void)saveOperatorPriorResult:(NSMutableDictionary *)operatorPriorDictionary fatherChar:(NSString *)fatherChar sonChar:(NSString *)sonChar result:(NSString *)result {
    NSMutableDictionary *dic = [operatorPriorDictionary objectForKey:fatherChar];
    
    for (NSString *key in [dic allKeys]) {
        if ([key isEqualToString:sonChar]) {
            [dic setObject:result forKey:sonChar];
        }
    }
    
    [operatorPriorDictionary setObject:dic forKey:fatherChar];
}

// 展示预测分析表
- (void)showOperatorPriorTableData:(NSDictionary *)forecastAnalyzeTableDic{
    // 删除原有的 TableColumn
    NSArray *tableColumns = [NSArray arrayWithArray:self.operatorPriorateDataTableView.tableColumns];
    for (NSTableColumn *tableColumn in tableColumns) {
        [self.operatorPriorateDataTableView removeTableColumn:tableColumn];
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
        [self.operatorPriorateDataTableView addTableColumn:channTableColumn];
    }
    
    
    [self.operatorPriorateDataTableView reloadData];
}

#pragma mark - 句子分析
- (IBAction)contextAnalyze:(id)sender {
    NSDictionary *contextDic = [self gainBaseCollectionDataBySeparateVT:self.grammarDataTextView.string];
    // 输入缓冲数组
    NSMutableArray *contextNeedAnalyzeStack = [self createContextAnalyzeStack:self.contextNeedAnalyzeTextField.stringValue];
    // 分析栈
    NSMutableArray *analyzeStack = [NSMutableArray arrayWithObject:@"#"];
    NSMutableArray *operateAnalyzeResultSteps = [NSMutableArray array];
    BOOL isSucess = YES;
    
    [self saveOperateAnalyzeResult:operateAnalyzeResultSteps anaylzeStack:analyzeStack contextStack:contextNeedAnalyzeStack value:@"初始状态"];
    while (![self isSuccessWithOperateAnalyze:contextNeedAnalyzeStack analyzeStack:analyzeStack]) {
        if (![self dealWithOPerateAnalyze:contextDic contextSatck:contextNeedAnalyzeStack analyzeStack:analyzeStack perateAnalyzeResultSteps:operateAnalyzeResultSteps]) {
            isSucess = NO;
            break;
        }
    }
    
    if (isSucess) {
        [self saveOperateAnalyzeResult:operateAnalyzeResultSteps anaylzeStack:analyzeStack contextStack:contextNeedAnalyzeStack value:@"成功"];
    }else {
        [self saveOperateAnalyzeResult:operateAnalyzeResultSteps anaylzeStack:analyzeStack contextStack:contextNeedAnalyzeStack value:@"失败"];
    }
    
    operatorPriorResultArr = [NSArray arrayWithArray:operateAnalyzeResultSteps];
    [self.operatorPriorateResultWithContextTableView reloadData];
}

- (BOOL)dealWithOPerateAnalyze:(NSDictionary *)contextDic contextSatck:(NSMutableArray *)contextSatck analyzeStack:(NSMutableArray *)analyzeStack perateAnalyzeResultSteps:(NSMutableArray *)perateAnalyzeResultSteps {
    for (int i = 0; i < [contextSatck count]; i++) {
        NSString *topElementWithContextSatck = [contextSatck firstObject];
        NSString *topElementWithAnalyzeSatck = [self topElementWithAnalyzeStack:analyzeStack];
        NSString *operateSymbol = [self gainOperateSymbolInOperatorPriorDic:topElementWithAnalyzeSatck topElementWithContextSatck:topElementWithContextSatck];
        if ([operateSymbol isEqualToString:@"<"] || [operateSymbol isEqualToString:@"="]) {
            // 缓存栈弹栈，分析栈压栈
            [self pushElementToAnalyzeStack:topElementWithContextSatck analyzeStack:analyzeStack];
            [self removeElementFormContextStack:contextSatck];
            // 保存
            NSString *value = [NSString stringWithFormat:@"%@%@%@, %@入栈", topElementWithAnalyzeSatck, operateSymbol, topElementWithContextSatck, topElementWithContextSatck];
            [self saveOperateAnalyzeResult:perateAnalyzeResultSteps anaylzeStack:analyzeStack contextStack:contextSatck value:value];
        }else {
            if ([self numberOfTerminalSymbolInStack:analyzeStack] != 1) {
                NSString *secondElementWithAnalyzeSatck = [self secondElementWithAnalyzeStack:analyzeStack];
                NSString *operateSymbolWithSecond = [self gainOperateSymbolInOperatorPriorDic:secondElementWithAnalyzeSatck topElementWithContextSatck:topElementWithAnalyzeSatck];
                if ([operateSymbol isEqualToString:@">"] && [operateSymbolWithSecond isEqualToString:@"<"]) {
                    // 归约
                    // 缓存栈不变，分析栈讲第一个终结字符归约， 如果终结字符两侧是非终结字符，则三个字符一起替换
                    NSString *expersionChar = [self foundExperssionChar:analyzeStack topElementWithAnalyzeSatck:topElementWithAnalyzeSatck];
                    NSArray *expersion = [self foundExpression:contextDic value:expersionChar];
                    [self removeElementFormAnalyeStack:analyzeStack expersionChar:expersionChar];
                    [self pushElementToAnalyzeStack:expersion[0] analyzeStack:analyzeStack];
                    // 保存
                    NSString *value = [NSString stringWithFormat:@"%@%@%@%@%@, 用%@->%@归约", secondElementWithAnalyzeSatck, operateSymbolWithSecond, topElementWithAnalyzeSatck, operateSymbol, topElementWithContextSatck, expersion[0], expersion[1]];
                    [self saveOperateAnalyzeResult:perateAnalyzeResultSteps anaylzeStack:analyzeStack contextStack:contextSatck value:value];
                }else {
                    // 错误
                    return NO;
                }
            }
        }
    }
    
    return YES;
}

// 判断循环是不是结束了 结束了返回YES，没有结束返回NO；
- (BOOL)isSuccessWithOperateAnalyze:(NSArray *)contextStack analyzeStack:(NSArray *)analyzeStack {
    NSString *startSymbol = [NSString stringWithFormat:@"%c",[self.grammarDataTextView.string characterAtIndex:0]];
    NSString *analyzeEnd = [NSString stringWithFormat:@"#%@",startSymbol];
    BOOL isSuccess = NO;
    
    // 获取两个栈的元素
    NSString *analyzeStr = [analyzeStack componentsJoinedByString:@""];
    NSString *contextStr = [contextStack componentsJoinedByString:@""];
    
    if ([analyzeStr isEqualToString:analyzeEnd] && [contextStr isEqualToString:@"#"]) {
        return YES;
    }
    
    return isSuccess;
}

// 判断栈中的终结符个数
- (NSInteger)numberOfTerminalSymbolInStack:(NSArray *)stack {
    NSInteger numberOfTerminalSymbol = 0;
    for (NSString *element in stack) {
        if (![self currentCharIsNonTerminalSymbol:element]) {
            numberOfTerminalSymbol ++;
        }
    }
    return numberOfTerminalSymbol;
}

// 获取相应的运算符
- (NSString *)gainOperateSymbolInOperatorPriorDic:(NSString *)topElementWithAnalyzeSatck topElementWithContextSatck:(NSString *)topElementWithContextSatck  {
    return [[operatorPriorDic objectForKey:topElementWithAnalyzeSatck] objectForKey:topElementWithContextSatck];
}

// 归约
- (NSArray *)foundExpression:(NSDictionary *)contextDic value:(NSString *)value {
    // 找直接相同的表达式
    for (NSString *key in nonTerminalSymbols) {
        NSArray *expressions = [contextDic objectForKey:key];
        for (NSString *expression in expressions) {
            if ([expression isEqualToString:value]) {
                return @[key, expression];
            }
        }
    }
    
    // 找间接相等的：即终结符相等，非终结符不相等
    NSMutableString *experssionChar = [NSMutableString string];
    for (int  i = 0; i < [value length]; i++) {
        NSString *element = [NSString stringWithFormat:@"%c",[value characterAtIndex:i]];
        if ([self currentCharIsNonTerminalSymbol:element]) {
            [experssionChar appendString:@"a"];
        }else {
            [experssionChar appendString:element];
        }
    }
    
    for (NSString *key in nonTerminalSymbols) {
        NSArray *expressions = [contextDic objectForKey:key];
        for (NSString *expression in expressions) {
            if ([expression length] == [experssionChar length]) {
                NSMutableString *experssionChar1 = [NSMutableString string];
                for (int  i = 0; i < [expression length]; i++) {
                    NSString *element = [NSString stringWithFormat:@"%c",[expression characterAtIndex:i]];
                    if ([self currentCharIsNonTerminalSymbol:element]) {
                        [experssionChar1 appendString:@"a"];
                    }else {
                        [experssionChar1 appendString:element];
                    }
                }
                if ([experssionChar isEqualToString:experssionChar1]) {
                    return @[key, expression];
                }
            }
        }
    }
    
//    if ([value length] == 3) {
//        NSString *terminalSymbol = [NSString stringWithFormat:@"%c",[value characterAtIndex:1]];
//        
//        for (NSString *key in nonTerminalSymbols) {
//            NSArray *expressions = [contextDic objectForKey:key];
//            for (NSString *expression in expressions) {
//                if ([expression rangeOfString:terminalSymbol].location != NSNotFound) {
//                    if ([expression length] == 3) {
//                        if ([self currentCharIsNonTerminalSymbol:[NSString stringWithFormat:@"%c",[expression characterAtIndex:0]]] && [self currentCharIsNonTerminalSymbol:[NSString stringWithFormat:@"%c",[expression characterAtIndex:2]]]) {
//                            return @[key, expression];
//                        }
//                    }
//                }
//            }
//        }
//    }
    return nil;
}

- (void)saveOperateAnalyzeResult:(NSMutableArray *)operateAnalyzeResultSteps anaylzeStack:(NSArray *)analyzeStack contextStack:(NSArray *)contextStack value:(NSString *)value {
    [operateAnalyzeResultSteps addObject:@{@"stepsNumber":@([operateAnalyzeResultSteps count] + 1), @"analyzeStack": [self arrayToString:analyzeStack], @"contextStack": [self arrayToString:contextStack], @"analyzeResult": value}];
}

// Stack 操作
// 创建输入缓冲数组
- (NSMutableArray *)createContextAnalyzeStack:(NSString *)contextNeedAnalyzeText {
    NSMutableArray *contextNeedAnalyzeArr = [NSMutableArray array];
    for (int i = 0; i < [contextNeedAnalyzeText length]; i++) {
        [contextNeedAnalyzeArr addObject:[NSString stringWithFormat:@"%c",[contextNeedAnalyzeText characterAtIndex:i]]];
    }
    [contextNeedAnalyzeArr addObject:@"#"];
    return contextNeedAnalyzeArr;
}

// 返回分析栈的栈顶元素
- (NSString *)topElementWithAnalyzeStack:(NSArray *)analyzeStack {
    NSString *topElement = @"";
    for (int i = (int)[analyzeStack count] - 1; i >= 0 ; i--) {
        NSString *element = [analyzeStack objectAtIndex:i];
        if (![self currentCharIsNonTerminalSymbol:element]) {
            topElement = element;
            break;
        }
    }
    return topElement;
}

// 返回第二个栈顶元素
- (NSString *)secondElementWithAnalyzeStack:(NSArray *)analyzeStack {
    NSString *topElement = @"";
    int isSecond = 1;
    for (int i = (int)[analyzeStack count] - 1; i >= 0 ; i--) {
        NSString *element = [analyzeStack objectAtIndex:i];
        if (![self currentCharIsNonTerminalSymbol:element]) {
            topElement = element;
            if (isSecond == 2) {
                break;
            }else {
                isSecond ++;
            }
        }
    }
    return topElement;
}

// 返回归约的字符
- (NSString *)foundExperssionChar:(NSArray *)analyzeStack topElementWithAnalyzeSatck:(NSString *)topElementWithAnalyzeSatck {
    NSMutableString *experssionChar = [NSMutableString string];
    int top = (int)[analyzeStack count] - 1;
    NSString *newTopElementWithAnalyzeSatck = [topElementWithAnalyzeSatck copy];
    
    for (; top > 0; top--) {
        if (![self currentCharIsNonTerminalSymbol:analyzeStack[top]]) {
            NSString *termElement = analyzeStack[top];
            if ([[self gainOperateSymbolInOperatorPriorDic:termElement topElementWithContextSatck:newTopElementWithAnalyzeSatck] isEqualToString:@"<"]) {
                break;
            }else {
                newTopElementWithAnalyzeSatck = termElement;
            }
        }
    }
    
    for (++top; top < [analyzeStack count]; top++) {
        [experssionChar appendString:analyzeStack[top]];
    }

//    if ([self currentCharIsNonTerminalSymbol:[analyzeStack lastObject]]) {
//        if (topElementWithAnalyzeSatck == analyzeStack[[analyzeStack count] - 2]) {
//            if ([self currentCharIsNonTerminalSymbol:analyzeStack[[analyzeStack count] - 3]]) {
//                [experssionChar appendFormat:@"%@",[analyzeStack lastObject]];
//                [experssionChar appendFormat:@"%@",analyzeStack[[analyzeStack count] - 2]];
//                [experssionChar appendFormat:@"%@",analyzeStack[[analyzeStack count] - 3]];
//                return experssionChar;
//            }
//        }
//    }
    
    return experssionChar;
}

// 压栈
- (void)pushElementToAnalyzeStack:(NSString *)analyzeElement analyzeStack:(NSMutableArray *)analyzeStack {
    [analyzeStack addObject:analyzeElement];
}

// 移栈
- (void)removeElementFormAnalyeStack:(NSMutableArray *)analyzeStack expersionChar:(NSString *)expersionChar{
    for (int i = 0; i < [expersionChar length]; i++) {
//        NSString *removeElement = [NSString stringWithFormat:@"%c",[expersionChar characterAtIndex:i]];
//        [analyzeStack removeObject:removeElement];
        [analyzeStack removeLastObject]; 
    }
}

- (void)removeElementFormContextStack:(NSMutableArray *)contextSatck {
    [contextSatck removeObjectAtIndex:0];
}

#pragma mark - TableView 操作
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (self.operatorPriorateDataTableView == tableView) {
        return  [[operatorPriorDic allKeys] count];
    }else if (self.operatorPriorateResultWithContextTableView == tableView) {
        return [operatorPriorResultArr count];
    }else {
        return 0;
    }
    
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (self.operatorPriorateDataTableView == tableView) {
        NSString *key = [operatorPriorDic allKeys][row];
        NSDictionary *dic = [operatorPriorDic objectForKey:key];
        
        if( [tableColumn.identifier isEqualToString:@"channels0"] ) {
            return key;
        }else {
            NSString *channelsTitle = tableColumn.title;
            return [dic objectForKey:channelsTitle];
        }
    }else if (self.operatorPriorateResultWithContextTableView == tableView) {
        NSDictionary *analyzeResultDic = [operatorPriorResultArr objectAtIndex:row];
        if([tableColumn.identifier isEqualToString:@"stepsNumber"] ) {
            return [analyzeResultDic objectForKey:@"stepsNumber"];
        }else if([tableColumn.identifier isEqualToString:@"analyzeStack"] ) {
            return [analyzeResultDic objectForKey:@"analyzeStack"];
        }else if([tableColumn.identifier isEqualToString:@"contextStack"] ) {
            return [analyzeResultDic objectForKey:@"contextStack"];
        }else {
            return [analyzeResultDic objectForKey:@"analyzeResult"];
        }
    }else {
        return nil;
    }
}


#pragma mark - 私有公共函数
// 获取 表达式 非终结符 语气表达式分离的 基础数据
- (NSDictionary *)gainBaseCollectionDataBySeparateVT:(NSString *)fileContext {
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


// 按行截取文件内容
- (NSArray *)separateFileContextWithRow:(NSString *)separateString {
    NSArray *fileInfoArr = [separateString componentsSeparatedByString:@"\r\n"];
    return fileInfoArr;
}

// 分离数据（依据：-> 和 |）
- (NSArray *)separateCollection:(NSString *)rowContext {
    // 先根据 -> 分离 起始符
    NSArray *arrowHeadArr = [rowContext componentsSeparatedByString:@"->"];
    NSArray *orSignalsArr = [arrowHeadArr[1] componentsSeparatedByString:@"|"];
    
    return @[arrowHeadArr[0], orSignalsArr];
}

// 判断当前字符是不是非终结符（关键字）， 是非终结符返回YES ，否则返回NO
- (BOOL)currentCharIsNonTerminalSymbol:(NSString *)currentChar{
    BOOL isKey = NO;
    for (NSString *key in nonTerminalSymbols) {
        if ([key isEqualToString:currentChar]) {
            isKey = YES;
            break;
        }
    }
    return isKey;
}

- (NSString *)arrayToString:(NSArray *)arr {
    // 对数据进行处理
    NSMutableString *allValue = [NSMutableString string];
    for (NSString *value in arr) {
        [allValue appendFormat:@"%@", value];
    }
    
    return allValue;
}




@end
