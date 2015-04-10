//
//  ViewController.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/7.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "ViewController.h"

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    // Do any additional setup after loading the view.
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}

#pragma mark - TableView
- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView {
    return  10;
}

- (NSView *)tableView:(NSTableView *)tableView viewForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row {
    
    // Get a new ViewCell
    NSTableCellView *cellView = [tableView makeViewWithIdentifier:tableColumn.identifier owner:self];
    
    // Since this is a single-column table view, this would not be necessary.
    // But it's a good practice to do it in order by remember it when a table is multicolumn.WordCellTypeCodeCell
    if( [tableColumn.identifier isEqualToString:@"LineNumberCell"] ) {
        cellView.textField.stringValue = @"10";
    }else if ([tableColumn.identifier isEqualToString:@"WordCell"] ) {
        cellView.textField.stringValue = @"9";
    }else {
        cellView.textField.stringValue = @"8";
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

@end
