//
//  LYProgressView.m
//  加载动画-01
//
//  Created by apple on 16/7/13.
//  Copyright © 2016年 雷晏. All rights reserved.
//
#define RADIANS_TO_DEGREES(radians) ((radians) * (180.0 / M_PI))
#define DEGREES_TO_RADIANS(angle) ((angle) / 180.0 * M_PI)

#import "LYProgressView.h"
@interface LYProgressView()
{
    CGFloat _radius;//半径
    CGPoint _circlePoint;//圆点
    CGFloat _waveOffset;//波浪
    CGFloat _progress;//进度条
    CGFloat _waveHeight;//波浪高度
    CGFloat _waveSpeed;//波浪速度
}

@property (nonatomic,strong) UIView *cicleView;//圆环
@property (nonatomic,strong) CAShapeLayer *lineShapeLayer;//竖线
@property (nonatomic,strong) CAShapeLayer *curveShapeLayer;//曲线
@property (nonatomic,strong) CAShapeLayer *waveShapeLayer;//波浪线
@property (nonatomic,strong) CAShapeLayer *cicleShapeLayer;//圆环路径
@property (nonatomic,strong) CAShapeLayer *successShapeLayer;//下载成功
@property (nonatomic,strong) UILabel *progressLabel;//进度显示

@property (nonatomic,strong) CADisplayLink *link;//定时器
@property (nonatomic,strong) NSTimer *timer;



@end

@implementation LYProgressView

-(instancetype)initWithFrame:(CGRect)frame{
    if(self = [super initWithFrame:frame]){
        
        _radius = frame.size.width/2;
        
        _circlePoint = CGPointMake(frame.size.width/2, frame.size.height/2);
        
        _waveOffset = 0;
        _waveHeight = 0;
        _waveSpeed  = 0;
        
        //初始化计时器(默认关闭，需要条件满足才才开）
        self.link = [CADisplayLink displayLinkWithTarget:self selector:@selector(doWaveAnimation:)];
        [self.link addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        self.link.paused = YES;
        
        //初始化视图
        [self setUpInit];
    }
    return self;
}


-(void)setUpInit{
    
    //圆环
    self.cicleView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, _radius*2, _radius*2)];
    self.cicleView.backgroundColor = [UIColor clearColor];
    self.cicleView.layer.cornerRadius = _radius;
    self.cicleView.layer.borderColor = [UIColor whiteColor].CGColor;
    self.cicleView.layer.borderWidth = 5;
    self.cicleView.alpha = .3;
    self.cicleView.transform = CGAffineTransformMakeRotation(-M_PI/2);
    [self addSubview:self.cicleView];

    //竖线
    self.lineShapeLayer = [CAShapeLayer layer];
    self.lineShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.lineShapeLayer.lineWidth = 3.f;
    self.lineShapeLayer.lineCap = kCALineCapRound;
    self.lineShapeLayer.path = [self lineBezierPath_ChangeValue:1].CGPath;
    [self.layer addSublayer:self.lineShapeLayer];
    
    
    //曲线
    self.curveShapeLayer = [CAShapeLayer layer];
    self.curveShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.curveShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.curveShapeLayer.lineWidth = 3.f;
    self.curveShapeLayer.lineJoin = kCALineJoinRound;
    self.curveShapeLayer.lineCap = kCALineCapRound;
    self.curveShapeLayer.path = [self curveBezierPath_changeValue:0 otherValue:0].CGPath;
    [self.layer addSublayer:self.curveShapeLayer];
    
    
    //波浪线
    self.waveShapeLayer = [CAShapeLayer layer];
    self.waveShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.waveShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.waveShapeLayer.lineWidth = 3.f;
    self.waveShapeLayer.opacity = 1.0;
    CGFloat WIDTH = _circlePoint.x+20+20 - (_circlePoint.x-20-20);
    self.waveShapeLayer.position = CGPointMake(_circlePoint.x-WIDTH/2, _circlePoint.y);
    [self.layer addSublayer:self.waveShapeLayer];
    
    
    //圆环路径
    self.cicleShapeLayer = [CAShapeLayer layer];
    self.cicleShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.cicleShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.cicleShapeLayer.lineWidth = 5.f;
    self.cicleShapeLayer.lineJoin = kCALineJoinRound;
    self.cicleShapeLayer.lineCap = kCALineCapRound;
    self.cicleShapeLayer.path = [self circleBezierPath].CGPath;
    self.cicleShapeLayer.strokeEnd = 0;
    [self.layer addSublayer:self.cicleShapeLayer];
    
    
    //进度显示
    self.progressLabel = [[UILabel alloc]init];
    self.progressLabel.center = CGPointMake(_circlePoint.x, _circlePoint.y+20);
    self.progressLabel.bounds = CGRectMake(0, 0, _radius*2, 30);
    self.progressLabel.layer.transform = CATransform3DMakeScale(0, 0, 0);
    self.progressLabel.textColor = [UIColor whiteColor];
    self.progressLabel.textAlignment = NSTextAlignmentCenter;
    self.progressLabel.font = [UIFont systemFontOfSize:14.f];
    [self addSubview:self.progressLabel];
    
    
    //下载成功
    self.successShapeLayer = [CAShapeLayer layer];
    self.successShapeLayer.strokeColor = [UIColor whiteColor].CGColor;
    self.successShapeLayer.fillColor = [UIColor clearColor].CGColor;
    self.successShapeLayer.lineWidth = 3.f;
    self.successShapeLayer.opacity = 0.0;
    self.successShapeLayer.lineCap = kCALineCapRound;
    self.successShapeLayer.position = CGPointMake(_circlePoint.x, _circlePoint.y);
    self.successShapeLayer.path = [self curveBezierPath_finishChangeShape:0 leftValue:0 rightValue:0].CGPath;
    [self.layer addSublayer:self.successShapeLayer];

}

