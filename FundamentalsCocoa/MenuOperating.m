//
//  MenuOperating.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/8.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "MenuOperating.h"
#import "CodeTypeOperating.h"
#import "ViewController.h"
#import "FundamentalsResultPanelViewController.h"

@interface MenuOperating () {
    FundamentalsResultPanelViewController *fundamentalsResultViewController;
}

@end


@implementation MenuOperating

#pragma mark - 打开文件
- (IBAction)openNewFundamenttals:(id)sender {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setPrompt: @"打开"];
    
    openPanel.allowedFileTypes = [NSArray arrayWithObjects: @"txt", @"doc", nil];
    openPanel.directoryURL = nil;
    
    [openPanel beginSheetModalForWindow:[self gainMainViewController] completionHandler:^(NSModalResponse returnCode) {
        
        if (returnCode == 1) {
            NSURL *fileUrl = [[openPanel URLs] objectAtIndex:0];
            // 获取文件内容
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:fileUrl error:nil];
            NSString *fileContext = [[NSString alloc] initWithData:fileHandle.readDataToEndOfFile encoding:NSUTF8StringEncoding];
            
            // 将 获取的数据传递给 ViewController 的 TextView
            ViewController *mainViewController = (ViewController *)[self gainMainViewController].contentViewController;
            mainViewController.showCodeTextView.string = fileContext;
        }
    }];
}

#pragma mark - 词法分析
- (IBAction)lexicalAnalysis:(id)sender {
    // 将 获取的数据传递给 ViewController 的 TextView
    ViewController *mainViewController = (ViewController *)[self gainMainViewController].contentViewController;
    CodeTypeOperating *codeTypeOperating = [[CodeTypeOperating alloc] init];
    
    
    [codeTypeOperating dealWithCode:mainViewController.showCodeTextView.string];
    
    
    mainViewController.showResultTextView.string = mainViewController.showCodeTextView.string;
}


#pragma mark - 编译
- (IBAction)fundamentalCode:(id)sender {
    ViewController *mainViewController = (ViewController *)[self gainMainViewController].contentViewController;
    
    
    if (!fundamentalsResultViewController) {
        fundamentalsResultViewController = [[FundamentalsResultPanelViewController alloc] initWithWindowNibName:@"FundamentalsResultPanelViewController"];
    }
    
    [fundamentalsResultViewController showWindow:self];
    fundamentalsResultViewController.showFunResultTextView.string = mainViewController.showCodeTextView.string;
}


#pragma mark - 私有方法 
-(NSWindow *)gainMainViewController {
    return [NSApplication sharedApplication].windows[0];

}

@end
