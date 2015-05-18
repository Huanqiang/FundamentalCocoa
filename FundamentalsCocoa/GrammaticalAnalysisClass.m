//
//  GrammaticalAnalysisClass.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/22.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "GrammaticalAnalysisClass.h"
#import "FileOperateClass.h"
#import "CodeTypeClass.h"

@interface GrammaticalAnalysisClass() {
    NSArray *tokenList;
    NSUInteger tokenTop;
    
    NSInteger temporaryVarIndex;
    NSMutableArray *rightSemanticQuaternionList;
    NSMutableArray *falseSemanticQuaternionList;
}

@end

@implementation GrammaticalAnalysisClass
@synthesize analyzeResultList;
@synthesize symbolAnalyzeResultList;
@synthesize falseList;
@synthesize quaternionList;

// 语法分析主程序
- (void)grammaticalAnalysis:(NSArray *)fileCodeList symbolInfoList:(NSArray *)symbolInfoList{
    quaternionList = [NSMutableArray array];
    analyzeResultList = [NSMutableArray array];
    symbolAnalyzeResultList = [NSMutableArray arrayWithArray:symbolInfoList];
    tokenList = [NSArray arrayWithArray:fileCodeList];
    tokenTop = 0;
    temporaryVarIndex = 0;
    falseList = [NSMutableArray array];
    
    [self mainAnalysis];
}


- (void)mainAnalysis {
    [self analyzeHead];

    // 判断下一个字符是不是const、var、begin 是的话进行处理。
    while (tokenTop < [tokenList count]) {
        NSString *token = [self gainNextToken];
        if ([token isEqualToString:@"const"]) {
            [self analyzeConst];
        }else if ([token isEqualToString:@"var"]) {
            [self analyzeVar];
        }else if ([token isEqualToString:@"begin"]) {
            [self saveResultInfo:@"开始识别 Begin 部分"];
            [self analyzeBegin];
        }else if ([token isEqualToString:@"."]){
            break;
        }
    }
    
    [self saveResultInfo:@"程序分析结束"];
}


#pragma mark - 处理判断头部
- (void)analyzeHead {
    // 记录识别信息
    [self saveResultInfo:@"开始识别头部"];
    
    NSString *token = [self gainNextToken];
    if (![token isEqualToString:@"program"]) {
        [self saveFalseInfo:@"缺少关键字'program'"];
    }
    
    token = [self gainNextToken];
    if (![self isIdentifier]) {
        if ([token isEqualToString:@";"]) {
            [self saveFalseInfo:@"缺少函数名称，请自定义！"];
            return ;
        }else {
            [self saveFalseInfo:@"函数名称错误，请自定义！"];
        }
    }else {
        [self saveResultInfo:[NSString stringWithFormat:@"\t本程序函数名是：%@", token]];
    }
    
    token = [self gainNextToken];
    if (![token isEqualToString:@";"]) {
        [self saveFalseInfo:@"缺少';'"];
    }
}

#pragma mark - 处理静态变量
- (void)analyzeConst {
    [self saveResultInfo:@"开始识别静态变量赋值"];
    int index = 1;
    while (tokenTop < [tokenList count]) {
        [self dealWithSignaConst:index++];
        
        // 判断const函数是否结束
        NSString *token = [self gainNextToken];
        [self tokenToPre];
        if ([token isEqualToString:@"var"]) {
            return;
        }
    }
}