/**
 *  做动画
 */
-(void)startAnimation{
    
    CAAnimationGroup *lineAnimationGroup = [CAAnimationGroup animation];
    
    //竖线慢慢变成小圆动画
    CABasicAnimation *lineBasicAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    lineBasicAnimation.fromValue = (__bridge id _Nullable)([self lineBezierPath_ChangeValue:1].CGPath);
    lineBasicAnimation.toValue = (__bridge id _Nullable)([self lineBezierPath_ChangeValue:0.02].CGPath);
    lineBasicAnimation.fillMode = kCAFillModeForwards;
    lineBasicAnimation.removedOnCompletion = NO;
    lineBasicAnimation.duration = 1;

    //弹性移动动画
    CAKeyframeAnimation *lineKeyframeAnimation = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    lineKeyframeAnimation.values = @[
                                   (__bridge id _Nullable)([self lineBezierPath_ChangeValue:0.02].CGPath),
                                   (__bridge id _Nullable)([self lineBezierPath_ChangePostion:_radius+30].CGPath),
                                    (__bridge id _Nullable)([self lineBezierPath_ChangePostion:_radius-3].CGPath)];
    lineKeyframeAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAAnimationLinear];
    lineKeyframeAnimation.fillMode = kCAFillModeForwards;
    lineKeyframeAnimation.removedOnCompletion = NO;
    lineKeyframeAnimation.beginTime = 1.3;
    lineKeyframeAnimation.duration = 1;
    
    lineAnimationGroup.animations = @[lineBasicAnimation,lineKeyframeAnimation];
    lineAnimationGroup.duration = lineKeyframeAnimation.beginTime+lineKeyframeAnimation.duration;
    lineAnimationGroup.fillMode = kCAFillModeForwards;
    lineAnimationGroup.removedOnCompletion = NO;
    lineAnimationGroup.delegate = self;
    
    [self.lineShapeLayer addAnimation:lineAnimationGroup forKey:@"lineAnimationGroup"];

    
    //曲线动画
    [NSTimer scheduledTimerWithTimeInterval:0.65 target:self selector:@selector(doCureAnimation) userInfo:nil repeats:NO];
    //显示进度动画
    [NSTimer scheduledTimerWithTimeInterval:3.5 target:self selector:@selector(doShowProgressAnimation) userInfo:nil repeats:NO];
}


