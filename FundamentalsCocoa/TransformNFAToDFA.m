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
#import "MinDFAObject.h"

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
    NSArray *dfaSteps;        // 用于最小化的时候时候
    NSInteger dfaStartState; // 用于最小化的时候时候
    
    NSArray *minDFASteps;
    NSMutableArray *minDFAProcessSteps;
    NSInteger minDFASerial;
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
    nfaSerial = 1; // 一开始就预设状态1；

    // 正式变换
    NSInteger inWay = 1;
    NSInteger outWay = 1;
    int regularExpLength = (int)[self.regularExpressionTextField.stringValue length];
    while (topOfRegularExp < regularExpLength) {
        [self createSignalNFA:[self gainFirstCharWithRegularExp] outWay:&outWay inWay:&inWay];
    }
    
//    [self saveNFASteps:[self createSignalNilNfaSteps:inWay inWay:1]];
//    inWay = 1;
    
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
        // 在递归之前要先保留当前的出入口
        NSInteger oldInWay = *inWay;
        NSInteger oldOutWay = *outWay;
        
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
        
        // 在括号后面要判断有没有星号的存在
        if ([self isAsteriskSymbol:[self gainFirstCharWithRegularExp]]) {
            // 判断是不是星号
            // 做星号的处理
            [self dealWithAsteriskSymbol:outWay inWay:inWay];
        }else {
            topOfRegularExp --;
        }
        
        // 新旧符号做连接
        [self saveNFASteps:[self createSignalNilNfaSteps:*inWay inWay:oldOutWay]];
        // 重新处理新的入口接口
        *inWay = oldInWay;
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
            
            if (topOfRegularExp == [self.regularExpressionTextField.stringValue length]) {
                // 新旧符号做连接
                [self saveNFASteps:[self createSignalNilNfaSteps:*inWay inWay:oldOutWay]];
                // 重新处理新的入口接口
                *inWay = oldInWay;
                break;
            }
            
            if ([self isVarchSymbol:[self gainFirstCharWithRegularExp]]) {
                // 新旧符号做连接
                [self saveNFASteps:[self createSignalNilNfaSteps:*inWay inWay:oldOutWay]];
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
    dfaStartState = firstDFAObject.collectionName;
    self.dfaStartStateCollectionLabel.stringValue = [NSString stringWithFormat:@"%ld", (long)dfaStartState];
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
    
    dfaSteps = [NSArray arrayWithArray:dfaProcessSteps];
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
        if (isExistName == -1 && [stateListByVarch count] != 0) {
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
            // 在判断是否已经存在了，存在了就跳过
            BOOL isExist = NO;
            for (NSString *repeatSybmol in varchArr) {
                if ([repeatSybmol isEqualToString:symbol]) {
                    isExist = YES;
                }
            }
            if (!isExist) {
                [varchArr addObject:symbol];
            }
        }
    }
    
    varchList = [NSArray arrayWithArray:varchArr];
}

#pragma mark - DFA最小化
- (IBAction)tranformDFAToMin:(id)sender {
    // 变量处理
    minDFASerial = 0;
    minDFAProcessSteps = [NSMutableArray array];
    
    [self minimumDFA:dfaNonEndStateCollection];
    [self minimumDFA:dfaEndStateCollection];
    
    
    minDFASteps = [NSArray arrayWithArray:minDFAProcessSteps];
    self.minDFAStartStateCollectionLabel.stringValue = [self gainMinDFAStartState];
    self.minDFAEndStateCollectionLabel.stringValue = [self gainMinDFAEndState];
    [self gainNewMinDFAStateList];
    [self.minDFAInfoTableView reloadData];
}

// 最小化主函数
- (void)minimumDFA:(NSArray *)stateCollection {
    NSMutableArray *repeatedDFAObjects = [NSMutableArray array];
    
    for (int i = 0; i < [stateCollection count]; i++) {
        DFAObject *currentDFA = [self gainDfaObjectInDFASteps:[stateCollection[i] integerValue]];
        // 如果当前DFA和前面的DFA有相同的，就不参与比较
        if ([self isExistInRepeatedDFAs:currentDFA repeatedDFAObjects:repeatedDFAObjects]) {
            continue;
        }
        
        // 创建一个MinDFAObject 并将当前状态加入进来
        MinDFAObject *minDFAObject = [self createMinDFAObject];
        [minDFAObject addObjectToPriStateList:currentDFA.collectionName];
        minDFAObject.isEndState = currentDFA.isEndState;
        
        // 开始比较
        for (int j = i + 1; j < [stateCollection count]; j++) {
            DFAObject *nextDFA = [self gainDfaObjectInDFASteps:[stateCollection[j] integerValue]];
            
            // 判断是不是和当前的DFA相同，相同就加入到当前MinDFA中，同时也加入到repeatedDFAObjects中，以便不参与下一次的比较
            if ([self isEqualToNextDFA:currentDFA nextDFA:nextDFA]) {
                [minDFAObject addObjectToPriStateList:nextDFA.collectionName];
                [repeatedDFAObjects addObject:@(nextDFA.collectionName)];
            }
        }
        
        // 比较完后，将产生的minDFA加入到minDFAProcessSteps中
        [minDFAProcessSteps addObject:minDFAObject];
    }
}

