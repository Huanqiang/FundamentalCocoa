//
//  TransformNFAToDFA.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/5/19.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "TransformNFAToDFA.h"
#import "NFAObject.h"
#import "DFAObject.h"

@interface TransformNFAToDFA () {
    NSMutableArray *nfaProcessSteps;
    NSInteger nfaSerial;
    int topOfRegularExp;
    NSInteger nfaInWay;
    NSInteger nfaOutWay;
    
    NSMutableArray *dfaProcessSteps;
    NSMutableArray *dfaStateCollectionList;
    NSArray *varchList;
    NSInteger dfaSerial;
    NSMutableArray *dfaEndStateCollection;
    NSMutableArray *dfaNonEndStateCollection;
    
    NSMutableArray *minDFAProcessSteps;
}

@property (weak) IBOutlet NSTextField *regularExpressionTextField;
@property (weak) IBOutlet NSTableView *nFAInfoTableView;
@property (weak) IBOutlet NSTableView *dFAInfoTableView;
@property (weak) IBOutlet NSTableView *minDFAInfoTableView;
@property (weak) IBOutlet NSTextField *nfaStartStateCollectionLabel;
@property (weak) IBOutlet NSTextField *nfaEndStateCollectionLabel;
@property (weak) IBOutlet NSTextField *dfaStartStateCollectionLabel;
@property (weak) IBOutlet NSTextField *dfaEndStateCollectionLabel;
@property (weak) IBOutlet NSTextField *minDFAStartStateCollectionLabel;
@property (weak) IBOutlet NSTextField *minDFAEndStateCollectionLabel;

@end

@implementation TransformNFAToDFA

- (void)windowDidLoad {
    [super windowDidLoad];
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}


#pragma mark - 验证正规式
- (IBAction)proveRegularExpression:(id)sender {
    self.regularExpressionTextField.stringValue = [self removeBlank:self.regularExpressionTextField.stringValue];
}

// 去除 空格
- (NSString *)removeBlank:(NSString *)rowContext {
    NSArray *blankOtherArr = [rowContext componentsSeparatedByString:@" "];
    NSMutableString *newRowContext = [NSMutableString string];
    
    for (NSString *otherString in blankOtherArr) {
        [newRowContext appendString:otherString];
    }
    
    return newRowContext;
}

#pragma mark - 正规式 => NFA
- (IBAction)tranformRegularExpToNFA:(id)sender {
    // 首先进行变量处理
    nfaProcessSteps = [NSMutableArray array];
    topOfRegularExp = 0;
    nfaSerial = 0; // 一开始就预设两个状态1、2；

    // 正式变换
    NSInteger inWay = 0;
    NSInteger outWay = 0;
    int regularExpLength = (int)[self.regularExpressionTextField.stringValue length];
    while (topOfRegularExp < regularExpLength) {
        [self createSignalNFA:[self gainFirstCharWithRegularExp] outWay:&outWay inWay:&inWay];
    }
    
    // 显示结果
    [self.nFAInfoTableView reloadData];
    self.nfaStartStateCollectionLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)inWay];
    self.nfaEndStateCollectionLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)outWay];
    nfaInWay = inWay;
    nfaOutWay = outWay;
}

// 每次处理一个符号
- (void)createSignalNFA:(NSString *)symbol outWay:(NSInteger *)outWay inWay:(NSInteger *)inWay {
    if ([self isVarchSymbol:symbol]) {
        // 判断是不是输入符号
        [self dealWithVarchSymbol:symbol outWay:outWay inWay:inWay];
    }else if ([self isAsteriskSymbol:symbol]) {
        // 判断是不是星号
        // 做星号的处理
        [self dealWithAsteriskSymbol:outWay inWay:inWay];
    }else if ([self isOrSymbol:symbol]) {
        // 判断是不是或符号（"|"）
        [self dealWithOrSymbol:outWay inWay:inWay];
    }else if ([self isLeftParenthesesSymbol:symbol]) {
        // 判断是不是左括号
        // 如果是左括号 则递归自己
        int regularExpLength = (int)[self.regularExpressionTextField.stringValue length];
        while (topOfRegularExp < regularExpLength) {
            NSString *nextSymbol = [self gainFirstCharWithRegularExp];
            // 遇到右括号才跳出
            if ([self isRightParenthesesSymbol:nextSymbol]) {
                break;
            }else {
                [self createSignalNFA:nextSymbol outWay:outWay inWay:inWay];
            }
        }
    }
}

