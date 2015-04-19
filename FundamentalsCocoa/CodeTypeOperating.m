//
//  CodeTypeOperating.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/8.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "CodeTypeOperating.h"
#import "CodeTypeClass.h"

#define TokenNumer [codeTypeClass.keywordArray count] + [codeTypeClass.operatorArray count] + [codeTypeClass.boundaryRiverArray count]
#define NumberToken TokenNumer + 1
#define CharacterStringToken NumberToken + 1
#define VariableNameToken CharacterStringToken + 1

@interface CodeTypeOperating () {
    CodeTypeClass *codeTypeClass;
}

@end

@implementation CodeTypeOperating
@synthesize tokenArr;
@synthesize symbolArr;
@synthesize falseWordArr;

- (void)dealWithCode:(NSString *)fileContext {
    codeTypeClass = [[CodeTypeClass alloc] init];
    symbolArr = [NSMutableArray array];
    tokenArr = [NSMutableArray array];
    falseWordArr = [NSMutableArray array];
    
    NSArray *fileContextArr = [self fileInfoWithRow:fileContext];
    for (int i = 0; i < [fileContextArr count]; i++) {
        [self dealWithFileOfRow:fileContextArr[i] rowNumber:i];
    }
}

// 按行截取文件内容
- (NSArray *)fileInfoWithRow:(NSString *)fileContext {
    NSArray *fileInfoArr = [fileContext componentsSeparatedByString:@"\n"];
    return fileInfoArr;
}


// 按行处理单词
- (void)dealWithFileOfRow:(NSString *)fileContextAtRow rowNumber:(NSInteger)row {
    for (int i = 0; i < [fileContextAtRow length];) {
        char currentChar = [fileContextAtRow characterAtIndex:i];
        
        // 判断第一个字符的归属(Cagetory)
        if ([codeTypeClass isBelongsNumber:currentChar]) {
            // 判断是不是数字
            i = [self phraseIsNumber:fileContextAtRow index:i row:row];
            
        }else if (currentChar == '\'' || currentChar == '"') {
            // 说明接下来的 是一个字符常量 或者字符串常量
            i = [self phraseIsCharacterString:fileContextAtRow index:i row:row];
            
        }else if ([codeTypeClass isBelongsLetters:currentChar]){
            // 判断是不是字母 （判断接下来的为字符常量 还是 变量名）
            i = [self phraseIsKeyWord:fileContextAtRow index:i row:row];
            
        }else if (currentChar == '_') {
            // 判断是不是 _ （判断 接下来的 为变量名/标识符）
            i = [self phraseIsVariableName:fileContextAtRow index:i row:row];
            
        }else if (currentChar == '/') {
            // 判断是不是 /  (判断接下来的是 注释 还是 只是一个 除号)
            i= [self phraseIsAnnotation:fileContextAtRow index:i row:row];
            
        }else {
            // 处理其他情况 如 界符, 运算符 等
            NSString *currentCharString = [NSString stringWithFormat:@"%c", currentChar];
            if ([codeTypeClass isBelongsBoundaryRiverArray:currentCharString] != -1) {

                NSInteger boundaryRiverIndex = [codeTypeClass isBelongsBoundaryRiverArray:currentCharString];
                NSInteger token = boundaryRiverIndex + [codeTypeClass.keywordArray count] + [codeTypeClass.operatorArray count];
                [self saveToToken:[self createRightWord:currentCharString codeType:token rowNumber:row]];
                
                i++;
            }else if ([codeTypeClass isBelongsOperatorArray:currentCharString] != -1) {
                // 是运算符 则处理保存
                // 运算符要注意下一个字符还是不是运算符，是的话两个一起判断，不是的话保存
                i = [self phraseIsBelongsOperator:fileContextAtRow index:i row:row];
            }else {
                if (![currentCharString isEqualToString:@" "]) {
                    [self saveToFalse:currentCharString rowNumber:row];
                }

                i++;
            }
        }
    }
}

