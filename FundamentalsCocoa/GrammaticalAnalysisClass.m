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
}

@end

@implementation GrammaticalAnalysisClass
@synthesize analyzeResultList;
@synthesize falseList;

// 语法分析主程序
- (void)grammaticalAnalysis:(NSArray *)fileCodeList {
    analyzeResultList = [NSMutableArray array];
    tokenList = [NSArray arrayWithArray:fileCodeList];
    tokenTop = 0;
    falseList = [NSMutableArray array];
    
    [self mainAnalysis];
}


- (void)mainAnalysis {
    [self analyzeHead];

    // 判断下一个字符是不是const、var、begin 是的话进行处理。
    while (tokenTop < [tokenList count]) {
        NSDictionary *tokenDic = [self gainNextToken];
        NSString *token = [tokenDic objectForKey:@"name"];
        if ([token isEqualToString:@"const"]) {
            [self analyzeConst];
        }else if ([token isEqualToString:@"var"]) {
            [self analyzeVar];
        }else if ([token isEqualToString:@"begin"]) {
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
    
    NSDictionary *tokenDic = [self gainNextToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if (![token isEqualToString:@"program"]) {
        [self saveFalseInfo:@"缺少关键字'program'" line:tokenDic];
    }
    
    tokenDic = [self gainNextToken];
    if (![self isIdentifier:tokenDic]) {
        if ([[tokenDic objectForKey:@"name"] isEqualToString:@";"]) {
            [self saveFalseInfo:@"缺少函数名称，请自定义！" line:tokenDic];
            return ;
        }else {
            [self saveFalseInfo:@"函数名称错误，请自定义！" line:tokenDic];
        }
    }else {
        [self saveResultInfo:[NSString stringWithFormat:@"\t本程序函数名是：%@", [tokenDic objectForKey:@"name"]]];
    }
    
    tokenDic = [self gainNextToken];
    token = [tokenDic objectForKey:@"name"];
    if (![token isEqualToString:@";"]) {
        [self saveFalseInfo:@"缺少';'" line:[tokenDic objectForKey:@"rowNumber"]];
    }
}

#pragma mark - 处理静态变量
- (void)analyzeConst {
    [self saveResultInfo:@"开始识别静态变量赋值"];
    int index = 1;
    while (tokenTop < [tokenList count]) {
        [self dealWithSignaConst:index++];
        
        // 判断const函数是否结束
        NSDictionary *tokenDic = [self gainNextToken];
        NSString *token = [tokenDic objectForKey:@"name"];
        [self tokenToPre];
        if ([token isEqualToString:@"var"]) {
            return;
        }
    }
}

// 处理单条赋值语句
- (void)dealWithSignaConst:(int)index {
    if (index != 0) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t开始识别第%d条赋值语句",index]];
    }else {
        [self saveResultInfo:@"\t开始识别赋值语句"];
    }
    
    BOOL isRight = YES;
    NSMutableString *resultInfo = [NSMutableString string];
    
    // 判断是不是自定义的变量；
    NSDictionary *tokenDic = [self gainNextToken];
    if ([self isHalfBakedWithValuation:tokenDic]) { return; } // 赋值语句不完整
    if (![self isIdentifier:tokenDic]) {
        isRight = NO;
        NSString *value = [NSString stringWithFormat:@"%@应该是自定义的变量名称", [tokenDic objectForKey:@"name"]];
        [self saveFalseInfo:value line:tokenDic];
    }
    [resultInfo appendFormat:@"%@",[tokenDic objectForKey:@"name"]];
    
    // 判断 变量名后面是不是接的 :=
    tokenDic = [self gainNextToken];
    if ([self isHalfBakedWithValuation:tokenDic]) { return; } // 赋值语句不完整
    NSString *token = [tokenDic objectForKey:@"name"];
    if (![token isEqualToString:@":="]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，变量名后应该接 := ";
        [self saveFalseInfo:value line:tokenDic];
    }
    [resultInfo appendFormat:@"%@",token];
    
    // 判断所赋的值是不是常量
    tokenDic = [self gainNextToken];
    if ([self isHalfBakedWithValuation:tokenDic]) { return; } // 赋值语句不完整
    if (![self isConstant:tokenDic]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，:= 后应该接常量 ";
        [self saveFalseInfo:value line:tokenDic];
    }
    [resultInfo appendFormat:@"%@",[tokenDic objectForKey:@"name"]];
    
    // 判断是不是分号（本语句结束）
    tokenDic = [self gainNextToken];
    if (![self isSemicolon:tokenDic]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，缺少分号结束";
        [self saveFalseInfo:value line:tokenDic];
        [self tokenToPre];
    }
    
    if (isRight) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t\t成功识别 %@", resultInfo]];
    }
}

// 赋值语句是否完整 不完整返回YES；
- (BOOL)isHalfBakedWithValuation:(NSDictionary *)tokenDic {
    if ([self isSemicolon:tokenDic]) {
        [self saveResultInfo:@"识别结束"];
        [self saveFalseInfo:@"赋值语句不完整" line:tokenDic];
        return YES;
    }
    return NO;
}

#pragma mark - 处理动定义变量
- (void)analyzeVar {
    [self saveResultInfo:@"开始识别定义变量"];
    while (1) {
        
        [self dealWithSignalVar];
        
        // 判断var函数是否结束
        NSDictionary *tokenDic = [self gainNextToken];
        NSString *token = [tokenDic objectForKey:@"name"];
        [self tokenToPre];
        if ([token isEqualToString:@"begin"]) {
            return;
        }
    }
}

// 处理单条定义变量语句
- (void)dealWithSignalVar {
    NSMutableString *resultInfo = [NSMutableString string];
    BOOL isRight = YES;
    // 判断是不是 变量名
    while (1) {
        NSDictionary *tokenDic = [self gainNextToken];
        if (![self isIdentifier:tokenDic]) {
            isRight = NO;
            [self saveFalseInfo:@"var 后面应该是标识符" line:tokenDic];
        }
        [resultInfo appendFormat:@" %@", [tokenDic objectForKey:@"name"]];
        
        tokenDic = [self gainNextToken];
        if ([self isHalfBakedWithValuation:tokenDic]) { return; } // 赋值语句不完整
        NSString *token = [tokenDic objectForKey:@"name"];
        if ([token isEqualToString:@","]) {
            continue;
        }else if ([token isEqualToString:@":"]) {
            break;
        }else {
            isRight = NO;
            [self saveFalseInfo:@"变量名后面只能接：和，" line:tokenDic];
        }
    }
    
    // 判断 是不是变量类型
    NSDictionary *tokenDic = [self gainNextToken];
    if ([self isHalfBakedWithValuation:tokenDic]) { return; } // 赋值语句不完整
    NSString *token = [tokenDic objectForKey:@"name"];
    if (![token isEqualToString:@"integer"] && ![token isEqualToString:@"bool"] && ![token isEqualToString:@"char"] && ![token isEqualToString:@"real"]) {
        isRight = NO;
        [self saveFalseInfo:@"变量说明错误" line:tokenDic];
    }
    if (isRight) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t%@ 是 %@ 类型", resultInfo, token]];
    }
    
    // 判断是不是分号（本语句结束）
    tokenDic = [self gainNextToken];
    if (![self isSemicolon:tokenDic]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，缺少分号结束";
        [self saveFalseInfo:value line:tokenDic];
        [self tokenToPre];
    }
}