-(void)doCureAnimation{
    CAAnimationGroup *curveAnimationGroup = [CAAnimationGroup animation];
    
    //往下移动动画
    CABasicAnimation *curveBasicAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    curveBasicAnimation.fromValue = (__bridge id _Nullable)([self curveBezierPath_changeValue:0 otherValue:0].CGPath);
    curveBasicAnimation.toValue = (__bridge id _Nullable)([self curveBezierPath_changeValue:10 otherValue:0].CGPath);
    curveBasicAnimation.fillMode = kCAFillModeForwards;
    curveBasicAnimation.removedOnCompletion = NO;
    curveBasicAnimation.duration = 0.35;
    
    //往上移动动画,并且曲线慢慢变成直线
    CABasicAnimation *curveBasicAnimation1 = [CABasicAnimation animationWithKeyPath:@"path"];
    curveBasicAnimation1.fromValue = (__bridge id _Nullable)([self curveBezierPath_changeValue:10 otherValue:0].CGPath);
    curveBasicAnimation1.toValue = (__bridge id _Nullable)([self curveBezierPath_changeValue:-10 otherValue:-20].CGPath);
    curveBasicAnimation1.fillMode = kCAFillModeForwards;
    curveBasicAnimation1.removedOnCompletion = NO;
    curveBasicAnimation1.beginTime = curveBasicAnimation.duration;
    curveBasicAnimation1.duration = 0.35;
    
    //弹性动画
    CAKeyframeAnimation *curveBasicAnimation2 = [CAKeyframeAnimation animationWithKeyPath:@"path"];
    curveBasicAnimation2.values = @[
                                    (__bridge id _Nullable)([self curveBezierPath_Spring:0].CGPath),
                                    (__bridge id _Nullable)([self curveBezierPath_Spring:-8].CGPath),
                                    (__bridge id _Nullable)([self curveBezierPath_Spring:5].CGPath),
                                    (__bridge id _Nullable)([self curveBezierPath_Spring:-2].CGPath),
                                    (__bridge id _Nullable)([self curveBezierPath_Spring:0].CGPath)];
    curveBasicAnimation2.beginTime = curveBasicAnimation1.duration+ curveBasicAnimation1.beginTime;
    curveBasicAnimation2.duration = 0.35;
    
    //长度变宽动画
    CABasicAnimation *curveBasicAnimation3 = [CABasicAnimation animationWithKeyPath:@"path"];
    curveBasicAnimation3.fromValue = (__bridge id _Nullable)([self curveBezierPath_changeValue:-10 otherValue:-20].CGPath);
    curveBasicAnimation3.toValue = (__bridge id _Nullable)([self curveBezierPath_changeLength:20].CGPath);
    curveBasicAnimation3.beginTime = curveBasicAnimation2.duration+ curveBasicAnimation2.beginTime+1;
    curveBasicAnimation3.duration = 1;
    

    curveAnimationGroup.animations = @[curveBasicAnimation,curveBasicAnimation1,curveBasicAnimation2,curveBasicAnimation3];
    curveAnimationGroup.duration = curveBasicAnimation3.beginTime+curveBasicAnimation3.duration;
    curveAnimationGroup.fillMode = kCAFillModeForwards;
    curveAnimationGroup.removedOnCompletion = NO;
    curveAnimationGroup.delegate = self;
    [self.curveShapeLayer addAnimation:curveAnimationGroup forKey:@"curveAnimationGroup"];
    
}


-(void)doShowProgressAnimation
{
    [UIView animateWithDuration:1 animations:^{
        self.progressLabel.layer.transform = CATransform3DMakeScale(1.0, 1.0, 0);
    }];
}