// 处理单条赋值语句
- (void)dealWithSignaConst:(int)index {
    NSMutableDictionary *signalConst = [NSMutableDictionary dictionaryWithDictionary:@{@"value": @"", @"name": @""}];
    
    if (index != 0) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t开始识别第%d条赋值语句",index]];
    }else {
        [self saveResultInfo:@"\t开始识别赋值语句"];
    }
    
    BOOL isRight = YES;
    NSMutableString *resultInfo = [NSMutableString string];
    
    // 判断是不是自定义的变量；
    NSString *token = [self gainNextToken];
    if ([self isHalfBakedWithValuation]) { return; } // 赋值语句不完整
    if (![self isIdentifier]) {
        isRight = NO;
        NSString *value = [NSString stringWithFormat:@"%@应该是自定义的变量名称", token];
        [self saveFalseInfo:value];
    }else {
        [signalConst setObject:token forKey:@"name"];
    }
    [resultInfo appendFormat:@"%@",token];
    
    // 判断 变量名后面是不是接的 :=
    token = [self gainNextToken];
    if ([self isHalfBakedWithValuation]) { return; } // 赋值语句不完整
    if (![token isEqualToString:@":="]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，变量名后应该接 := ";
        [self saveFalseInfo:value];
    }
    [resultInfo appendFormat:@"%@",token];
    
    // 判断所赋的值是不是常量
    token = [self gainNextToken];
    if ([self isHalfBakedWithValuation]) { return; } // 赋值语句不完整
    if (![self isConstant]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，:= 后应该接常量 ";
        [self saveFalseInfo:value];
    }else {
        [signalConst setObject:token forKey:@"value"];
    }
    [resultInfo appendFormat:@"%@",token];
    
    // 判断是不是分号（本语句结束）
    token = [self gainNextToken];
    if (![self isSemicolon]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，缺少分号结束";
        [self saveFalseInfo:value];
        [self tokenToPre];
    }
    
    if (isRight) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t\t成功识别 %@", resultInfo]];
        [self saveSymbolList:signalConst];
    }
}

// 赋值语句是否完整 不完整返回YES；
- (BOOL)isHalfBakedWithValuation{
    if ([self isSemicolon]) {
        [self saveResultInfo:@"识别结束"];
        [self saveFalseInfo:@"赋值语句不完整"];
        return YES;
    }
    return NO;
}

#pragma mark - 处理动定义变量
- (void)analyzeVar {
    [self saveResultInfo:@"开始识别定义变量"];
    while (1) {
        
        [self dealWithSignalVar];
        
        // 判断 var 函数是否结束
        NSString *token = [self gainNextToken];
        [self tokenToPre];
        if ([token isEqualToString:@"begin"]) {
            return;
        }
    }
}

// 处理单条定义变量语句
- (void)dealWithSignalVar {
    NSMutableDictionary *signalVar = [NSMutableDictionary dictionaryWithDictionary:@{@"value": @"", @"name": @"", @"type": @""}];
    NSMutableArray *varNameList = [NSMutableArray array];
    
    NSMutableString *resultInfo = [NSMutableString string];
    BOOL isRight = YES;
    // 判断是不是 变量名
    while (1) {
        NSString *token = [self gainNextToken];
        if (![self isIdentifier]) {
            isRight = NO;
            [self saveFalseInfo:@"var 后面应该是标识符"];
        }
        [varNameList addObject:[token copy]];
        [resultInfo appendFormat:@" %@", token];
        
        token = [self gainNextToken];
        if ([self isHalfBakedWithValuation]) { return; } // 赋值语句不完整
        if ([token isEqualToString:@","]) {
            continue;
        }else if ([token isEqualToString:@":"]) {
            break;
        }else {
            isRight = NO;
            [self saveFalseInfo:@"变量名后面只能接：和，"];
        }
    }
    
    // 判断 是不是变量类型
    NSString *token = [self gainNextToken];
    if ([self isHalfBakedWithValuation]) { return; } // 赋值语句不完整
    if (![token isEqualToString:@"integer"] && ![token isEqualToString:@"bool"] && ![token isEqualToString:@"char"] && ![token isEqualToString:@"real"]) {
        isRight = NO;
        [self saveFalseInfo:@"变量说明错误"];
    }
    signalVar[@"type"] = token;
    
    if (isRight) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t%@ 是 %@ 类型", resultInfo, token]];
        
        for (NSString *varName in varNameList) {
            signalVar[@"name"] = varName;
            [self saveSymbolList:signalVar];
        }
    }
    
    // 判断是不是分号（本语句结束）
    token = [self gainNextToken];
    if (![self isSemicolon]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，缺少分号结束";
        [self saveFalseInfo:value];
        [self tokenToPre];
    }
}

#pragma mark - 处理主程序
- (void)analyzeBegin {
    
    while (tokenTop < [tokenList count]) {
        NSString *token = [self gainNextToken];
        if ([token isEqualToString:@"end"]) {
            // 判断函数处理函数是否结束
            break;
        }else {
            rightSemanticQuaternionList = [NSMutableArray array];
            falseSemanticQuaternionList = [NSMutableArray array];
            [self tokenToPre];
            [self selectOperater:@""];
        }
    }
}