// ***** 符号处理
// 处理 输入符号
- (void)dealWithVarchSymbol:(NSString *)symbol outWay:(NSInteger *)outWay inWay:(NSInteger *)inWay {
    if ([nfaProcessSteps count] == 0) {
        [self createNfaStepWithSteps:symbol outWay:outWay inWay:inWay];
    }else {
        // 先假设 后一个也是 varch
        while (1) {
            // 先保存一个上一步的InWay，OutWay
            NSInteger oldInWay = *inWay;
            NSInteger oldOutWay = *outWay;
            // 新做符号处理
            [self createNfaStepWithSteps:symbol outWay:outWay inWay:inWay];
            
            if ([self isVarchSymbol:[self gainFirstCharWithRegularExp]]) {
                // 新旧符号做连接
                [self saveNFASteps:[self createSignalNilNfaSteps:oldOutWay inWay:*inWay]];
                // 重新处理新的入口接口
                *inWay = oldInWay;
            }else {
                topOfRegularExp--;
                break;
            }
        }
    }
}

- (void)createNfaStepWithSteps:(NSString *)symbol outWay:(NSInteger *)outWay inWay:(NSInteger *)inWay {
    *inWay = [self createNewSerialNumber];
    *outWay = [self createNewSerialNumber];
    [self saveNFASteps:[self createSignalNfaSteps:symbol outWay:*outWay inWay:*inWay]];
}

// 处理 星号
- (void)dealWithAsteriskSymbol:(NSInteger *)outWay inWay:(NSInteger *)inWay {
    // 首先创建一个从当前的旧接口到新接口的空值的nfa，即：循环线路（原来的出口入口做反）
    [self saveNFASteps:[self createSignalNilNfaSteps:*inWay inWay:*outWay]];
    
    // 创建一个新接口
    NSInteger newInway = [self createNewSerialNumber];
    NSInteger newOutWay = [self createNewSerialNumber];
    // 将原来的出口做新nfa的入口 | 将原来的入口做新nfa的出口
    [self saveNFASteps:[self createSignalNilNfaSteps:*inWay inWay:newInway]];
    [self saveNFASteps:[self createSignalNilNfaSteps:newOutWay inWay:*outWay]];
    [self saveNFASteps:[self createSignalNilNfaSteps:newOutWay inWay:newInway]];
    // 重置新的出入口
    *inWay = newInway;
    *outWay = newOutWay;
}

// 处理 或符号
- (void)dealWithOrSymbol:(NSInteger *)outWay inWay:(NSInteger *)inWay {
    // 先保存一个上一步的InWay，OutWay
    NSInteger oldInWay = *inWay;
    NSInteger oldOutWay = *outWay;
    
    // 在做一次正规式化简操作， 以获取或的另一部分的出入口
    [self createSignalNFA:[self gainFirstCharWithRegularExp] outWay:outWay inWay:inWay];
    NSInteger orInWay = *inWay;
    NSInteger orOutWay = *outWay;

    // 获取新的出入口
    *inWay = [self createNewSerialNumber];
    *outWay = [self createNewSerialNumber];
    
    // 创建连接
    [self saveNFASteps:[self createSignalNilNfaSteps:oldInWay inWay:*inWay]];
    [self saveNFASteps:[self createSignalNilNfaSteps:orInWay inWay:*inWay]];
    [self saveNFASteps:[self createSignalNilNfaSteps:*outWay inWay:oldOutWay]];
    [self saveNFASteps:[self createSignalNilNfaSteps:*outWay inWay:orOutWay]];
}

