//
//  LLFirstForecast.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/21.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "LLFirstForecast.h"
#import "FileOperateClass.h"

@interface LLFirstForecast ()

@property (unsafe_unretained) IBOutlet NSTextView *grammarDataTextView;
@property (unsafe_unretained) IBOutlet NSTextView *firstCollectionResultTextView;
@property (unsafe_unretained) IBOutlet NSTextView *followCollectionResultTextView;

@end

@implementation LLFirstForecast

- (void)windowDidLoad {
    [super windowDidLoad];
    
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
    
    // 最后进行文法的 展示
    [self fileContextShow:firstCollection];
}

// 分离数据（依据：-> 和 |）
- (NSDictionary *)separateFirstCollection:(NSString *)rowContext {
    // 先根据 -> 分离 起始符
    NSArray *arrowHeadArr = [rowContext componentsSeparatedByString:@"->"];
    
    // 获取每一个 结束符的 第一个符号
    NSMutableArray *endSignals = [NSMutableArray array];
    for (NSString *signal in [arrowHeadArr[1] componentsSeparatedByString:@"|"]) {
        [endSignals addObject:[NSString stringWithFormat:@"%c", [signal characterAtIndex:0]]];
    }
    
    // 将每一个起始符 和 其到达分离
    // IsFinish： 1表示完成 0表示未完成
    return @{arrowHeadArr[0]: @{@"IsFinish": @(0), @"EndSignalValues":endSignals}};
}

// 数据处理
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
- (void)fileContextShow:(NSDictionary *)firstCollection {
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
    
    self.firstCollectionResultTextView.string = newFileContext;
}

#pragma mark - 求 follow 集
- (IBAction)foundFollowCollection:(id)sender {
    
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
