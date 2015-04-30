//
//  ViewController.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/7.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "ViewController.h"

@interface ViewController () {
    NSArray *tokenArr;
}

@end

@implementation ViewController
@synthesize symbolFormCodeTypeArr;
@synthesize tokenFormCodeTypeArr;
@synthesize showCodeTextView;
@synthesize showResultTextView;
@synthesize wordDistinguishResultTableView;

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
    tokenArr = [NSArray array];
    symbolFormCodeTypeArr = [NSArray array];
    tokenFormCodeTypeArr = [NSArray array];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - TableView
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return  [tokenArr count];
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    // Since this is a single-column table view, this would not be necessary.
    // But it's a good practice to do it in order by remember it when a table is multicolumn.
    //@{@"name": wordName, @"token": @(codeType), @"rowNumber": @(row)};
    NSDictionary *tokenDic = [tokenArr objectAtIndex:row];
    if( [tableColumn.identifier isEqualToString:@"LineNumberCell"] ) {
        cellView.textField.stringValue = [tokenDic objectForKey:@"rowNumber"];
        
    }else if ([tableColumn.identifier isEqualToString:@"WordCell"] ) {
        cellView.textField.stringValue = [tokenDic objectForKey:@"name"];
        
    }else {
        cellView.textField.stringValue = [tokenDic objectForKey:@"token"];
        
    }
    return cellView;
}

//- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
//    if( [tableColumn.identifier isEqualToString:@"LineNumberCell"] ) {
//        return @"10";
//    }else if ([tableColumn.identifier isEqualToString:@"WordCell"] ) {
//        return @"9";
//    }else {
//        return @"8";
//    }
//    return nil;
//}


#pragma mark - 数据处理 
- (void)dealWithToken:(NSArray *)tokens {
    
    tokenArr = [NSArray arrayWithArray:tokens];
    
    [wordDistinguishResultTableView reloadData];
    
}

@end