- (void)selectOperater:(NSString *)retractNum {
    NSString *token = [self gainNextToken];
    if ([token isEqualToString:@"if"]) {
        [self dealWithIf];
    }else if ([token isEqualToString:@"for"]) {
        [self dealWithFor];
    }else if ([token isEqualToString:@"while"]) {
        [self dealWithWhile];
    }else if ([token isEqualToString:@"do"]) {
        [self dealWithDoWhile];
    }else if ([token isEqualToString:@"repeat"]) {
        [self dealWithRepeat];
    }else {
        [self tokenToPre];
        [self dealWithExecStatement:retractNum];
    }
}

- (void)dealWithIf {
    // if函数已经处理了"if"，现在开始处理布尔表达式 （括号在布尔表达式中判断）
    [self saveResultInfo:@"开始处理 if 语句"];
    [self dealWithBooleanExpression];
    
    // 再判断 then，处理执行语句
    NSString *token = [self gainNextToken];
    if ([token isEqualToString:@"then"]) {
        [self saveResultInfo:@"\t处理 then 部分"];
        [self selectOperater:@"\t\t"];
    }else {
        [self saveFalseInfo:@"if语句缺少 then 部分"];
        return ;
    }
    
    // 再判断 else（else可能有，也可能没有）
    token = [self gainNextToken];
    if ([token isEqualToString:@"else"]) {
        [self saveResultInfo:@"\t处理 else 部分"];
        [self dealWithExecStatement:@"\t\t"];
    }else {
        [self tokenToPre];
    }
}

- (void)dealWithFor {
    [self saveResultInfo:@"开始处理 For 循环"];
    // 一开始 一定是 "标识符 := 算术表达式 "
    [self saveResultInfo:@"\t开始处理标识符赋值"];
//    [self dealWithAssignmentExpression:@"\t\t"];
    
    NSMutableString *resultInfo = [NSMutableString string];
    BOOL isRight = YES;
    // 第一个字符是 标识符
    NSString *token = [self gainNextToken];
    if ([self isHalfBakedWithValuation]) { return; } // 赋值语句不完整
    if (![self isIdentifier]) {
        isRight = NO;
        [self saveFalseInfo:@"赋值表达式缺少 标识符"];
    }
    [resultInfo appendString:token];
    
    // 第二个字符是 :=
    token = [self gainNextToken];
    if ([self isHalfBakedWithValuation]) { return; } // 赋值语句不完整
    if (![token isEqualToString:@":="]) {
        isRight = NO;
        [self saveFalseInfo:@"赋值表达式缺少 :="];
    }
    [resultInfo appendString:token];
    
    // 处理 算术表达式
    NSString *temporaryVar = @"";
    [resultInfo appendString:[self dealWithArithmeticExpression:&temporaryVar]];
    if (isRight) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t\t\t%@",resultInfo]];
    }
    
    // 判断 to， 处理 算术表达式
    token = [self gainNextToken];
    if ([token isEqualToString:@"to"]) {
        [self saveResultInfo:@"\t开始处理 to 部分"];
        NSString *nilString = @"";
        [self saveResultInfo:[NSString stringWithFormat:@"\t\t%@",[self dealWithArithmeticExpression:&nilString]]];
    }else {
        [self saveFalseInfo:@"For 循环缺少 to 部分"];
    }

    // 判断 do， 处理 执行语句
    token = [self gainNextToken];
    if ([token isEqualToString:@"do"]) {
        [self saveResultInfo:@"\t开始处理 do 执行语句部分"];
        [self selectOperater:@"\t\t"];
    }else {
        [self saveFalseInfo:@"For 循环缺少 do 部分"];
    }
}

- (void)dealWithWhile {
    [self saveResultInfo:@"开始处理 While 循环"];
    // 开始处理布尔表达式 （括号在布尔表达式中判断）
    [self dealWithBooleanExpression];
    
    // 处理do 即执行语句
    NSString *token = [self gainNextToken];
    if ([token isEqualToString:@"do"]) {
        [self saveResultInfo:@"\t处理 do 部分"];
        [self selectOperater:@"\t\t"];
    }else {
        [self saveFalseInfo:@"While语句缺少 do 部分"];
        return ;
    }
}

