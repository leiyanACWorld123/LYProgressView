//
//  LYProgressView.h
//  加载动画-01
//
//  Created by apple on 16/7/13.
//  Copyright © 2016年 雷晏. All rights reserved.
//

#import <UIKit/UIKit.h>
typedef void(^finishBlock)();

@interface LYProgressView : UIView
@property (nonatomic,assign) finishBlock downLoadBlock;


-(void)startAnimation;

@end