// 保存操作
- (void)saveNFASteps:(NFAObject *)nfaObject {
    [nfaProcessSteps addObject:nfaObject];
}

// 创建一个传空的nfa状态
- (NFAObject *)createSignalNilNfaSteps:(NSInteger)outWay inWay:(NSInteger)inWay {
    return [self createSignalNfaSteps:@"$" outWay:outWay inWay:inWay];
}

// 创建一个新的nfa状态
- (NFAObject *)createSignalNfaSteps:(NSString *)sybmol outWay:(NSInteger)outWay inWay:(NSInteger)inWay {
    return [[NFAObject alloc] init:inWay outWay:outWay varch:sybmol];
}

// 获取第一个正规式字符
- (NSString *)gainFirstCharWithRegularExp {
    return [NSString stringWithFormat:@"%c", [self.regularExpressionTextField.stringValue characterAtIndex:topOfRegularExp++]];
}

// 返回一个新的序号
- (NSInteger)createNewSerialNumber {
    return ++nfaSerial;
}

// **** 符号判断

// 判断是不是输入符号：即非 (,),*,|
- (BOOL)isVarchSymbol:(NSString *)symbol {
    if (![self isParenthesesSymbol:symbol] && ![self isAsteriskSymbol:symbol] && ![self isOrSymbol:symbol]) {
        return YES;
    }
    return NO;
}

// 判断是不是星号
- (BOOL)isAsteriskSymbol:(NSString *)symbol {
    if ([symbol isEqualToString:@"*"]) {
        return YES;
    }
    return NO;
}

// 判断是不是 |
- (BOOL)isOrSymbol:(NSString *)symbol {
    if ([symbol isEqualToString:@"|"]) {
        return YES;
    }
    return NO;
}

// 判断是不是括号
- (BOOL)isParenthesesSymbol:(NSString *)sybmol {
    if ([self isLeftParenthesesSymbol:sybmol] || [self isRightParenthesesSymbol:sybmol]) {
        return YES;
    }
    return NO;
}

// 判断是不是左括号
- (BOOL)isLeftParenthesesSymbol:(NSString *)sybmol {
    if ([sybmol isEqualToString:@"("]) {
        return YES;
    }
    return NO;
}

// 判断是不是右括号
- (BOOL)isRightParenthesesSymbol:(NSString *)sybmol {
    if ([sybmol isEqualToString:@")"]) {
        return YES;
    }
    return NO;
}

#pragma mark - NFA =>DFA
- (IBAction)tranformNFAToDFA:(id)sender {
    // 变量处理
    dfaProcessSteps = [NSMutableArray array];
    dfaStateCollectionList = [NSMutableArray array];
    dfaSerial = 0;
    dfaEndStateCollection = [NSMutableArray array];
    dfaNonEndStateCollection = [NSMutableArray array];
    // 获取 输入符号列表
    [self gainVarchList];
    
    NSMutableArray *currentStateList = [NSMutableArray arrayWithObject:@(nfaInWay)];
    [self gainNilStateList:nfaInWay nilStateList:currentStateList];
    DFAObject *firstDFAObject = [self createNewDFAObejct:currentStateList];
    [self saveDFAStateName:firstDFAObject];
    [self findNextStateList:firstDFAObject];
    
    // 处理结果
    self.dfaStartStateCollectionLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)firstDFAObject.collectionName];
    self.dfaEndStateCollectionLabel.stringValue = [self gainEndState];
    
    [self gainNewDFAStateList];
    [self.dFAInfoTableView reloadData];
}

- (NSString *)gainEndState {
    NSMutableString *endState = [NSMutableString string];
    for (DFAObject *dfaObject in dfaProcessSteps) {
        if (dfaObject.isEndState) {
            [dfaEndStateCollection addObject:@(dfaObject.collectionName)];
            [endState appendFormat:@"%ld ", (long)dfaObject.collectionName];
        }else {
            [dfaNonEndStateCollection addObject:@(dfaObject.collectionName)];
        }
    }
    
    return endState;
}