- (void)dealWithDoWhile {
    [self saveResultInfo:@"开始处理 Do-While 循环"];
    // 处理 do 的执行语句
    [self saveResultInfo:@"\t处理 do 部分"];
    [self selectOperater:@"\t\t"];
    
    // 处理do 即执行语句
    NSString *token = [self gainNextToken];
    if ([token isEqualToString:@"while"]) {
        [self saveResultInfo:@"\t处理 while 部分"];
        [self dealWithBooleanExpression];
    }else {
        [self saveFalseInfo:@"Do-While 语句缺少 while 部分"];
        return ;
    }
}

-  (void)dealWithRepeat {
    [self saveResultInfo:@"开始处理 Repeat 语句"];
    //开始处理 执行语句
    [self saveResultInfo:@"\t处理执行语句部分"];
    [self selectOperater:@"\t\t"];
    
    // 处理until 即执行语句
    NSString *token = [self gainNextToken];
    if ([token isEqualToString:@"until"]) {
        [self saveResultInfo:@"\t处理 until 部分"];
        [self dealWithBooleanExpression];
    }else {
        [self saveFalseInfo:@"Repeat 语句缺少 until 部分"];
        return ;
    }
    
    // 判断是不是分号（本语句结束）
    token = [self gainNextToken];
    if (![self isSemicolon]) {
        NSString *value = @"在赋值语句中，缺少分号结束";
        [self saveFalseInfo:value];
        [self tokenToPre];
    }
}

#pragma mark - 处理算术表达式
- (NSMutableString *)dealWithArithmeticExpression:(NSString **)result {
    NSMutableString *resultInfo = [NSMutableString string];
    NSString *term1 = @"";
    NSString *term2 = @"";
    
    // 处理乘除
    [resultInfo appendString:[self dealWithMulAndDivArithmeticExpression: &term1]];
    
    while (1) {
        NSString *token = [self gainNextToken];
        if ([token isEqualToString:@"+"] || [token isEqualToString:@"-"]) {
            [resultInfo appendString:token];
            // 调用乘除运算
            [resultInfo appendString:[self dealWithMulAndDivArithmeticExpression: &term2]];
            
            // 四元式 处理
            NSString *temporaryVar = [self gainNewTemporaryVar];
            NSDictionary *quaternion = [self gainNewQuaternion:token arg1:term1 arg2:term2 result:temporaryVar];
            [self saveQuaternionToList:quaternion];
            // term 处理
            term1 = temporaryVar;
        }else {
            *result = [term1 copy];
            [self tokenToPre];
            break;
        }
    }
    
    
    return resultInfo;
}

// 处理 乘除
- (NSMutableString *)dealWithMulAndDivArithmeticExpression:(NSString **)term {
    NSMutableString *resultInfo = [NSMutableString string];
    NSString *fac1 = @"";
    NSString *fac2 = @"";
    
    [resultInfo appendString:[self dealWithBaseArithmeticExpressionWithBracket: &fac1]];
    while (1) {
        NSString *token = [self gainNextToken];
        if ([token isEqualToString:@"*"] || [token isEqualToString:@"/"]) {
            [resultInfo appendString:token];
            // 调用基础运算
            [resultInfo appendString:[self dealWithBaseArithmeticExpressionWithBracket: &fac2] ];
            
            // 四元式处理
            NSString *temporaryVar = [self gainNewTemporaryVar];
            NSDictionary *quaternion = [self gainNewQuaternion:token arg1:fac1 arg2:fac2 result:temporaryVar];
            [self saveQuaternionToList:quaternion];
            // term 处理
            fac1 = temporaryVar;
        }else {
            *term = [fac1 copy];
            [self tokenToPre];
            break;
        }
    }
    
    return resultInfo;
}