- (BOOL)isExistInRepeatedDFAs:(DFAObject *)dfaObject repeatedDFAObjects:(NSArray *)repeatedDFAObjects {
    for (NSNumber *state in repeatedDFAObjects) {
        if ([state isEqualToNumber:@(dfaObject.collectionName)]) {
            return YES;
        }
    }
    
    return NO;
}


// 判断两个DFA的后继是否相等
- (BOOL)isEqualToNextDFA:(DFAObject *)currentDFA nextDFA:(DFAObject *)nextDFA {
    BOOL isEqual = YES;
    
    for (NSString *varch in varchList) {
        NSInteger finalStateWithCurrentDFA = [self gainNextStateInDFASteps:currentDFA.collectionName varch:varch];
        NSInteger finalStateWithNextDFA = [self gainNextStateInDFASteps:nextDFA.collectionName varch:varch];
        if (finalStateWithCurrentDFA != finalStateWithNextDFA) {
            isEqual = NO;
            break;
        }
    }
    return isEqual;
}

// 获取一个dfa通过一个输入符号的后继
- (NSInteger)gainNextStateInDFASteps:(NSInteger)state varch:(NSString *)varch{
    DFAObject *dfaObject = [self gainDfaObjectInDFASteps:state];
    NSInteger nextState = [dfaObject.stateListByVarch[varch] integerValue];
    if (nextState == -1) {
        return dfaObject.collectionName;
    }else {
        return nextState;
    }
}

// 通过名字获取dfa
- (DFAObject *)gainDfaObjectInDFASteps:(NSInteger)state {
    for (DFAObject *dfaObject in dfaSteps) {
        if (state == dfaObject.collectionName) {
            return dfaObject;
        }
    }
    return nil;
}

- (MinDFAObject *)createMinDFAObject {
    return [[MinDFAObject alloc] initWithName:[self gainMinDFASerial]];
}

- (NSInteger)gainMinDFASerial {
    return ++minDFASerial;
}


- (void)saveMinDFA:(MinDFAObject *)minDFAObejct {
    [minDFAProcessSteps addObject:minDFAObejct];
}


// *** DFA最小化的结果处理
- (NSString *)gainMinDFAStartState {
    MinDFAObject *minDFA = [self findNextMinDFAInProcessSteps:dfaStartState];
    return [NSString stringWithFormat:@"%ld", (long)minDFA.collectionName];
}

- (NSString *)gainMinDFAEndState {
    NSMutableString *minDFAEndState = [NSMutableString string];
    for (MinDFAObject *minDFAObject in minDFASteps) {
        if (minDFAObject.isEndState) {
            [minDFAEndState appendFormat:@"%ld ", (long)minDFAObject.collectionName];
        }
    }
    return minDFAEndState;
}

- (void)gainNewMinDFAStateList {
    NSMutableArray *newMinDFAStateList = [NSMutableArray array];
    MinDFAObject *currentMinDFA = [self findNextMinDFAInProcessSteps:dfaStartState];
    [self findNextStateWithMinDFA:currentMinDFA newMinDFAStateList:newMinDFAStateList];
    
    minDFAProcessSteps = newMinDFAStateList;
}

- (void)findNextStateWithMinDFA:(MinDFAObject *)currentMinDFA newMinDFAStateList:(NSMutableArray *)newMinDFAStateList {
    // 找到当前的MinDFA的priState集中的第一个元素
    NSInteger currentDFAState = [[currentMinDFA.priStateList firstObject] integerValue];
    
    
    for (NFAObject *dfaStep in dfaProcessSteps) {
        if (dfaStep.inWay == currentDFAState) {
            
            BOOL isIncurrentDFA = NO;
            for (NSNumber *state in currentMinDFA.priStateList) {
                if ([state isEqualToNumber:@(dfaStep.outWay)]) {
                    isIncurrentDFA = NO;
                    break;
                }
            }
            
            if (isIncurrentDFA) {
                continue;
            }
            
            // 找到nextDFA状态所处的MinDFA
            MinDFAObject *nextMinDFA = [self findNextMinDFAInProcessSteps:dfaStep.outWay];
            // 将该MinDFA加入到
            NFAObject *object = [self createSignalNfaSteps:dfaStep.varch outWay:nextMinDFA.collectionName inWay:currentMinDFA.collectionName];
            
            // 如果有重复的，排除掉
            BOOL isDealed = NO;
            for (NFAObject *dealedObject in newMinDFAStateList) {
                if ([dealedObject.varch isEqualToString:object.varch] && dealedObject.inWay == object.inWay && dealedObject.outWay == object.outWay) {
                    isDealed = YES;
                }
            }
            
            if (!isDealed) {
                [newMinDFAStateList addObject:object];
                
                // 开始递归，（将 nextDFA 转换成新的 currentDFA）
                [self findNextStateWithMinDFA:nextMinDFA newMinDFAStateList:newMinDFAStateList];
            }
        }
    }
}

// 找到DFA状态所处的MinDFA
- (MinDFAObject *)findNextMinDFAInProcessSteps:(NSInteger)dfaState {
    for (MinDFAObject *minDFA in minDFASteps) {
        for (NSNumber *priState in minDFA.priStateList) {
            if ([priState isEqualToNumber:@(dfaState)]) {
                return minDFA;
            }
        }
    }
    return nil;
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
