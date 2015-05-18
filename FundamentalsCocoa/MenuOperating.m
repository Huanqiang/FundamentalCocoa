//
//  MenuOperating.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/8.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "MenuOperating.h"

// 打开文件操作类
#import "FileOperateClass.h"

// 词法分析
#import "CodeTypeOperating.h"

// 语法分析
#import "GrammaticalAnalysisClass.h"

// 框体类
#import "ViewController.h"
#import "FundamentalsResultPanelViewController.h"
#import "LLFirstForecast.h"
#import "OperatorPriorateWindowController.h"

@interface MenuOperating () {
    FundamentalsResultPanelViewController *fundamentalsResultViewController;
    LLFirstForecast *llFirstForecastViewController;
    OperatorPriorateWindowController *operatorPriorateWindowController;
}

@end


@implementation MenuOperating

#pragma mark - 打开文件
- (IBAction)openNewFundamenttals:(id)sender {
    [[[FileOperateClass alloc] init] openFileWithSelectFolder:[self gainMainWindowController] gainData:^(NSString *result) {
        // 将 获取的数据传递给 ViewController 的 TextView
        ViewController *mainViewController = [self gainMainViewController];
        mainViewController.showCodeTextView.string = result;
    }];
}

#pragma mark - 词法分析
- (IBAction)lexicalAnalysis:(id)sender {
    // 将 获取的数据传递给 ViewController 的 TextView
    ViewController *mainViewController = [self gainMainViewController];
    CodeTypeOperating *codeTypeOperating = [[CodeTypeOperating alloc] init];
    
    // 进行 词法分析
    [codeTypeOperating dealWithCode:mainViewController.showCodeTextView.string];
    
    // 获取token 和symbol
    mainViewController.symbolFormCodeTypeArr = [NSArray arrayWithArray:codeTypeOperating.symbolArr];
    mainViewController.tokenFormCodeTypeArr = [NSArray arrayWithArray:codeTypeOperating.tokenArr];
    
    // 将 词法分析 的正确部分 放到主界面的相应位置
    [mainViewController dealWithToken:codeTypeOperating.tokenArr];
    
    // 将 词法分析 的错误部分 放到主界面的相应位置
    mainViewController.showResultTextView.string = [self dealWithFalseInfo:codeTypeOperating.falseWordArr];
    
    // 保存 至 文件
    // 将语法分析结果保存至文件
    FileOperateClass *fileOperateClass = [[FileOperateClass alloc] init];
    [fileOperateClass saveSymbolToFile:codeTypeOperating.symbolArr];
    [fileOperateClass saveTokenToFile:codeTypeOperating.tokenArr];
}


// 处理错误信息
- (NSString *)dealWithFalseInfo:(NSArray *)falseWordArr {
    
    NSMutableString *falseInfoString = [NSMutableString string];
    if ([falseWordArr count] != 0) {
        [falseInfoString appendFormat:@"程序有错：\n"];
        for (NSDictionary *falseDic in falseWordArr) {
            [falseInfoString appendFormat:@"\t第%@行： 信息：%@\n", [falseDic objectForKey:@"rowNumber"], [falseDic objectForKey:@"name"]];
        }
    }else {
        [falseInfoString appendString:@"暂无错误!"];
    }

    return falseInfoString;
}

#pragma mark - 编译
- (IBAction)fundamentalCode:(id)sender {
}

#pragma mark - LL1 预测分析
- (IBAction)LLFirstForecastAnalyse:(id)sender {
    if (!llFirstForecastViewController) {
        llFirstForecastViewController = [[LLFirstForecast alloc] initWithWindowNibName:@"LLFirstForecast"];
    }
    [llFirstForecastViewController showWindow:self];
}


#pragma mark - 算符优先
- (IBAction)operatorPriorate:(id)sender {
    if (!operatorPriorateWindowController) {
        operatorPriorateWindowController = [[OperatorPriorateWindowController alloc] initWithWindowNibName:@"OperatorPriorateWindowController"];
    }
    [operatorPriorateWindowController showWindow:self];
}

#pragma mark - 语法 分析
- (IBAction)grammaticalAnalysis:(id)sender {
    // 将 获取的数据传递给 ViewController 的 TextView
    ViewController *mainViewController = [self gainMainViewController];
    GrammaticalAnalysisClass *grammaticalAnalysis = [[GrammaticalAnalysisClass alloc] init];
    [grammaticalAnalysis grammaticalAnalysis:mainViewController.tokenFormCodeTypeArr symbolInfoList:mainViewController.symbolFormCodeTypeArr];    
    
    // 数据展示
    if (!fundamentalsResultViewController) {
        fundamentalsResultViewController = [[FundamentalsResultPanelViewController alloc] initWithWindowNibName:@"FundamentalsResultPanelViewController"];
    }
    [fundamentalsResultViewController showWindow:self];
    
    
    
    // 将 语法分析 的正确部分 放到主界面的相应位置
    [fundamentalsResultViewController transformInfoRightToTextView:grammaticalAnalysis.analyzeResultList];
    // 将 语法分析 的错误部分 放到主界面的相应位置
    fundamentalsResultViewController.analyzeFalseInfoTextView.string = [self dealWithFalseInfo:grammaticalAnalysis.falseList];
    // 将 语义分析 放到主界面的相应位置
    [fundamentalsResultViewController transformInfoQuaternionToTextView:grammaticalAnalysis.quaternionList];
    
    // 将语法分析结果保存至文件
    FileOperateClass *fileOperateClass = [[FileOperateClass alloc] init];
    [fileOperateClass saveSymbolToFile:grammaticalAnalysis.symbolAnalyzeResultList];
}


#pragma mark - 私有方法 
- (ViewController *)gainMainViewController {
    return (ViewController *)[self gainMainWindowController].contentViewController;
}

-(NSWindow *)gainMainWindowController {
    return [NSApplication sharedApplication].windows[0];

}

@end