#pragma mark - 处理主程序
- (void)analyzeBegin {
    [self saveResultInfo:@"开始识别 Begin 部分"];
    while (tokenTop < [tokenList count]) {
        NSDictionary *tokenDic = [self gainNextToken];
        NSString *token = [tokenDic objectForKey:@"name"];
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
        }else if ([token isEqualToString:@"end"]) {
            // 判断函数处理函数是否结束
            break;
        }else {
            [self tokenToPre];
            [self dealWithExecStatement:@""];
        }
    }
}

- (void)dealWithIf {
    // if函数已经处理了"if"，现在开始处理布尔表达式 （括号在布尔表达式中判断）
    [self saveResultInfo:@"开始处理 if 语句"];
    [self dealWithBooleanExpression];
    
    // 再判断 then，处理执行语句
    NSDictionary *tokenDic = [self gainNextToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if ([token isEqualToString:@"then"]) {
        [self saveResultInfo:@"\t处理 then 部分"];
        [self dealWithExecStatement:@"\t\t"];
    }else {
        [self saveFalseInfo:@"if语句缺少 then 部分" line:tokenDic];
        return ;
    }
    
    // 再判断 else（else可能有，也可能没有）
    tokenDic = [self gainNextToken];
    token = [tokenDic objectForKey:@"name"];
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
    [self dealWithAssignmentExpression:@"\t\t"];
    
    // 判断 to， 处理 算术表达式
    NSDictionary *tokenDic = [self gainNextToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if ([token isEqualToString:@"to"]) {
        [self saveResultInfo:@"\t开始处理 to 部分"];
        [self saveResultInfo:[NSString stringWithFormat:@"\t\t%@",[self dealWithArithmeticExpression]]];
    }else {
        [self saveFalseInfo:@"For 循环缺少 to 部分" line:tokenDic];
    }

    // 判断 do， 处理 执行语句
    tokenDic = [self gainNextToken];
    token = [tokenDic objectForKey:@"name"];
    if ([token isEqualToString:@"do"]) {
        [self saveResultInfo:@"\t开始处理 do 执行语句部分"];
        [self dealWithExecStatement:@"\t\t"];
    }else {
        [self saveFalseInfo:@"For 循环缺少 do 部分" line:tokenDic];
    }
}

- (void)dealWithWhile {
    [self saveResultInfo:@"开始处理 While 循环"];
    // 开始处理布尔表达式 （括号在布尔表达式中判断）
    [self dealWithBooleanExpression];
    
    // 处理do 即执行语句
    NSDictionary *tokenDic = [self gainNextToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if ([token isEqualToString:@"do"]) {
        [self saveResultInfo:@"\t处理 do 部分"];
        [self dealWithExecStatement:@"\t\t"];
    }else {
        [self saveFalseInfo:@"While语句缺少 do 部分" line:tokenDic];
        return ;
    }
}

- (void)dealWithDoWhile {
    [self saveResultInfo:@"开始处理 Do-While 循环"];
    // 处理 do 的执行语句
    [self saveResultInfo:@"\t处理 do 部分"];
    [self dealWithExecStatement:@"\t\t"];
    
    // 处理do 即执行语句
    NSDictionary *tokenDic = [self gainNextToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if ([token isEqualToString:@"while"]) {
        [self saveResultInfo:@"\t处理 while 部分"];
        [self dealWithBooleanExpression];
    }else {
        [self saveFalseInfo:@"Do-While 语句缺少 while 部分" line:tokenDic];
        return ;
    }
}

-  (void)dealWithRepeat {
    [self saveResultInfo:@"开始处理 Repeat 语句"];
    //开始处理 执行语句
    [self saveResultInfo:@"\t处理执行语句部分"];
    [self dealWithExecStatement:@"\t\t"];
    
    // 处理until 即执行语句
    NSDictionary *tokenDic = [self gainNextToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if ([token isEqualToString:@"until"]) {
        [self saveResultInfo:@"\t处理 until 部分"];
        [self dealWithBooleanExpression];
    }else {
        [self saveFalseInfo:@"Repeat 语句缺少 until 部分" line:tokenDic];
        return ;
    }
    
    // 判断是不是分号（本语句结束）
    tokenDic = [self gainNextToken];
    if (![self isSemicolon:tokenDic]) {
        NSString *value = @"在赋值语句中，缺少分号结束";
        [self saveFalseInfo:value line:tokenDic];
        [self tokenToPre];
    }
}

// 处理算术表达式
- (NSString *)dealWithArithmeticExpression {
    NSMutableString *resultInfo = [NSMutableString string];
    
    // 先判断是不是 字符串或字符的赋值，是的话，只获取一个；不是的话，走循环
    NSDictionary *tokenDic = [self gainNextToken];
    if ([self isCharacterString:tokenDic]) {
        [resultInfo appendFormat:@"%@", [tokenDic objectForKey:@"name"]];
    }else {
        while (tokenTop < [tokenList count]) {
            // 判断该字符是不是 标识符（变量）或者 数字常量 或者 运算符
            if ([self isIdentifier:tokenDic] || [self isNumberConstant:tokenDic] || [self isOperate:tokenDic] ) {
                [resultInfo appendFormat:@"%@", [tokenDic objectForKey:@"name"]];
            }else {
                if ([[tokenDic objectForKey:@"name"] isEqualToString:@"("]) {
                    [self tokenToPre];
                    [resultInfo appendString:[self dealWithBooleanExpressionWithBracket]];
                }else {
                    break;
                }
                
            }
            tokenDic = [self gainNextToken];
        }
        [self tokenToPre];
    }
    
    
    
    // 获取算术表达式的最后一个字符进行判断其是不是 标识符 或者 常量
    [self tokenToPre];
    tokenDic = [self gainNextToken];
    if ([self isIdentifier:tokenDic] || [self isNumberConstant:tokenDic] || [self isCharacterString:tokenDic]) {
        return [NSString stringWithFormat:@"%@", resultInfo];
    }else {
        [self saveFalseInfo:[NSString stringWithFormat:@"算术表达式：%@ 错误", resultInfo] line:tokenDic];
        return @"";
    }
    
}

// 处理布尔表达式
- (void)dealWithBooleanExpression {
    [self saveResultInfo:@"\t处理布尔表达式"];
    
    // 先判断 not，有的话再 判断 "（算术表达式）"; 不是的话，直接判断 "（算术表达式）"
    NSDictionary *tokenDic = [self gainNextToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if ([token isEqualToString:@"not"]) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t\tnot部分：%@",[self dealWithBooleanExpressionWithBracket]]];
    }else if ([token isEqualToString:@"("]) {
        [self tokenToPre];
        [self saveResultInfo:[NSString stringWithFormat:@"\t\t%@",[self dealWithBooleanExpressionWithBracket]]];
    }else {
        [self saveFalseInfo:@"布尔表达式缺少 左括号" line:tokenDic];
    }

    // 在判断 是 and 还是 or ，是的话，继续 判断 "（算术表达式）"; 不是的话直接返回
    tokenDic = [self gainNextToken];
    token = [tokenDic objectForKey:@"name"];
    if ([token isEqualToString:@"and"] || [token isEqualToString:@"or"]) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t\t%@部分：%@", token, [self dealWithBooleanExpressionWithBracket]]];
    }else {
        [self tokenToPre];
    }
}

// 处理布尔表达式里的判断 （带括号）
- (NSString *)dealWithBooleanExpressionWithBracket {
    NSString *resultInfo = @"";
    // 处理左括号
    NSDictionary *tokenDic = [self gainNextToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if (![token isEqualToString:@"("]) {
        [self tokenToPre];
        [self saveFalseInfo:@"布尔表达式缺少 左括号" line:tokenDic];
    }
    resultInfo = [self dealWithArithmeticExpression];
    
    // 处理右括号
    tokenDic = [self gainNextToken];
    token = [tokenDic objectForKey:@"name"];
    if (![token isEqualToString:@")"]) {
        [self tokenToPre];
        [self saveFalseInfo:@"布尔表达式缺少 左括号" line:tokenDic];
    }
    
    return resultInfo;
}

// 处理可执行语句
- (void)dealWithExecStatement:(NSString *)retractNum {
    // 判断 是不是简单句（赋值句） 或者 是不是 复合句（这个暂时不做了）
    [self saveResultInfo:[NSString stringWithFormat:@"%@开始处理可执行语句",retractNum]];
    
    NSDictionary *tokenDic = [self gainNextToken];
    NSString *token = [tokenDic objectForKey:@"name"];
    if ([token isEqualToString:@"{"]) {
        while (tokenTop < [tokenList count]) {
            tokenDic = [self gainNextToken];
            token = [tokenDic objectForKey:@"name"];
            // 判断该字符是不是 标识符（变量）是标识符 进行赋值语句处理
            if ([self isIdentifier:tokenDic]) {
                [self tokenToPre];
                [self dealWithAssignmentExpression:retractNum];
            }else if ([token isEqualToString:@"}"]) {
                break;
            }
        }
    }else {
        [self tokenToPre];
        NSDictionary *tokenDic = [self gainNextToken];
        [self tokenToPre];
        // 判断该字符是不是 标识符（变量）是标识符 进行赋值语句处理
        if ([self isIdentifier:tokenDic]) {
            [self dealWithAssignmentExpression:retractNum];
        }
    }

}

// 处理赋值表达式
- (void)dealWithAssignmentExpression:(NSString *)retractNum {
    NSMutableString *resultInfo = [NSMutableString string];
    BOOL isRight = YES;
    
    // 第一个字符是 标识符
    NSDictionary *tokenDic = [self gainNextToken];
    if ([self isHalfBakedWithValuation:tokenDic]) { return; } // 赋值语句不完整
    if (![self isIdentifier:tokenDic]) {
        isRight = NO;
        [self saveFalseInfo:@"赋值表达式缺少 标识符" line:tokenDic];
    }
    [resultInfo appendString:[tokenDic objectForKey:@"name"]];

    // 第二个字符是 :=
    tokenDic = [self gainNextToken];
    if ([self isHalfBakedWithValuation:tokenDic]) { return; } // 赋值语句不完整
    NSString *token = [tokenDic objectForKey:@"name"];
    if (![token isEqualToString:@":="]) {
        isRight = NO;
        [self saveFalseInfo:@"赋值表达式缺少 :=" line:tokenDic];
    }
    [resultInfo appendString:token];
    
    // 处理 算术表达式
    [resultInfo appendString:[self dealWithArithmeticExpression]];
    
    // 判断是不是分号（本语句结束）
    tokenDic = [self gainNextToken];
    if (![self isSemicolon:tokenDic]) {
        isRight = NO;
        NSString *value = @"在赋值语句中，缺少分号结束";
        [self saveFalseInfo:value line:tokenDic];
        [self tokenToPre];
    }
    
    if (isRight) {
        [self saveResultInfo:[NSString stringWithFormat:@"\t%@%@", retractNum, resultInfo]];
    }
}

#pragma mark - 私有工具函数
// 判断是不是自定义变量名称
- (BOOL)isIdentifier:(NSDictionary *)tokenDic {
    if ([[tokenDic objectForKey:@"token"] isEqualToNumber:@(69)]) {
        return YES;
    }else {
        return NO;
    }
}

// 判断是不是 字符常量
- (BOOL)isCharacterString:(NSDictionary *)tokenDic {
    if ([[tokenDic objectForKey:@"token"] isEqualToNumber:@(68)]) {
        return YES;
    }else {
        return NO;
    }
}

// 判断是不是常量
- (BOOL)isConstant:(NSDictionary *)tokenDic {
    NSNumber *tokenNum = [tokenDic objectForKey:@"token"];
    if ([tokenNum isEqualToNumber:@(67)] || [tokenNum isEqualToNumber:@(68)] || [tokenNum isEqualToNumber:@(69)]) {
        return YES;
    }
    return NO;
}

// 判断是不是数字
- (BOOL)isNumberConstant:(NSDictionary *)tokenDic {
    NSNumber *tokenNum = [tokenDic objectForKey:@"token"];
    if ([tokenNum isEqualToNumber:@(67)]) {
        return YES;
    }
    return NO;
}

// 判断是不是运算符
- (BOOL)isOperate:(NSDictionary *)tokenDic {
    NSString *token = [tokenDic objectForKey:@"name"];
    if ([[[CodeTypeClass alloc] init] isBelongsOperatorArray:token] != -1) {
        return YES;
    }
    return NO;
}

// 判断是不是分号
- (BOOL)isSemicolon:(NSDictionary *)tokenDic {
    if ([[tokenDic objectForKey:@"name"] isEqualToString:@";"]) {
        return YES;
    }
    return NO;
}

// 判断是不是比较符号
- (BOOL)isCompareSymbol:(NSDictionary *)tokenDic {
    NSArray *compareSymbolList = @[@">", @"<", @">=", @"<=", @"=", @"<>"];
    NSString *token = [tokenDic objectForKey:@"name"];
    
    for (NSString *key in compareSymbolList) {
        if ([key isEqualToString:token]) {
            return YES;
        }
    }
    
    return NO;
}

// 获取当前的字符
- (NSDictionary *)gainNextToken{
    return [tokenList objectAtIndex:tokenTop++];
}

// 指向下一个字符
- (void)tokenToNext {
    tokenTop ++;
}

// 指向上一个字符
- (void)tokenToPre {
    tokenTop --;
}

- (void)saveFalseInfo:(NSString *)value line:(NSDictionary *)line {
    [falseList addObject:@{@"name":value, @"rowNumber":[line objectForKey:@"rowNumber"]}];
}

- (void)saveResultInfo:(NSString *)value {
    [analyzeResultList addObject:value];
}



@end