- (void)gainNewDFAStateList {
    NSMutableArray *newDFAStateList = [NSMutableArray array];
    
    for (DFAObject *dfaObject in dfaProcessSteps) {
        for (NSString *key in [dfaObject.stateListByVarch allKeys]) {
            NSNumber *value = dfaObject.stateListByVarch[key];
            if (![value isEqualToNumber:@(-1)]) {
                NFAObject *object = [self createSignalNfaSteps:key outWay:[value integerValue] inWay:dfaObject.collectionName];
                [newDFAStateList addObject:object];
            }
        }
    }
    
    dfaProcessSteps = [newDFAStateList copy];
}


- (void)findNextStateList:(DFAObject *)currentDFA {
    // 对于每一个状态列表，都要按所有的输入符号来查找相应的闭包
    for (NSString *varch in varchList) {
        NSMutableArray *stateListByVarch = [NSMutableArray array];
        
        // 找到由输入符号组成的StateList
        for (NSNumber *state in currentDFA.stateList) {
            NFAObject *nfaObject = [self findNFAObjectInProcessSteps:state];
            // 如果nfaObject = nil 说明没有这个入口，就进入下一个循环
            if (nfaObject == nil) {
                continue;
            }
            if ([varch isEqualToString:nfaObject.varch]) {
                [stateListByVarch addObject:@(nfaObject.outWay)];
            }
        }
        
        NSArray *stateListByVarchCopy = [stateListByVarch copy];
        // 当这里处理完了 就进行找空的字符
        for (NSNumber *state in stateListByVarchCopy) {
            [self gainNilStateList:[state integerValue] nilStateList:stateListByVarch];
        }
        
        // 判断这个状态集是不是已经存在于dfaStateCollectionList
        NSInteger isExistName = [self isExistInDFANameList:stateListByVarch];
        if (isExistName == -1) {
            // 如果不存在存在就将产生一个dfa，并将其名字加入到 当前dfa中相应的位置
            DFAObject *dfaObject = [self createNewDFAObejct:stateListByVarch];
            [currentDFA.stateListByVarch setObject:@(dfaObject.collectionName) forKey:varch];
            // 将产生的dfa加入dfa名字列表
            [self saveDFAStateName:dfaObject];
            // 循环产生它的子集
            [self findNextStateList:dfaObject];
            
        }else {
            // 如果存在，就将该名字加入当前dfa的相应的位置
            [currentDFA.stateListByVarch setObject:@(isExistName) forKey:varch];
        }
    }
    [self saveDFASteps:currentDFA];
}

- (NSInteger)isExistInDFANameList:(NSArray *)stateList {
    for (DFAObject *dfa in dfaStateCollectionList) {
        if ([dfa.stateList isEqualToArray:stateList]) {
            return dfa.collectionName;
        }
    }
    return -1;
}

- (NFAObject *)findNFAObjectInProcessSteps:(NSNumber *)inWay {
    for (NFAObject *nfaObjetct in nfaProcessSteps) {
        if ([inWay isEqualToNumber:@(nfaObjetct.inWay)]) {
            return nfaObjetct;
        }
    }
    return nil;
}


// 查找由空字符串成的状态列表
- (void)gainNilStateList:(NSInteger)firstState nilStateList:(NSMutableArray *)nilStateList {
    NSMutableArray *newNilStateList = [nilStateList copy];
    for (NFAObject *nfaObjetct in nfaProcessSteps) {
        // 如果该状态不是当前nfa的入口，就进行下一个循环查找
        if (firstState != nfaObjetct.inWay) {
            continue;
        }
        // 如果nfa 的输入符号不是空，就进入下一个循环
        if (![self isNilSymbol:nfaObjetct.varch]) {
            continue;
        }
        // 判断该状态在状态列表里没有出现过，就加入 nilStateList
        BOOL isExist = NO;
        for (NSNumber *state in newNilStateList) {
            if ([state isEqualToNumber:@(nfaObjetct.outWay)]) {
                isExist = YES;
                break;
            }
        }
        if (!isExist) {
            [nilStateList addObject:@(nfaObjetct.outWay)];
        }
    }
    
//    ![nilStateList isEqualToArray:newNilStateList] || firstState == nfaOutWay
    if (firstState != [[nilStateList lastObject] integerValue]) {
        NSNumber *nextState = nilStateList[[nilStateList indexOfObject:@(firstState)] + 1];
        [self gainNilStateList:[nextState integerValue] nilStateList:nilStateList];
    }
}

