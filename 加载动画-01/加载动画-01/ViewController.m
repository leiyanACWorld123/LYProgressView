//
//  ViewController.m
//  加载动画-01
//
//  Created by apple on 16/7/13.
//  Copyright © 2016年 雷晏. All rights reserved.
//

#import "ViewController.h"
#import "LYProgressView.h"

@interface ViewController ()

@property (nonatomic,strong) LYProgressView *bigCicleView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor colorWithRed:0/255.0 green:152/255.0 blue:246/255.0 alpha:1];
    
    self.bigCicleView = [[LYProgressView alloc]initWithFrame:CGRectMake(0, 0, 120, 120)];
    self.bigCicleView.center = self.view.center;
    [self.view addSubview:self.bigCicleView];
    self.bigCicleView.downLoadBlock = ^{
        NSLog(@"下载完毕");
    };
}

-(void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event{
    [self.bigCicleView startAnimation];
}
@end
