//
//  CodeTypeOperating.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/8.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "CodeTypeOperating.h"
#import "CodeTypeClass.h"

@interface CodeTypeOperating () {
    CodeTypeClass *codeTypeClass;
    
    NSMutableArray *rightWordArr;
    NSMutableArray *falseWordArr;
}

@end

@implementation CodeTypeOperating


- (void)dealWithCode:(NSString *)fileContext {
    codeTypeClass = [[CodeTypeClass alloc] init];
    rightWordArr = [NSMutableArray array];
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
            i = [self phraseIsNumber:fileContextAtRow index:i];
            
        }else if ([codeTypeClass isBelongsLetters:currentChar]){
            // 判断是不是字母 （判断接下来的为字符常量 还是 变量名）
            i = [self phraseIsKeyWord:fileContextAtRow index:i];
            
        }else if (currentChar == '_') {
            // 判断是不是 _ （判断 接下来的 为变量名/标识符）
            i = [self phraseIsVariableName:fileContextAtRow index:i];
            
        }else if (currentChar == '/') {
            // 判断是不是 /  (判断接下来的是 注释 还是 只是一个 除号)
            i= [self phraseIsAnnotation:fileContextAtRow index:i];
            
        }else {      // 处理其他情况 如 界符, 运算符 等
            NSString *currentCharString = [NSString stringWithFormat:@"%c", currentChar];
            if ([codeTypeClass isBelongsOperatorArray:currentCharString]) {
#warning 是界符 则处理保存
            }else if ([codeTypeClass isBelongsBoundaryRiverArray:currentCharString]) {
                // 是运算符 则处理保存
                // 运算符要注意下一个字符还是不是运算符，是的话两个一起判断，不是的话保存
#warning 未完成；
            }
        }
    }
}

// 当 获取的第一个字符是 数字 的时候
- (int)phraseIsNumber:(NSString *)fileContextOfRow index:(int)index {
    NSMutableString *phrase = [NSMutableString string];
    for (; index < [fileContextOfRow length]; index++) {
        char currentChar = [fileContextOfRow characterAtIndex:index];
        if (![codeTypeClass isBelongsNumber:currentChar]) {
            break;
        }
        [phrase appendFormat:@"%c", currentChar];
    }
    
#warning 保存数字到 Token 表中
    
    return index;
}

// 当 获取的第一个字符是 字母 的时候
- (int)phraseIsKeyWord:(NSString *)fileContextOfRow index:(int)index {
    NSMutableString *phrase = [NSMutableString string];
    for (; index < [fileContextOfRow length]; index++) {
        char currentChar = [fileContextOfRow characterAtIndex:index];
        if ([self isPhraseEnd:currentChar]) {
            break;
        }
        [phrase appendFormat:@"%c", currentChar];
    }
    
    if ([codeTypeClass isKeyWordOrVariate:phrase]) {
#warning/ 保存 关键字 至符号表
//        [self saveToSymbol:<#(NSDictionary *)#>]
    } else {
#warning 保存 变量名称（标识符） 至符号表
    }
    
    return index;
}


// 当 获取的第一个字符是 '_' 的时候 （当以 '_' 开头的时候，该数组只有可能是 变量名）
- (int)phraseIsVariableName:(NSString *)fileContextOfRow index:(int)index {
    NSMutableString *phrase = [NSMutableString string];
    for (; index < [fileContextOfRow length]; index++) {
        char currentChar = [fileContextOfRow characterAtIndex:index];
        if ([self isPhraseEnd:currentChar]) {
            break;
        }
        [phrase appendFormat:@"%c", currentChar];
    }
    
#warning 保存 变量名（标识符）至 Token 表
    return index;
}


// 当 第一个字符是以 '/' 开头的时候（此时，该数组可能是注释，也可能只是一个 '/'（除号））
- (int)phraseIsAnnotation:(NSString *)fileContextOfRow index:(int)index {
    char nextChar = [fileContextOfRow characterAtIndex:++index];
    
    if (nextChar == '/') {     // 如果下一个字符是 '/'，表明接下来的整行都是注释
        index = (int)[fileContextOfRow length];
    }else if (nextChar == '*') {    // 如果下一个字符是 '*'，表明接下来的都是注释 直到遇到下一个 '*/'， 过了本行后不视为注释
        for (; index < [fileContextOfRow length]; index++) {
            char currentChar = [fileContextOfRow characterAtIndex:index];
            if (index == ([fileContextOfRow length] - 1)) {
                index = (int)[fileContextOfRow length];
                break;
            }
            char currentNewxChar = [fileContextOfRow characterAtIndex:index + 1];
            if (currentChar == '*' && currentNewxChar == '/') {
                // 表示注释结束
                break;
            }
        }
    }else {   // 其余情况均视为 除号
#warning 保存除号
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
    return @{@"name": wordName, @"codeType": @(codeType), @"rowNumber": @(row)};
}

- (NSDictionary *)createFalseWord:(NSString *)wordName rowNumber:(NSInteger)row {
    return @{@"name": wordName, @"rowNumber": @(row)};
}

- (void)saveToSymbol:(NSDictionary *)symbol {
    
}

- (void)saveToToken:(NSDictionary *)token {
    
}


@end
