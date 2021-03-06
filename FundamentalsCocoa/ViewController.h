//
//  ViewController.h
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/7.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface ViewController : NSViewController<NSTableViewDataSource, NSTableViewDelegate>

@property (nonatomic, strong) NSArray *symbolFormCodeTypeArr;
@property (nonatomic, strong) NSArray *tokenFormCodeTypeArr;
@property (unsafe_unretained) IBOutlet NSTextView *showCodeTextView;
@property (unsafe_unretained) IBOutlet NSTextView *showResultTextView;

@property (weak) IBOutlet NSTableView *wordDistinguishResultTableView;

- (void)dealWithToken:(NSArray *)tokens;

@end

