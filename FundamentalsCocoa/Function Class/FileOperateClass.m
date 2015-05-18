//
//  FileOperateClass.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/21.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "FileOperateClass.h"

@implementation FileOperateClass

- (void)openFileWithSelectFolder:(NSWindow *)openWindow gainData:(void (^)(NSString *))gainData {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setPrompt: @"打开"];
    
    openPanel.allowedFileTypes = [NSArray arrayWithObjects: @"txt", @"doc", nil];
    openPanel.directoryURL = nil;
    
    [openPanel beginSheetModalForWindow:openWindow completionHandler:^(NSModalResponse returnCode) {
        
        if (returnCode == 1) {
            NSURL *fileUrl = [[openPanel URLs] objectAtIndex:0];
            // 获取文件内容
            NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingFromURL:fileUrl error:nil];
            NSString *fileContext = [[NSString alloc] initWithData:fileHandle.readDataToEndOfFile encoding:NSUTF8StringEncoding];
            
            gainData(fileContext);
        }
    }];
}

#pragma  mark - 保存信息 至 文件
- (void)saveSymbolToFile:(NSArray *)symbolArr {
    [symbolArr writeToFile:[self filePath:@"symbol"] atomically:YES];
}

- (void)saveTokenToFile:(NSArray *)tokenArr {
    [tokenArr writeToFile:[self filePath:@"Token"] atomically:YES];
}


- (NSString *)filePath:(NSString *)fileNmae {
    return [NSString stringWithFormat:@"/Users/wanghuanqiang/Desktop/%@.txt", fileNmae];
}

@end
