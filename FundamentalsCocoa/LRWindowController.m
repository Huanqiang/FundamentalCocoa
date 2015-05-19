//
//  LRWindowController.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/5/19.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "LRWindowController.h"
#import "FileOperateClass.h"

@interface LRWindowController () {
    NSMutableArray *lrAnalyzeStateGroup;
    NSMutableArray *lrAnalyzeTableInfoList;   // 数组里包含字典  当前状态、后继状态（后继状态是一个子字典，由当前状态  和 所有的字符构成）
    NSArray *nonTerminalSymbolList;
    NSArray *terminialSymbolList;
    NSArray *grammarList;
    NSArray *grammarStateList;
    
    NSMutableArray *analyzeProcessWithSteps;
    NSMutableArray *contextStack;
    NSMutableArray *stateStack;
    NSMutableArray *symbolStack;
}


@property (unsafe_unretained) IBOutlet NSTextView *grammarContextTextView;
@property (unsafe_unretained) IBOutlet NSTextView *grammarStateTextView;
@property (weak) IBOutlet NSTableView *lrAnalyzeTableView;
@property (weak) IBOutlet NSTableView *analyzeProcessTextView;
@property (weak) IBOutlet NSTextField *analyzeContextTextField;
@property (weak) IBOutlet NSTableView *lrAnalyzeStateGroupTableView;

@end

@implementation LRWindowController