// 处理算术表达式里的括号的判断
- (NSMutableString *)dealWithBaseArithmeticExpressionWithBracket:(NSString **)quaElement {
    NSMutableString *resultInfo = [NSMutableString string];
    
    // 处理左括号
    NSString *token = [self gainNextToken];
    if ([token isEqualToString:@"("]) {
        [resultInfo appendString:token];
        
        // 调用算术表达式处理
        [resultInfo appendString:[self dealWithArithmeticExpression: quaElement]];
        
        // 处理右括号
        token = [self gainNextToken];
        if (![token isEqualToString:@")"]) {
            [self tokenToPre];
            [self saveFalseInfo:@"布尔表达式缺少 左括号"];
        }
        
        [resultInfo appendString:token];
    }else if ([token isEqualToString:@"-"]) {
        // 处理单目表达式 取负
        // 调用算术表达式处理
        [resultInfo appendString:[self dealWithArithmeticExpression: quaElement]];
        
    }else if ([self isIdentifier] || [self isNumberConstant] || [self isConstant]) {
        [resultInfo appendString:token];
        *quaElement = [token copy];
    }
    
    return resultInfo;
}

#pragma mark - 处理布尔表达式
- (void)dealWithBooleanExpression {
    [self saveResultInfo:@"\t处理布尔表达式"];
    NSDictionary *booleanDic = @{@"op": @"", @"arg1": @"", @"ar2": @""};

    // 先判断 not，有的话再 判断 "（算术表达式）"; 不是的话，直接判断 "（算术表达式）"
    NSString *token = [self gainNextToken];
    if ([token isEqualToString:@"not"]) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t\tnot部分：%@",[self dealWithBooleanExpressionWithBracket:booleanDic]]];
    }else if ([token isEqualToString:@"("]) {
        // 处理 左括号
        [self tokenToPre];
        [self saveResultInfo:[NSString stringWithFormat:@"\t\t%@",[self dealWithBooleanExpressionWithBracket:booleanDic]]];
    }else {
        [self saveFalseInfo:@"布尔表达式缺少 左括号"];
    }
    
    while (1) {
        // 判断是 and， 是的话，继续 判断 "（算术表达式）";
        NSString *token = [self gainNextToken];
        if ([token isEqualToString:@"and"] || [token isEqualToString:@"or"]) {
            [self saveResultInfo:[NSString stringWithFormat:@"\t\t%@部分：%@", token, [self dealWithBooleanExpressionWithBracket:booleanDic]]];
        }else {
            [self tokenToPre];
            break;
        }
    }
}

- (void)dealWithBooleanExpressionWithNot {
    
}

// 处理布尔表达式里的判断 （带括号）
- (NSString *)dealWithBooleanExpressionWithBracket:(NSDictionary *)booleanDic {
    NSMutableString *resultInfo = [NSMutableString string];
    // 处理左括号
    NSString *token = [self gainNextToken];
    if (![token isEqualToString:@"("]) {
        [self tokenToPre];
        [self saveFalseInfo:@"布尔表达式缺少 左括号"];
    }
    NSString *arithmeticResult = @"";
    [resultInfo appendString:[self dealWithArithmeticExpression:&arithmeticResult]];
    [booleanDic setValue:arithmeticResult forKey:@"arg1"];
    
    // 判断是否为 比较符号
    token = [self gainNextToken];
    if (![self isCompareSymbol]) {
        return resultInfo;
    }else {
        [resultInfo appendString:token];
        [booleanDic setValue:token forKey:@"op"];
    }
    
    // 处理 符号右边
    [resultInfo appendString:[self dealWithArithmeticExpression:&arithmeticResult]];
    [booleanDic setValue:arithmeticResult forKey:@"arg2"];
    
    // 处理右括号
    token = [self gainNextToken];
    if (![token isEqualToString:@")"]) {
        [self tokenToPre];
        [self saveFalseInfo:@"布尔表达式缺少 右括号"];
    }
    
    return resultInfo;
}