// 当 获取的第一个字符是 数字 的时候
- (int)phraseIsNumber:(NSString *)fileContextOfRow index:(int)index row:(NSInteger)row {
    NSMutableString *phrase = [NSMutableString string];
    for (; index < [fileContextOfRow length]; index++) {
        char currentChar = [fileContextOfRow characterAtIndex:index];
//        if (![codeTypeClass isBelongsNumber:currentChar] && currentChar != 'E' && currentChar != '.') {
//            break;
//        }
        if (![codeTypeClass isBelongsNumber:currentChar]) {
            if (currentChar == 'E' && (index < [fileContextOfRow length])) {
                char nextChar = [fileContextOfRow characterAtIndex:index + 1];
                if (![codeTypeClass isBelongsNumber:nextChar]) {
                    if (nextChar != '-' && nextChar != '+') {
                        break;
                    }else {
                        if (index + 2 < [fileContextOfRow length]) {
                            char nextNextChar = [fileContextOfRow characterAtIndex:index + 2];
                            if ([codeTypeClass isBelongsNumber:nextNextChar]) {
                                [phrase appendFormat:@"%c", currentChar];
                                [phrase appendFormat:@"%c", nextChar];
                                [phrase appendFormat:@"%c", nextNextChar];
                                index +=2;
                            }else {
                                break;
                            }
                        }else {
                            break;
                        }
                    }
                }else {
                    [phrase appendFormat:@"%c", currentChar];
                    [phrase appendFormat:@"%c", nextChar];
                    index += 1;
                }
            }else {
                if (currentChar == '.' && (index != [fileContextOfRow length] - 1)) {
                    char nextChar = [fileContextOfRow characterAtIndex:index + 1];
                    if (![codeTypeClass isBelongsNumber:nextChar]) {
                        break;
                    }else {
                        [phrase appendFormat:@"%c", currentChar];
                        [phrase appendFormat:@"%c", nextChar];
                        index += 1;
                    }
                }else {
                    break;
                }
            }
        }else {
            [phrase appendFormat:@"%c", currentChar];
        }
    }
    
    NSString *numberType;
    if (([phrase rangeOfString:@"."].length == 0) && ([phrase rangeOfString:@"E"].length == 0) ) {
        numberType = @"整型";
    }else {
        numberType = @"浮点型";
    }
    
    // 保存操作
    NSDictionary *numberDic = [self createSymbolWord:phrase token:NumberToken type:numberType];
    [self saveToSymbol:numberDic];
    [self saveToToken:[self createRightWord:phrase codeType:NumberToken rowNumber:row]];
    
    return index;
}


// 当 获取的第一个字符是 '\'' 或者 "\"" (即单引号或者双引号) 的时候
- (int)phraseIsCharacterString:(NSString *)fileContextOfRow index:(int)index row:(NSInteger)row {
    char currentSymbolChar = [fileContextOfRow characterAtIndex:index++];
    NSMutableString *phrase = [NSMutableString stringWithFormat:@"%c",currentSymbolChar];
    
    for (; index < [fileContextOfRow length]; index++) {
        char nextSymbolChar = [fileContextOfRow characterAtIndex:index];
        [phrase appendFormat:@"%c", nextSymbolChar];
        if (currentSymbolChar == nextSymbolChar) {
            index++;
            break;
        }
    }
    
    NSString *charType;
    if (currentSymbolChar == '\'') {
        charType = @"字符常量";
    }else {
        charType = @"字符串常量";
    }
    
    // 保存操作
    [self saveToSymbol:[self createSymbolWord:phrase token:CharacterStringToken type:charType]];
    [self saveToToken:[self createRightWord:phrase codeType:CharacterStringToken rowNumber:row]];
    
    return index;
}

// 当 获取的第一个字符是 字母 的时候
- (int)phraseIsKeyWord:(NSString *)fileContextOfRow index:(int)index row:(NSInteger)row {
    NSMutableString *phrase = [NSMutableString string];
    for (; index < [fileContextOfRow length]; index++) {
        char currentChar = [fileContextOfRow characterAtIndex:index];
        if ([self isPhraseEnd:currentChar]) {
            break;
        }
        [phrase appendFormat:@"%c", currentChar];
    }
    
    NSInteger isKeyWord = [codeTypeClass isKeyWordOrVariate:phrase];
    if (isKeyWord == 1) {
        NSInteger keywordToken = [codeTypeClass isBelongsKeywordArray:phrase];
        [self saveToToken: [self createRightWord:phrase codeType:keywordToken rowNumber:row]];
    } else if(isKeyWord == 2){
        [self saveToSymbol:[self createSymbolWord:phrase token:VariableNameToken type:@"标识符"]];
        [self saveToToken:[self createRightWord:phrase codeType:VariableNameToken rowNumber:row]];
    }
    
    return index;
}


// 当 获取的第一个字符是 '_' 的时候 （当以 '_' 开头的时候，该数组只有可能是 变量名）
- (int)phraseIsVariableName:(NSString *)fileContextOfRow index:(int)index row:(NSInteger)row {
    NSMutableString *phrase = [NSMutableString string];
    for (; index < [fileContextOfRow length]; index++) {
        char currentChar = [fileContextOfRow characterAtIndex:index];
        if ([self isPhraseEnd:currentChar]) {
            break;
        }
        [phrase appendFormat:@"%c", currentChar];
    }
    
    [self saveToToken:[self createRightWord:phrase codeType:VariableNameToken rowNumber:row]];
    [self saveToSymbol:[self createSymbolWord:phrase token:VariableNameToken type:@"标识符"]];
    
    return index;
}