-(void)doFinishAnimation
{
    CAAnimationGroup *animationGroup = [CAAnimationGroup animation];
    
    //变成勾勾动画
    CABasicAnimation *basicAnimation = [CABasicAnimation animationWithKeyPath:@"path"];
    basicAnimation.fromValue = (__bridge id)[self curveBezierPath_finishChangeShape:0 leftValue:0 rightValue:0].CGPath;
    basicAnimation.toValue = (__bridge id)[self curveBezierPath_finishChangeShape:15 leftValue:9 rightValue:5].CGPath;
    basicAnimation.duration = 1;
    basicAnimation.fillMode = kCAFillModeForwards;
    basicAnimation.removedOnCompletion = NO;
    
    //缩放动画
    CAKeyframeAnimation *keyframeAnimation2 = [CAKeyframeAnimation animationWithKeyPath:@"transform"];
    keyframeAnimation2.values = @[
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(1, 1, 0)],
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(1.2, 1.2, 0)],
                                  [NSValue valueWithCATransform3D:CATransform3DMakeScale(1, 1, 0)]];
    keyframeAnimation2.beginTime = basicAnimation.duration;
    keyframeAnimation2.duration = 0.85;
    keyframeAnimation2.fillMode = kCAFillModeForwards;
    keyframeAnimation2.removedOnCompletion = NO;
    
    animationGroup.animations = @[basicAnimation,keyframeAnimation2];
    animationGroup.fillMode = kCAFillModeForwards;
    animationGroup.removedOnCompletion = NO;
    animationGroup.delegate = self;
    animationGroup.duration = keyframeAnimation2.beginTime+keyframeAnimation2.duration;
    [self.successShapeLayer addAnimation:animationGroup forKey:@"waveShapeLayerAnimationGroup"];

}

//计时器监听方法(用于绘制波浪）y=Asin（ωx+φ）+h
-(void)doWaveAnimation:(CADisplayLink *)displayLink
{
    _waveOffset+=_waveSpeed;
    
    //波浪总宽度
    CGFloat WIDTH = _circlePoint.x+20+20 - (_circlePoint.x-20-20);
    
    CGMutablePathRef pathRef = CGPathCreateMutable();
    CGFloat startY = 2*sinf(_waveOffset*M_PI/WIDTH);
    CGPathMoveToPoint(pathRef, NULL, 0, startY);
    for(CGFloat i = 0.0 ; i < WIDTH ; i++){
        CGFloat y = 2*sinf(i*_waveHeight*M_PI/WIDTH+_waveOffset*M_PI/WIDTH);
        CGPathAddLineToPoint(pathRef, NULL, i, y);
    }
    self.waveShapeLayer.path = pathRef;
    CGPathRelease(pathRef);
}

//计时器监听方法（用于圆环填充）
-(void)progressLoading{
    _progress+=0.01;
    if(_progress > 1.01){
        [self.timer invalidate];
        self.waveShapeLayer.opacity = 0;
        self.successShapeLayer.opacity = 1;
        
        [UIView animateWithDuration:1 animations:^{
            self.progressLabel.layer.transform = CATransform3DMakeScale(0, 0, 0);
        }];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            //下载完毕做完毕动画
            [self doFinishAnimation];
        });
        
    }else{
        //0-0.7之间，波浪幅度和速度不变
        if(_progress >=0.0 && _progress <= 0.7){
            _waveSpeed = 5;
            _waveHeight= 2.5;
            NSLog(@"%f,%f",_waveSpeed,_waveHeight);

        }else{//0.7-1之间，波浪幅度和速度逐渐递减，最后为0
            _waveSpeed = 5*(1-_progress)/0.3;
            _waveHeight = 2.5*(1-_progress)/0.3;
            NSLog(@"%f,%f",_waveSpeed,_waveHeight);
        }
    
        self.cicleShapeLayer.strokeEnd = _progress;
        self.progressLabel.text = [NSString stringWithFormat:@"  %.f%%",_progress*100];
    }
}

#pragma -mark - 贝塞尔曲线绘制

//改变竖线长度
-(UIBezierPath *)lineBezierPath_ChangeValue:(CGFloat)value{
    UIBezierPath *lineBezierPath = [UIBezierPath bezierPath];
    [lineBezierPath moveToPoint:CGPointMake(_circlePoint.x, _circlePoint.y-30*value)];
    [lineBezierPath addLineToPoint:CGPointMake(_circlePoint.x, _circlePoint.y+30*value)];
    return lineBezierPath;
}