- (void)windowDidLoad {
    [super windowDidLoad];
    lrAnalyzeStateGroup = [NSMutableArray array];
    grammarStateList = [NSArray array];
    grammarList = [NSArray array];
    nonTerminalSymbolList = [NSArray array];
    lrAnalyzeTableInfoList = [NSMutableArray array];
    terminialSymbolList = [NSMutableArray array];
    analyzeProcessWithSteps = [NSMutableArray array];
    analyzeProcessWithSteps = [NSMutableArray array];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

#pragma mark - 文件操作
- (IBAction)openFile:(id)sender {
    [[[FileOperateClass alloc] init] openFileWithSelectFolder:self.window gainData:^(NSString *result) {
        self.grammarContextTextView.string = result;
    }];
}

// 确认文法
- (IBAction)suregrammar:(id)sender {
    NSMutableString *newFileContext = [NSMutableString string];
    NSArray *fileContextArr = [self separateFileContextWithRow:self.grammarContextTextView.string];
    for (NSString *rowContext in fileContextArr) {
        NSString *newContext = [self removeBlank:rowContext];
        if (![newContext isEqualToString:@""] && ![newContext isEqualToString:@"\r\n"]) {
            [newFileContext appendString:newContext];
        }
    }
    
    self.grammarContextTextView.string = newFileContext;
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

#pragma mark - 显示状态信息
- (IBAction)showStateInfo:(id)sender {
    NSArray *grammarArr = [self separateContextWithArrow:[self separateFileContextWithRow:self.grammarContextTextView.string]];
    NSMutableString *grammarStr = [NSMutableString string];
    [grammarStr appendFormat:@"0:Z->%c\n", [self.grammarContextTextView.string characterAtIndex:0]];
    
    for (int i = 0; i < [grammarArr count]; i++) {
        [grammarStr appendFormat:@"%d:%@\n", i + 1, grammarArr[i]];
    }
    self.grammarStateTextView.string = grammarStr;
}

// 按行截取文件内容
- (NSArray *)separateFileContextWithRow:(NSString *)separateString {
    NSArray *fileInfoArr = [separateString componentsSeparatedByString:@"\r\n"];
    return fileInfoArr;
}

// 再按剪头截取文件
- (NSArray *)separateContextWithArrow:(NSArray *)fileInfoArr {
    NSMutableArray *fileInfoWithoutArrowArr = [NSMutableArray array];
    for (NSString *rowContext in fileInfoArr) {
        if (![rowContext isEqualToString:@""]) {
            // 先将rowContext 按箭头分出来，提取出非终结符arrowArr[0]和内容符arrowArr[1]
            NSArray *arrowArr = [rowContext componentsSeparatedByString:@"->"];
            if ([arrowArr[1] rangeOfString:@"|"].location != NSNotFound) {
                NSArray *fileInfoWithoutOr = [arrowArr[1] componentsSeparatedByString:@"|"];
                for (NSString *orSymbol in fileInfoWithoutOr) {
                    [fileInfoWithoutArrowArr addObject:[NSString stringWithFormat:@"%@->%@", arrowArr[0], orSymbol]];
                }
            }else {
                [fileInfoWithoutArrowArr addObject:[NSString stringWithFormat:@"%@->%@", arrowArr[0], arrowArr[1]]];
            }
        }
    }
    return fileInfoWithoutArrowArr;
}

#pragma mark - 构造LR分析表
- (IBAction)createLRTable:(id)sender {
    lrAnalyzeTableInfoList = [NSMutableArray array];
    lrAnalyzeStateGroup = [NSMutableArray array];
    // 获取非终结字符 和 终结符的集合
    nonTerminalSymbolList = [self gainNonTerminalSmybolList];
    terminialSymbolList = [self gainTerminalSymbolList];
    // 获取文法状态集合
    [self createGrammarStateList];
    
    // 获取开始的产生式
    NSDictionary *firstGrammarExpression = [grammarStateList firstObject];
    // 找出状态族
    [self lrAnalyzeWithFoundStateGroup:firstGrammarExpression];
    
    // 确定状态族的状态（行为）
    [self foundNextStateForStateGroup];
    
    // 进行数据展示
    [self showLRAnalyzeTableData];
}

// 找出状态族
- (void)lrAnalyzeWithFoundStateGroup:(NSDictionary *)grammarExpression {
    if ([self isLRAnalyzeEndWithFoundStateGroup:grammarExpression]) {
        return ;
    }
    
    NSString *expressionStr = [grammarExpression allValues][0];
    // 获取点（.）后面的第一个字符
    NSString *firstSymbolForExpressionAfterPoint = [self gainFirstSymbolForExpressionAfterPoint:expressionStr];
    
    // 创建单状态族
    NSMutableArray *singleGrammarStateGroup = [NSMutableArray array];
    [singleGrammarStateGroup addObject:grammarExpression];
    // 判断点后面的第一个字符是不是非终结符，是的话将该终结符的产生式（状态）加入当前单状态族
    if ([self isNonTerminalSybmol:firstSymbolForExpressionAfterPoint]) {
        for (NSDictionary *grammarState in grammarStateList) {
            if ([[grammarState allKeys][0] isEqualToString:firstSymbolForExpressionAfterPoint]) {
                [singleGrammarStateGroup addObject:grammarState];
            }
        }
    }
    
    // 将单状态族加入总体状态族
    [lrAnalyzeStateGroup addObject:singleGrammarStateGroup];
    
    // 循环单状态族，找出下一个状态的状态族
    for (NSDictionary *grammarState in singleGrammarStateGroup) {
        NSString *key = [grammarState allKeys][0];
        NSString *value = [grammarState allValues][0];
        [self lrAnalyzeWithFoundStateGroup:@{key: [self movePointToNext:value]}];
    }
}

// 获取点（.）后面的第一个字符
- (NSString *)gainFirstSymbolForExpressionAfterPoint:(NSString *)expressionStr {
    NSArray *arrWithPoint = [expressionStr componentsSeparatedByString:@"."];
    return [NSString stringWithFormat:@"%c", [arrWithPoint[1] characterAtIndex:0]];
}

// 判断是不是非终结符
- (BOOL)isNonTerminalSybmol:(NSString *)sybmol {
    for (NSString *nonTerminal in nonTerminalSymbolList) {
        if ([sybmol isEqualToString:nonTerminal]) {
            return YES;
        }
    }
    return NO;
}

// 将点（.）后移一位
- (NSString *)movePointToNext:(NSString *)expressionStr {
    NSRange pointRange = [expressionStr rangeOfString:@"."];
    NSMutableString *newExpression = [NSMutableString stringWithString:expressionStr];
    [newExpression replaceCharactersInRange:pointRange withString:@""];
    [newExpression insertString:@"." atIndex:pointRange.location + 1];
    return newExpression;
}

// 判断找状态族是否结束
- (BOOL)isLRAnalyzeEndWithFoundStateGroup:(NSDictionary *)currentGrammarState {
    NSString *currentKey = [currentGrammarState allKeys][0];
    NSString *currentValue = [currentGrammarState allValues][0];
    
    // 先判断该产生式是不是已经出现过了
    for (NSArray *singalGrammarStateGroup in lrAnalyzeStateGroup) {
        NSDictionary *firstGrammarState = [singalGrammarStateGroup firstObject];
        NSString *key = [firstGrammarState allKeys][0];
        NSString *value = [firstGrammarState allValues][0];
        if ([key isEqualToString:currentKey] && [value isEqualToString:currentValue]) {
            return YES;
        }
    }
    
    // 再判断 点是不是在最后一个，是的话则结束, 并将该状态加入状态族
    NSUInteger pointLocation = [currentValue rangeOfString:@"."].location;
    if (pointLocation == [currentValue length] - 1) {
        [lrAnalyzeStateGroup addObject:@[currentGrammarState]];
        return YES;
    }
    
    return NO;
}


// 确定状态族的后继状态
- (void)foundNextStateForStateGroup {
    for (int i = 0; i < [lrAnalyzeStateGroup count]; i++) {
        NSArray *currentStateGroup = lrAnalyzeStateGroup[i];
        NSMutableDictionary *currentStateInfo = [NSMutableDictionary dictionaryWithDictionary:@{@"serial": @(i), @"nextStateInfo":@""}];
        NSMutableDictionary *nextStateInfo = [NSMutableDictionary dictionary];
        
        for (NSDictionary *grammarExpression in currentStateGroup) {
            NSDictionary *serialWithGrammarState = [self gainSerialWithGrammarState:grammarExpression];
            if (serialWithGrammarState != nil) {
                for (NSString *key in [serialWithGrammarState allKeys]) {
                    NSString *value = serialWithGrammarState[key];
                    [nextStateInfo setObject:value forKey:key];
                }
            }
        }
        
        [currentStateInfo setValue:nextStateInfo forKey:@"nextStateInfo"];
        [lrAnalyzeTableInfoList addObject:currentStateInfo];
    }
}

// 获取该状态的后继行为
- (NSDictionary *)gainSerialWithGrammarState:(NSDictionary *)grammerState {
    NSString *currentKey = [grammerState allKeys][0];
    NSString *currentValue = [grammerState allValues][0];
    NSMutableString *currentValueWithoutPoint = [NSMutableString stringWithString:currentValue];
    [currentValueWithoutPoint replaceCharactersInRange:[currentValue rangeOfString:@"."] withString:@""];
    
    // 判断点是不是在最后一位，是的话则用R，否则用S
    if ([currentValue rangeOfString:@"."].location == [currentValue length] - 1) {
        NSMutableDictionary *serialWithGrammarState = [NSMutableDictionary dictionary];
        
        for (int i = 0; i < [grammarList count]; i++) {
            NSDictionary *grammarExp = [grammarList objectAtIndex:i];
            NSString *key = [grammarExp allKeys][0];
            NSString *value = [grammarExp allValues][0];
            if ([key isEqualToString:currentKey] && [value isEqualToString:currentValueWithoutPoint]) {
                if (i == 0) {
                    [serialWithGrammarState setObject:@"acc" forKey:@"#"];
                }else {
                    for (NSDictionary *terminal in terminialSymbolList) {
                        [serialWithGrammarState setObject:[NSString stringWithFormat:@"R%@", @(i)] forKey:terminal];
                    }
                }
                break;
            }
        }
        
        return serialWithGrammarState;
    }else {
        currentValue = [self movePointToNext:currentValue];
        for (int i = 0; i < [lrAnalyzeStateGroup count]; i++) {
            NSDictionary *firstGrammarState = [lrAnalyzeStateGroup[i] firstObject];
            NSString *key = [firstGrammarState allKeys][0];
            NSString *value = [firstGrammarState allValues][0];
            if ([key isEqualToString:currentKey] && [value isEqualToString:currentValue]) {
                NSArray *arrWithoutPoint = [currentValue componentsSeparatedByString:@"."];
                NSString *lastSybmolBeforePoint = [NSString stringWithFormat:@"%c", [arrWithoutPoint[0] characterAtIndex:[arrWithoutPoint[0] length] - 1]];
                return @{lastSybmolBeforePoint: [NSString stringWithFormat:@"S%@", @(i)]};
            }
        }
    }
    
    return nil;
}

// 展示LR分析表
- (void)showLRAnalyzeTableData {
    // 删除原有的 TableColumn
    NSArray *tableColumns = [NSArray arrayWithArray:self.lrAnalyzeTableView.tableColumns];
    for (NSTableColumn *tableColumn in tableColumns) {
        [self.lrAnalyzeTableView removeTableColumn:tableColumn];
    }
    
    NSMutableArray *tableColumnTitles = [NSMutableArray array];
    [tableColumnTitles addObjectsFromArray:terminialSymbolList];
    [tableColumnTitles addObjectsFromArray:nonTerminalSymbolList];
    
    // 创建 新的 TableColumn
    for (int i = 0; i < [tableColumnTitles count] + 1; i++) {
        NSTableColumn * channTableColumn = [[NSTableColumn alloc] initWithIdentifier:[NSString stringWithFormat:@"channels%d",i]];
        channTableColumn.minWidth = 20;
        channTableColumn.width = self.lrAnalyzeTableView.frame.size.width / [tableColumnTitles count] + 1;
        if (i != 0) {
            channTableColumn.title = tableColumnTitles[i - 1];
        }else {
            channTableColumn.title = @"序号";
        }
        [self.lrAnalyzeTableView addTableColumn:channTableColumn];
    }
    
    
    [self.lrAnalyzeTableView reloadData];
}

#pragma mark - LR分析
- (IBAction)analyzeLRContext:(id)sender {
    analyzeProcessWithSteps = [NSMutableArray array];
    contextStack = [self gainNeedAnalyzeContext];
    stateStack = [NSMutableArray arrayWithObject:@"0"];
    symbolStack = [NSMutableArray arrayWithObject:@"#"];
    [self saveStepAnalyzeInfo:@"初始状态" analyzeExpression:@""];
    
    int isAnalyzeTrue = [self isLRAnalyzeEnd];
    while (isAnalyzeTrue == 0) {
        // 从分析表中 查找元素
        NSString *currentContext = [self gainFirstValueFormStack:contextStack];
        NSMutableString *nextState = [NSMutableString stringWithFormat:@"%@",[self gainValueFormLRAnalyzeTableInfo:[self gainFirstValueFormStack:stateStack] secKey:currentContext]];
        
        if (![nextState isEqualToString:@""]) {
            if ([nextState hasPrefix:@"S"]) {
                // 说明这个有下一个状态的
                // 保存状态
                [self saveStepAnalyzeInfo:[NSString stringWithFormat:@"%@,%@进栈", nextState, currentContext] analyzeExpression:@""];
                
                // 将 nextState中的下一个状态压栈，状态栈、符号栈压栈，内容栈弹栈
                [self pushToStack:currentContext stack:symbolStack];
                [nextState deleteCharactersInRange:[nextState rangeOfString:@"S"]];
                [self pushToStack:nextState stack:stateStack];
                
                [self removeFirstValueFormStack:contextStack];
                
            }else if ([nextState hasPrefix:@"R"]) {
                // 说明需要归约
                // 首先获取归约的产生式
                [nextState deleteCharactersInRange:[nextState rangeOfString:@"R"]];
                NSDictionary *expressionDic = grammarList[[nextState intValue]];
                NSString *expressionKey = [expressionDic allKeys][0];
                NSString *expressionValue = [expressionDic allValues][0];
                
                // 记录弹出的元素
                NSMutableArray *deletedStates = [NSMutableArray array];
                NSMutableArray *deletedSymbols = [NSMutableArray array];
                
                // 从状态栈、符号栈中弹出与产生式右部相同数量的元素
                for (int i = 0; i < [expressionValue length]; i++) {
                    [deletedStates addObject:[self removeFirstValueFormStack:stateStack]];
                    [deletedSymbols addObject:[self removeFirstValueFormStack:symbolStack]];
                }
                
                // 将产生式左部的非终结符加入符号栈
                [self pushToStack:expressionKey stack:symbolStack];
                
                // 找出 要压栈的非终结符的对应的序号,并压栈
                NSMutableString *stateWithNonTerminal = [NSMutableString stringWithString:[self gainValueFormLRAnalyzeTableInfo:[self gainFirstValueFormStack:stateStack] secKey:[self gainFirstValueFormStack:symbolStack]]];
                [stateWithNonTerminal deleteCharactersInRange:[stateWithNonTerminal rangeOfString:@"S"]];
                [self pushToStack:stateWithNonTerminal stack:stateStack];
                
                // 保存信息
                [self saveStepAnalyzeInfo:[NSString stringWithFormat:@"%@，%@弹栈，%@，%@入栈", [deletedStates componentsJoinedByString:@" "],
                                           [deletedSymbols componentsJoinedByString:@" "],
                                           stateWithNonTerminal,
                                           expressionKey]
                        analyzeExpression:[NSString stringWithFormat:@"%@->%@", expressionKey, expressionValue]];
            }
        }

        isAnalyzeTrue = [self isLRAnalyzeEnd];
    }
    
    
    // 展示数据
    [self.analyzeProcessTextView reloadData];
}

// 判断是否结束
- (int)isLRAnalyzeEnd {
    
    NSString *value = [self gainValueFormLRAnalyzeTableInfo:[self gainFirstValueFormStack:stateStack] secKey:[self gainFirstValueFormStack:contextStack]];
    if ([value isEqualToString:@""]) {
        return -1;// 匹配不成功
    }else if ([value isEqualToString:@"acc"]) {
        return 1;// 成功结束
    }else {
        return 0;// 尚未匹配成功，继续循环
    }
}

- (NSString *)gainValueFormLRAnalyzeTableInfo:(NSString *)mainKey secKey:(NSString *)secKey {
    for (NSDictionary *stateDic in lrAnalyzeTableInfoList) {
        if ([[NSString stringWithFormat:@"%@", stateDic[@"serial"]] isEqualToString:mainKey]) {
            NSDictionary *nextStateInfo = stateDic[@"nextStateInfo"];
            NSString *nextState = nextStateInfo[secKey];
            if (nextState == nil) {
                return @"";
            }else {
                return nextState;
            }
        }
    }
    return @"";
}

// 获取需要分析的字符
- (NSMutableArray *)gainNeedAnalyzeContext {
    NSString *context = self.analyzeContextTextField.stringValue;
    NSMutableArray *contextList = [NSMutableArray array];
                                   
    for (int i = 0; i < [context length]; i++) {
        NSString *currentChar = [NSString stringWithFormat:@"%c",[context characterAtIndex:i]];
        [contextList addObject:currentChar];
    }
    [contextList addObject:@"#"];
    return contextList;
}

// 栈操作
- (void)pushToStack:(NSString *)newValue stack:(NSMutableArray *)stack {
    [stack insertObject:newValue atIndex:0];
}

- (NSString *)removeFirstValueFormStack:(NSMutableArray *)stack {
    NSString *firstValue = [stack firstObject];
    [stack removeObjectAtIndex:0];
    return firstValue;
}

- (NSString *)gainFirstValueFormStack:(NSMutableArray *)stack {
    return [stack firstObject];
}

- (void)saveStepAnalyzeInfo:(NSString *)analyzeValue analyzeExpression:(NSString *)analyzeExpression {
    [analyzeProcessWithSteps addObject:@{@"context":[contextStack componentsJoinedByString:@""],
                                         @"symbol":[[self arrBackFormation:symbolStack] componentsJoinedByString:@""],
                                         @"state":[[self arrBackFormation:stateStack] componentsJoinedByString:@""],
                                         @"analyzeExpression": analyzeExpression,
                                         @"analyzeValue":analyzeValue}];
}



#pragma mark - TableView 操作
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (self.lrAnalyzeTableView == tableView) {
        return  [lrAnalyzeTableInfoList count];
    }else if (self.analyzeProcessTextView == tableView) {
        return [analyzeProcessWithSteps count];
    }else {
        return 0;
    }
    
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (self.lrAnalyzeTableView == tableView) {
        NSDictionary *dic = lrAnalyzeTableInfoList[row];
        
        if( [tableColumn.identifier isEqualToString:@"channels0"] ) {
            return [dic objectForKey:@"serial"];
        }else {
            NSString *channelsTitle = tableColumn.title;
            NSString *value = [[dic objectForKey:@"nextStateInfo"] objectForKey:channelsTitle];
            if (value == nil) {
                return @"";
            }else {
                return value;
            }
        }
    }else if (self.analyzeProcessTextView == tableView) {
        
        NSDictionary *analyzeResultDic = [analyzeProcessWithSteps objectAtIndex:row];
        if([tableColumn.identifier isEqualToString:@"stepsNumber"] ) {
            return [NSString stringWithFormat:@"%@", @(row)];
        }else if([tableColumn.identifier isEqualToString:@"state"] ) {
            return [analyzeResultDic objectForKey:@"state"];
        }else if([tableColumn.identifier isEqualToString:@"symbol"] ) {
            return [analyzeResultDic objectForKey:@"symbol"];
        }else if([tableColumn.identifier isEqualToString:@"context"] ) {
            return [analyzeResultDic objectForKey:@"context"];
        }else if([tableColumn.identifier isEqualToString:@"analyzeExpression"] ) {
            return [analyzeResultDic objectForKey:@"analyzeExpression"];
        }else {
            return [analyzeResultDic objectForKey:@"analyzeValue"];
        }
        
    }else {
        return nil;
    }
    
}



#pragma mark - 私有方法
// 数组倒置
- (NSArray *)arrBackFormation:(NSArray *)stack {
    NSMutableArray *backFormationArr = [NSMutableArray array];
    for (int i = (int)[stack count] - 1; i >= 0; i--) {
        [backFormationArr addObject:stack[i]];
    }
    
    return backFormationArr;
}

// 获取非终结字符的集合
- (NSArray *)gainNonTerminalSmybolList {
    NSArray *grammarArr = [self separateFileContextWithRow:self.grammarContextTextView.string];
    NSMutableArray *nTerminalSymbolList = [NSMutableArray array];
    
    for (NSString *rowContext in grammarArr) {
        if (![rowContext isEqualToString:@""]) {
            [nTerminalSymbolList addObject:[rowContext componentsSeparatedByString:@"->"][0]];
        }
    }
    return nTerminalSymbolList;
}

// 获取终结符结合
- (NSArray *)gainTerminalSymbolList {
    NSArray *grammarArr = [self separateFileContextWithRow:self.grammarContextTextView.string];
    NSMutableArray *terminalSymbolArr = [NSMutableArray array];
    
    for (NSString *rowContext in grammarArr) {
        if (![rowContext isEqualToString:@""]) {
            NSString *expression = [rowContext componentsSeparatedByString:@"->"][1];
            for (int i = 0; i < [expression length]; i++) {
                NSString *currentChar = [NSString stringWithFormat:@"%c", [expression characterAtIndex:i]];
                if (![self isNonTerminalSybmol:currentChar] && ![currentChar isEqualToString:@"|"]) {
                    [terminalSymbolArr addObject:currentChar];
                }
            }
        }
    }
    
    [terminalSymbolArr addObject:@"#"];
    return terminalSymbolArr;
}

// 获取文法状态列表
- (void)createGrammarStateList {
    NSMutableArray *nGrammarStateArr = [NSMutableArray array];
    NSMutableArray *nGrammarArr = [NSMutableArray array];
    
    NSArray *grammarStateArr = [self.grammarStateTextView.string componentsSeparatedByString:@"\n"];
    for (NSString *grammarState in grammarStateArr) {
        if (![grammarState isEqualToString:@""]) {
            NSArray *grammarInfo = [grammarState componentsSeparatedByString:@":"];
            NSArray *grammarInfoWithoutArrow = [grammarInfo[1] componentsSeparatedByString:@"->"];
            [nGrammarArr addObject:@{grammarInfoWithoutArrow[0]: grammarInfoWithoutArrow[1]}];
            [nGrammarStateArr addObject:@{grammarInfoWithoutArrow[0]: [self addPointToGrammarExpression:grammarInfoWithoutArrow[1]]}];
        }
    }
    
    grammarList = nGrammarArr;
    grammarStateList = nGrammarStateArr;
}

// 在文法产生式中加入点
- (NSString *)addPointToGrammarExpression:(NSString *)expression {
    return [NSString stringWithFormat:@".%@", expression];
}

@end