// 判断 是不是 空符号
- (BOOL)isNilSymbol:(NSString *)varchSymbol {
    if ([varchSymbol isEqualToString:@"$"]) {
        return YES;
    }
    return NO;
}

// 创建一个新的dfa变量
- (DFAObject *)createNewDFAObejct:(NSArray *)stateList {
    DFAObject *dfaObject = [[DFAObject alloc] init:[self gainNewDFAName] stateList:stateList varchList:varchList];
    for (NSNumber *state in stateList) {
        if ([state isEqualToNumber:@(nfaOutWay)]) {
            dfaObject.isEndState = YES;
            break;
        }
    }
    return dfaObject;
}

- (void)saveDFASteps:(DFAObject *)dfaObject {
    [dfaProcessSteps addObject:dfaObject];
}

- (void)saveDFAStateName:(DFAObject *)dfaObject {
    [dfaStateCollectionList addObject:dfaObject];
}

- (NSInteger)gainNewDFAName {
    return ++dfaSerial;
}



// 获取 输入符号列表
- (void)gainVarchList {
    NSMutableArray *varchArr = [NSMutableArray array];
    int regularExpLength = (int)[self.regularExpressionTextField.stringValue length];
    for (int i = 0; i < regularExpLength; i++) {
        NSString *symbol = [NSString stringWithFormat:@"%c", [self.regularExpressionTextField.stringValue characterAtIndex:i]];
        if ([self isVarchSymbol:symbol]) {
            [varchArr addObject:symbol];
        }
    }
    
    varchList = [NSArray arrayWithArray:varchArr];
}

#pragma mark - DFA最小化
- (IBAction)tranformDFAToMin:(id)sender {
    // 变量处理
    minDFAProcessSteps = [NSMutableArray array];
    
    
}

- (void)minimumDFA:(NSArray *)stateCollection {
    
}












#pragma mark - TableView 操作
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    if (self.nFAInfoTableView == tableView) {
        return [nfaProcessSteps count];
    }else if (self.dFAInfoTableView == tableView){
        return [dfaProcessSteps count];
    }else if (self.minDFAInfoTableView == tableView){
        return [minDFAProcessSteps count];
    }else {
        return 0;
    }
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    if (self.nFAInfoTableView == tableView) {
        return [self gainValueInRow:tableColumn objectList:nfaProcessSteps row:row];
    }else if (self.dFAInfoTableView == tableView){
        return [self gainValueInRow:tableColumn objectList:dfaProcessSteps row:row];
    }else if (self.minDFAInfoTableView == tableView){
        return [self gainValueInRow:tableColumn objectList:minDFAProcessSteps row:row];
    }else {
        return nil;
    }
}

- (NSString *)gainValueInRow:(NSTableColumn *)tableColumn objectList:(NSArray *)objectList row:(NSInteger)row {
    NFAObject *nfaObject = objectList[row];
    
    if ([tableColumn.identifier isEqualToString:@"StartState"]) {
        return [NSString stringWithFormat:@"%ld", (long)nfaObject.inWay];
    }else if ([tableColumn.identifier isEqualToString:@"AcceptSymbol"]) {
        return [NSString stringWithFormat:@"%@", nfaObject.varch];
    }else if ([tableColumn.identifier isEqualToString:@"EndState"]) {
        return [NSString stringWithFormat:@"%ld", (long)nfaObject.outWay];
    }else {
        return nil;
    }
}

@end