//改变竖线位置（发射竖线）
-(UIBezierPath *)lineBezierPath_ChangePostion:(CGFloat)offsetY{
    UIBezierPath *lineBezierPath = [UIBezierPath bezierPath];
    [lineBezierPath moveToPoint:CGPointMake(_circlePoint.x, _circlePoint.y-offsetY)];
    [lineBezierPath addLineToPoint:CGPointMake(_circlePoint.x, _circlePoint.y-offsetY)];
    return lineBezierPath;
}


//改变曲线（从折线变成直线）
-(UIBezierPath *)curveBezierPath_changeValue:(CGFloat)value otherValue:(CGFloat)otherValue{
    UIBezierPath *curveBezierPath = [UIBezierPath bezierPath];
    [curveBezierPath moveToPoint:CGPointMake(_circlePoint.x-20, _circlePoint.y+10 + value)];
    [curveBezierPath addLineToPoint:CGPointMake(_circlePoint.x, _circlePoint.y+30 + value+otherValue)];
    [curveBezierPath addLineToPoint:CGPointMake(_circlePoint.x+20, _circlePoint.y+10 + value)];
    
    return curveBezierPath;

}
//改变曲线（从直线变成抛物线)
-(UIBezierPath *)curveBezierPath_Spring:(CGFloat)value{
    UIBezierPath *curveBezierPath = [UIBezierPath bezierPath];
    [curveBezierPath moveToPoint:CGPointMake(_circlePoint.x-20, _circlePoint.y)];
    [curveBezierPath addQuadCurveToPoint:CGPointMake(_circlePoint.x+20, _circlePoint.y) controlPoint:CGPointMake(_circlePoint.x, _circlePoint.y+value)];
    return curveBezierPath;
}

//改变曲线宽度
-(UIBezierPath *)curveBezierPath_changeLength:(CGFloat)value{
    UIBezierPath *curveBezierPath = [UIBezierPath bezierPath];
    [curveBezierPath moveToPoint:CGPointMake(_circlePoint.x-20-value, _circlePoint.y)];
    [curveBezierPath addLineToPoint:CGPointMake(_circlePoint.x+20+value, _circlePoint.y)];
    return curveBezierPath;
}

//圆环路径
-(UIBezierPath *)circleBezierPath{
    CGPoint arcCenter = CGPointMake(_circlePoint.x, _circlePoint.y);
    UIBezierPath *circleBezierPath = [UIBezierPath bezierPathWithArcCenter:arcCenter radius:self.bounds.size.width*0.5-3 startAngle:-M_PI/2 endAngle:-2*M_PI-M_PI/2 clockwise:NO];
    return circleBezierPath;
}

//加载完毕（勾勾)
-(UIBezierPath *)curveBezierPath_finishChangeShape:(CGFloat)value leftValue:(CGFloat)leftValue rightValue:(CGFloat)rightValue{
    UIBezierPath *curveBezierPath = [UIBezierPath bezierPath];
    [curveBezierPath moveToPoint:CGPointMake(-40+value+leftValue,-value+leftValue)];
    [curveBezierPath addLineToPoint:CGPointMake(0,value)];
    [curveBezierPath addLineToPoint:CGPointMake(40-value-rightValue,-value-rightValue)];
    return curveBezierPath;
}

#pragma mark - animation Delegate
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if(anim == [self.curveShapeLayer animationForKey:@"curveAnimationGroup"]){
        if(flag){
            NSLog(@"cureveAnimation end..");
            //开启定时器
            self.link.paused = NO;
            
            self.curveShapeLayer.opacity = 0;
            
            if(!self.timer){
            self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(progressLoading) userInfo:nil repeats:YES];
                [[NSRunLoop currentRunLoop]addTimer:self.timer forMode:NSRunLoopCommonModes];
            }
        }
    }else if (anim == [self.lineShapeLayer animationForKey:@"lineAnimationGroup"]){
        if(flag){
            NSLog(@"lineAnimation end..");
        }
    }else if (anim == [self.successShapeLayer animationForKey:@"waveShapeLayerAnimationGroup"]){
        if(flag){
            NSLog(@"finishAnimation end..");
            self.downLoadBlock();
        }
    }
}

@end