// 当 第一个字符是以 '/' 开头的时候（此时，该数组可能是注释，也可能只是一个 '/'（除号））
- (int)phraseIsAnnotation:(NSString *)fileContextOfRow index:(int)index row:(NSInteger)row {
    char nextChar = [fileContextOfRow characterAtIndex:++index];
    
    if (nextChar == '/') {     // 如果下一个字符是 '/'，表明接下来的整行都是注释
        index = (int)[fileContextOfRow length];
    }else if (nextChar == '*') {
        // 如果下一个字符是 '*'，表明接下来的都是注释 直到遇到下一个 '*/'， 过了本行后不视为注释
        for (++index; index < [fileContextOfRow length]; index++) {
            char currentAnnotationChar = [fileContextOfRow characterAtIndex:index];
            if (index == ([fileContextOfRow length] - 1)) {
                index = (int)[fileContextOfRow length];
                break;
            }
            char currentNextAnnotationChar = [fileContextOfRow characterAtIndex:(index + 1)];
            if (currentAnnotationChar == '*' && currentNextAnnotationChar == '/') {
                index = index + 2;
                // 表示注释结束
                break;
            }
        }
    }else {   // 其余情况均视为 除号
        char currentChar = [fileContextOfRow characterAtIndex:index - 1]; // 获取除号
        
        NSString *divSymbolString = [NSString stringWithFormat:@"%c", currentChar];
        NSInteger dicsymbolToken = [codeTypeClass isBelongsOperatorArray:divSymbolString];
        [self saveToToken:[self createRightWord:divSymbolString codeType:dicsymbolToken rowNumber:row]];

    }
    
    return index;
}


// 当第一个字符是 运算符 的时候， 判断是不是 词组是不是运算符
- (int)phraseIsBelongsOperator:(NSString *)fileContextOfRow index:(int)index row:(NSInteger)row {
    char currentChar = [fileContextOfRow characterAtIndex:index];
    NSString *phrase = [NSString stringWithFormat:@"%c", currentChar];
    if (index != [fileContextOfRow length] - 1) {
        char nextChar = [fileContextOfRow characterAtIndex:++index];
        phrase = [NSString stringWithFormat:@"%c%c", currentChar, nextChar];
    }
    
    
    if ([codeTypeClass isBelongsOperatorArray:phrase] != -1) {
        index++;
        NSInteger operatorToken = [codeTypeClass isBelongsOperatorArray:phrase] + [codeTypeClass.keywordArray count];
        [self saveToToken:[self createRightWord:phrase codeType:operatorToken rowNumber:row]];
    }else {
        
        NSString *operatorString = [NSString stringWithFormat:@"%c", currentChar];
        NSInteger operatorToken = [codeTypeClass isBelongsOperatorArray:operatorString] + [codeTypeClass.keywordArray count];
        [self saveToToken:[self createRightWord:operatorString codeType:operatorToken rowNumber:row]];
    }
    
    return index;
}




// 判断一个词组的结束
// 当这个字符不为 数字、字母、'_' 的时候，表示词组结束
- (BOOL)isPhraseEnd:(char)endChar {
    if ((![codeTypeClass isBelongsLetters:endChar]) && (![codeTypeClass isBelongsNumber:endChar]) && (endChar != '_') ) {
        return YES;
    }
    return NO;
}



#pragma mark - 处理结果
// 创建 正确单词 字典
- (NSDictionary *)createRightWord:(NSString *)wordName codeType:(NSInteger)codeType rowNumber:(NSInteger)row {
    return @{@"name": wordName, @"token": @(codeType), @"rowNumber": @(row + 1)};
}


// 创建 错误单词 （字典）
- (NSDictionary *)createFalseWord:(NSString *)wordName rowNumber:(NSInteger)row {
    return @{@"name": wordName, @"rowNumber": @(row + 1)};
}

// 创建 符号表内容 字典
- (NSDictionary *)createSymbolWord:(NSString *)wordName token:(NSInteger)token type:(NSString *)type {
    if ([type isEqualToString:@"整型"] || [type isEqualToString:@"浮点型"]) {
        return @{@"name": wordName, @"length": @(1), @"token": @(token + 1), @"type": type};
    }
    return @{@"name": wordName, @"length": @([wordName length]), @"token": @(token + 1), @"type": type};
}

// 最后处理操作
- (void)saveToSymbol:(NSDictionary *)symbol {
    if (![symbolArr containsObject:symbol]) {
        [symbolArr addObject:symbol];
    }
}

- (void)saveToToken:(NSDictionary *)token {
//    if (![tokenArr containsObject:token]) {
//        [tokenArr addObject:token];
//    }
    [tokenArr addObject:token];
}

- (void)saveToFalse:(NSString *)wordName rowNumber:(NSInteger)row {
    [falseWordArr addObject:[self createFalseWord:wordName rowNumber:row]];
}


#pragma  mark - 保存信息 至 文件
- (void)saveSymbolToFile {
    [symbolArr writeToFile:[self filePath:@"symbol"] atomically:YES];
}

- (void)saveTokenToFile {
    [tokenArr writeToFile:[self filePath:@"Token"] atomically:YES];
}


- (NSString *)filePath:(NSString *)fileNmae {
    return [NSString stringWithFormat:@"/Users/wanghuanqiang/Desktop/%@.txt", fileNmae];
}
@end
