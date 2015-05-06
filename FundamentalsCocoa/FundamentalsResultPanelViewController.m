//
//  FundamentalsResultPanelViewController.m
//  FundamentalsCocoa
//
//  Created by 王焕强 on 15/4/7.
//  Copyright (c) 2015年 王焕强. All rights reserved.
//

#import "FundamentalsResultPanelViewController.h"

@interface FundamentalsResultPanelViewController ()


@end

@implementation FundamentalsResultPanelViewController
@synthesize analyzeFalseInfoTextView;
@synthesize analyzeRightInfoTextView;

- (id)init {
    self = [super initWithWindowNibName:@"FundamentalsResultPanelViewController"];
//    self.showFunResultTextView = [[NSTextView alloc] init];
    return self;
}

- (void)windowDidLoad {
    [super windowDidLoad];
    
    // Implement this method to handle any initialization after your window controller's window has been loaded from its nib file.
}

- (void)transformInfoRightToTextView:(NSArray *)infoList {
    NSMutableString *rightInfo = [NSMutableString string];
    for (NSString *info in infoList) {
        [rightInfo appendFormat:@"%@\n", info];
    }
    self.analyzeRightInfoTextView.string = rightInfo;
}

@end
