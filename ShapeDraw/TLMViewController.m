//
//  TLMViewController.m
//  ShapeDraw
//
//  Created by Hunter Bridges on 8/29/13.
//  Copyright (c) 2013 The Telemetry Group. All rights reserved.
//

#import "TLMViewController.h"
#import "TLMLinearInterpView.h"

@interface TLMViewController ()

@property (nonatomic, strong) UIView *interpView;

@end

@implementation TLMViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.interpView =
        [[TLMLinearInterpView alloc] initWithFrame:self.view.bounds];
    self.interpView.autoresizingMask =
        (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    [self.view addSubview:self.interpView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation
{
    return UIInterfaceOrientationPortrait;
}

@end