#pragma mark - 处理可执行语句
- (void)dealWithExecStatement:(NSString *)retractNum {
    // 判断 是不是简单句（赋值句） 或者 是不是 复合句（这个暂时不做了）
    [self saveResultInfo:[NSString stringWithFormat:@"%@开始处理可执行语句",retractNum]];
    
    NSString *token = [self gainNextToken];
    if ([token isEqualToString:@"{"]) {
        while (tokenTop < [tokenList count]) {
            token = [self gainNextToken];
            // 判断该字符是不是 标识符（变量）是标识符 进行赋值语句处理
            if ([self isIdentifier]) {
                [self tokenToPre];
                [self dealWithAssignmentExpression:retractNum];
            }else if ([token isEqualToString:@"}"]) {
                break;
            }
        }
    }else {
        [self tokenToPre];
        token = [self gainNextToken];
        // 判断该字符是不是 标识符（变量）是标识符 进行赋值语句处理
        if ([self isIdentifier]) {
            [self tokenToPre];
            [self dealWithAssignmentExpression:retractNum];
        }
    }
}

// 处理赋值表达式
- (void)dealWithAssignmentExpression:(NSString *)retractNum {
    NSMutableString *resultInfo = [NSMutableString string];
    BOOL isRight = YES;
    NSString *identifier = @"";
    
    // 第一个字符是 标识符
    NSString *token = [self gainNextToken];
    identifier = [token copy];
    if ([self isHalfBakedWithValuation]) { return; } // 赋值语句不完整
    if (![self isIdentifier]) {
        isRight = NO;
        [self saveFalseInfo:@"赋值表达式缺少 标识符"];
    }
    [resultInfo appendString:token];

    // 第二个字符是 :=
    token = [self gainNextToken];
    if ([self isHalfBakedWithValuation]) { return; } // 赋值语句不完整
    if (![token isEqualToString:@":="]) {
        isRight = NO;
        [self saveFalseInfo:@"赋值表达式缺少 :="];
    }
    [resultInfo appendString:token];
    
    // 处理 算术表达式
    NSString *temporaryVar = @"";
    [resultInfo appendString:[self dealWithArithmeticExpression:&temporaryVar]];
    
    // 判断是不是分号（本语句结束）
    token = [self gainNextToken];
    if (![self isSemicolon]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，缺少分号结束";
        [self saveFalseInfo:value];
        [self tokenToPre];
    }
    
    if (isRight) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t%@%@", retractNum, resultInfo]];
        
        // 产生一个四元式
        NSDictionary *quaternion = [self gainNewQuaternion:@":=" arg1:temporaryVar arg2:@"" result:identifier];
        [self saveQuaternionToList:quaternion];
    }
}

#pragma mark - 私有工具函数
// 判断是不是自定义变量名称
- (BOOL)isIdentifier {
    NSDictionary *tokenDic = [self gainPreToken];
    if ([[tokenDic objectForKey:@"token"] isEqualToNumber:@(69)]) {
        return YES;
    }else {
        return NO;
    }
}

// 判断是不是 字符常量
- (BOOL)isCharacterString {
    NSDictionary *tokenDic = [self gainPreToken];
    if ([[tokenDic objectForKey:@"token"] isEqualToNumber:@(68)]) {
        return YES;
    }else {
        return NO;
    }
}

// 判断是不是 常量
- (BOOL)isConstant {
    NSDictionary *tokenDic = [self gainPreToken];
    NSNumber *tokenNum = [tokenDic objectForKey:@"token"];
    if ([tokenNum isEqualToNumber:@(67)] || [tokenNum isEqualToNumber:@(68)] || [tokenNum isEqualToNumber:@(69)]) {
        return YES;
    }
    return NO;
}

// 判断是不是 数字
- (BOOL)isNumberConstant {
    NSDictionary *tokenDic = [self gainPreToken];
    NSNumber *tokenNum = [tokenDic objectForKey:@"token"];
    if ([tokenNum isEqualToNumber:@(67)]) {
        return YES;
    }
    return NO;
}

