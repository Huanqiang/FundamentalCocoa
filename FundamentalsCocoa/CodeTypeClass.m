//
//  CodeTypeClass.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/8.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "CodeTypeClass.h"

@implementation CodeTypeClass
@synthesize keywordArray;
@synthesize boundaryRiverArray;
@synthesize operatorArray;

- (id)init {
    self = [super init];
    if (self) {
        keywordArray = [NSArray arrayWithObjects:@"program",@"var", @"integer", @"bool", @"real", @"char", @"const", @"begin", @"if",  @"end",@"then", @"else", @"while", @"do", @"repeat", @"until", @"for", @"to", @"not", @"and", @"or", nil];
//        @"auto", @"double", @"int", @"struct", @"break", @"else", @"long", @"switch", @"case", @"enum", @"register", @"typedef",@"char",@"extern", @"return", @"union", @"const", @"float", @"short", @"unsigned", @"continue", @"for", @"signed", @"void", @"default", @"goto", @"sizeof", @"volatile", @"do", @"if", @"while", @"static", nil];
        operatorArray = [NSArray arrayWithObjects:@"+",@"-",@"*",@"/",@"%",@">",@"<",@">=",@"<=",@"==", @"-=",@"+=", @"*=",@"/=",@"!=",@"=",@"%=",@"&",@"&&",@"|",@"||",@"!",@"++",@"--",@"~",@"<<",@">>",@"?:", @"<>", @":=", nil];
        boundaryRiverArray = [NSArray arrayWithObjects: @"{", @"}", @"[", @"]", @";", @",", @".", @"(", @")", @":", @"\"", @"#", @">", @"<", @"\'", nil];
    }
    
    return self;
}

// 判断是不是 关键字
- (NSInteger)isBelongsKeywordArray:(NSString *)keyWord {
    for (NSString *key in keywordArray) {
        if ([key isEqualToString:keyWord]) {
            return [keywordArray indexOfObject:key];
        }
    }

    return -1;
}

// 判断是不是 远算符
- (NSInteger)isBelongsOperatorArray:(NSString *)operatorString {
    for (NSString *key in operatorArray) {
        if ([key isEqualToString:operatorString]) {
            return [operatorArray indexOfObject:key];
        }
    }
    
    return -1;
}

// 判断是不是 界符
- (NSInteger)isBelongsBoundaryRiverArray:(NSString *)boundaryRiverString {
    for (NSString *key in boundaryRiverArray) {
        if ([key isEqualToString:boundaryRiverString]) {
            return [boundaryRiverArray indexOfObject:key];
        }
    }
    
    return -1;
}

// 判断是不是 数字
- (BOOL)isBelongsNumber:(char)number {
    if (isdigit(number)) {
        return YES;
    }
    return NO;
}

// 判断是不是 字母
- (BOOL)isBelongsLetters:(char)letters {
//    char x = [letters characterAtIndex:0];
//    if ((x >= 'a' && x <= 'z') || (x >= 'A' && x <= 'Z')) {
//        return YES;
//    }
    if (isalpha(letters)!= 0) {
        return YES;
    }
    return NO;
}

// 判断是不是 数字常量
- (BOOL)isNumericConstants:(NSString *)numberString {
    BOOL isDig = YES;
    int isDecimalPoint = 0;
    for (int i = 1; i < [numberString length]; i++) {
        // 判断是不是数字
        if (![self isBelongsNumber:[numberString characterAtIndex:i]]) {
            // 判断是不是 小数点
            if ([numberString characterAtIndex:i] == '.') {
                isDecimalPoint ++;
                // 判断小数点个数是不是 只有一个
                if (isDecimalPoint >= 2) {
                    isDig = NO;
                    break;
                }
            }else {
                isDig = NO;
                break;
            }
        }
    }
    
    return isDig;
}

// 判断是不是 字符常量
- (void)isCharConstant:(NSString *)charString {
    
}

// 判断是 关键字(1) 还是 变量名称(2) 还是其他(0)
- (NSInteger)isKeyWordOrVariate:(NSString *)wordString {
    if ([self isBelongsKeywordArray:wordString] == -1) {
        // 如果不是关键字 则 判断是不是 变量名称
        if ([self isVariable:wordString]) {
            return 2;
        }else {
            return 0;
        }
    }else {
        return 1;
    }
    return  0;
}

// 判断是不是 变量名称
- (BOOL)isVariable:(NSString *)variableString {
    for (int i = 1; i < [variableString length]; i++) {
        char wordChar = [variableString characterAtIndex:i];
        if ((![self isBelongsLetters:wordChar]) && (![self isBelongsNumber:wordChar]) && (wordChar != '_') ) {
            return NO;
        }
    }
    return YES;
}



@end
