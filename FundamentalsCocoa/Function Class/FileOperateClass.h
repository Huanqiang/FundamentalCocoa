//
//  FileOperateClass.h
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/21.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>

@interface FileOperateClass : NSObject

/**
 *  开发文件选择器，并选择文件，获取数据
 *
 *  @param openWindow 需要被打开的框体
 *  @param gainData   获取数据操作
 */
- (void)openFileWithSelectFolder:(NSWindow *)openWindow gainData:(void (^)(NSString *result))gainData;

- (void)saveSymbolToFile:(NSArray *)symbolArr;
- (void)saveTokenToFile:(NSArray *)tokenArr;


@end