// 判断是不是 运算符
- (BOOL)isOperate {
    NSDictionary *tokenDic = [self gainPreToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if ([[[CodeTypeClass alloc] init] isBelongsOperatorArray:token] != -1) {
        return YES;
    }
    return NO;
}

// 判断是不是分号
- (BOOL)isSemicolon {
    NSDictionary *tokenDic = [self gainPreToken];
    if ([[tokenDic objectForKey:@"name"] isEqualToString:@";"]) {
        return YES;
    }
    return NO;
}

// 判断是不是比较符号
- (BOOL)isCompareSymbol {
    NSArray *compareSymbolList = @[@">", @"<", @">=", @"<=", @"=", @"<>"];
    NSString *token = [[self gainPreToken] objectForKey:@"name"];
    
    for (NSString *key in compareSymbolList) {
        if ([key isEqualToString:token]) {
            return YES;
        }
    }
    
    return NO;
}

// 获取当前的字符
- (NSString *)gainNextToken {
    return [[tokenList objectAtIndex:tokenTop++] objectForKey:@"name"];
}

- (NSDictionary *)gainPreToken {
    return [tokenList objectAtIndex:tokenTop - 1];
}

// 指向下一个字符
- (void)tokenToNext {
    tokenTop ++;
}

// 指向上一个字符
- (void)tokenToPre {
    tokenTop --;
}

#pragma mark - 保存输出信息
- (void)saveFalseInfo:(NSString *)value {
    NSDictionary *lineDic = [self gainPreToken];
    [falseList addObject:@{@"name":value, @"rowNumber":[lineDic objectForKey:@"rowNumber"]}];
}

- (void)saveResultInfo:(NSString *)value {
    [analyzeResultList addObject:value];
}

#pragma mark - 字符表处理
- (void)saveSymbolList:(NSDictionary *)signalConst {
    
    // 查找原来的signalConst in SymbolList
    NSDictionary *foundSignalConst = [self foundAndRemoveInSymbolList:[signalConst objectForKey:@"name"]];
    if (foundSignalConst) {
        NSMutableDictionary *priSignalConst = [NSMutableDictionary dictionaryWithDictionary:foundSignalConst];
        NSString *value = [signalConst objectForKey:@"value"];
        if (![value isEqualToString:@""]) {
            [priSignalConst setObject:value forKey:@"value"];
            
            // 删除原来的值数据
            NSDictionary *priValue = [self foundAndRemoveInSymbolList:value];
            [priSignalConst setObject:[priValue objectForKey:@"type"] forKey:@"varType"];
        }else {
            // 值是空的，说明来自于Var的定义变量
            [priSignalConst setObject:[signalConst objectForKey:@"type"] forKey:@"varType"];
        }

        [symbolAnalyzeResultList addObject:priSignalConst];
    }
    
}

- (NSDictionary *)foundAndRemoveInSymbolList:(NSString *)constName {
    for (NSDictionary *keyDic in symbolAnalyzeResultList) {
        NSString *keyName = [keyDic objectForKey:@"name"];
        if ([keyName isEqualToString:constName]) {
            NSDictionary *keyCopy = [keyDic copy];
            [symbolAnalyzeResultList removeObject:keyDic];
            return keyCopy;
        }
    }
    return nil;
}

#pragma mark - 四元式处理
- (void)saveQuaternionToList:(NSDictionary *)quaternionDic {
    
    NSMutableDictionary *quaternionInfo = [NSMutableDictionary dictionaryWithDictionary:quaternionDic];
    // 添加序号
    [quaternionInfo setObject:@([quaternionList count] + 1) forKey:@"serialNumber"];
    
    [quaternionList addObject:quaternionInfo];
}

// 向 四元式中加入 序号
- (NSDictionary *)addSerialNumberToQuaternion:(NSDictionary *)quaternionDic {
    NSMutableDictionary *quaternionInfo = [NSMutableDictionary dictionaryWithDictionary:quaternionDic];
    // 添加序号
    [quaternionInfo setObject:@([quaternionList count] + 1) forKey:@"serialNumber"];
    return quaternionInfo;
}

// 产生一个算术表达式的四元式
- (NSDictionary *)gainNewQuaternion:(NSString *)op arg1:(NSString *)arg1 arg2:(NSString *)arg2 result:(NSString *)result{
    return @{@"op": op, @"arg1": arg1, @"arg2": arg2, @"result": result};
}

// 在 算术表达式中 生成新的临时变量
- (NSString *)gainNewTemporaryVar {
    return [NSString stringWithFormat:@"T%ld", (long)temporaryVarIndex++];
}

// 布尔表达式的 四元式
- (NSDictionary *)gainNewBooleanQuaternion:(NSString *)op arg1:(NSString *)arg1 arg2:(NSString *)arg2 {
    return [self gainNewQuaternion:op arg1:arg1 arg2:arg2 result:0];
}

@end
