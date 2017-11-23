//
//  GooView.m
//  16  QQ提示标粘性效果
//
//  Created by MAC on 2017/9/6.
//  Copyright © 2017年 GuoDongge. All rights reserved.
//

#import "GooView.h"
//最远拖拽距离，超过这个距离就会爆破
#define kMaxDistance 80

@interface GooView()

/**
 底部的小圆
 */
@property(nonatomic,weak)UIView * smallCircleView;

/**
 底部小圆最开始的半径
 */
@property(nonatomic,assign)CGFloat smallViewR;

/**
 可以生成不规则图形的layer
 */
@property(nonatomic,weak)CAShapeLayer * shapeLayer;

@end
@implementation GooView
//懒加载不规则layer
-(CAShapeLayer *)shapeLayer
{
    if (_shapeLayer == nil) {
        CAShapeLayer * layer = [CAShapeLayer layer];
        
        _shapeLayer = layer;
        
        layer.fillColor = self.backgroundColor.CGColor;
        //添加到俯视图的layer上，位置在大圆后边（目前按钮本身就是这个大圆）
        [self.superview.layer insertSublayer:layer below:self.layer];
    }
    return  _shapeLayer ;
}
/**
 懒加载创建小圆

 @return 小圆view
 */
-(UIView *)smallCircleView
{
    if (_smallCircleView == nil) {
        
        UIView * view = [[UIView alloc]init];
        //颜色和大圆一样
        view.backgroundColor = self.backgroundColor;
        _smallCircleView = view;
        
        //添加到父视图，在大圆后边
        [self.superview insertSubview:view belowSubview:self];
        
    }
    return _smallCircleView;
}

-(void)awakeFromNib
{
    [super awakeFromNib];
    
    [self setUp];
}

-(void)setUp
{
    //大圆的宽
    CGFloat w = self.bounds.size.width;
    //小圆最开始的半径
    _smallViewR = w /2;
    //大圆切圆角
    self.layer.cornerRadius = w / 2;
    
    UIPanGestureRecognizer * pan = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(pan:)];
    
    [self addGestureRecognizer:pan];
    
    //设置小圆的位置和半径
    self.smallCircleView.center = self.center;
    self.smallCircleView.bounds = self.bounds;
    self.smallCircleView.layer.cornerRadius = w / 2;
    
}

-(instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        [self setUp];
    }
    return self;
}


-(void)pan:(UIPanGestureRecognizer*)pan
{
    //获取手指偏移量
    CGPoint transP = [pan translationInView:self];
    
    //修改center
    CGPoint center = self.center;
    center.x += transP.x;
    center.y += transP.y;
    self.center = center;
    
    //复位（因为拖动手势里，位置是相对于上一次）
    [pan setTranslation:CGPointZero inView:self];
    //两个圆心的间距
    CGFloat d = [self centerDistanceWithBigCircleCenter:self.center smallCircleCenter:self.smallCircleView.center];
    
    //小圆的半径（不断变化的）= 小圆最开始的半径 - 两个圆心间距的1/10
    CGFloat smallR = self.smallViewR - d /10;
    //当小圆半径小于0时，不再加载小圆
//    if (smallR < 0) return;
    
    
    //设置小圆尺寸
    self.smallCircleView.bounds = CGRectMake(0, 0, smallR * 2, smallR * 2);
    self.smallCircleView.layer.cornerRadius = smallR;
    
    
    //当圆心间距大于所设置的距离
    if (d > kMaxDistance) {
        //隐藏小圆，删除不规则图层
        self.smallCircleView.hidden = YES;
        
        [self.shapeLayer removeFromSuperlayer];
        self.shapeLayer = nil;
        
        
        //当圆心距离大于0并且小圆不隐藏时
    }else if (d>0 && self.smallCircleView.hidden == NO)
    {
           //绘制不规则图层
        self.shapeLayer.path = [self pathWithBigCircleView:self smallCircleView:self.smallCircleView].CGPath;
    }
    
    //当手指离开时
    if (pan.state == UIGestureRecognizerStateEnded) {
        //当圆心间距大于所设置的距离
        if (d > kMaxDistance) {
            //加载gif爆破图片
            UIImageView * imageView = [[UIImageView alloc]initWithFrame:self.bounds];
            //创建图片数组
            NSMutableArray * arrM = [NSMutableArray array];
            //遍历图片，并且加入到数组
            for (int i =1; i < 9 ; i++) {
                UIImage * image = [UIImage imageNamed:[NSString stringWithFormat:@"%d",i]];
                [arrM addObject:image];
            }
            
            imageView.animationImages = arrM;
            imageView.animationRepeatCount = 1;
            imageView.animationDuration = 0.5;
            [imageView startAnimating];
            
            [self addSubview:imageView];
            //延迟0.4秒消失
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
                [self removeFromSuperview];
            });
        }
        else
        {
//            当圆心间距小于所设置的距离
            [self.shapeLayer removeFromSuperlayer];
            self.shapeLayer = nil;
            
            //还原位置
            [UIView animateWithDuration:0.5 delay:0 usingSpringWithDamping:0.2 initialSpringVelocity:0 options:UIViewAnimationOptionCurveLinear animations:^{
                
                self.center = self.smallCircleView.center;
            } completion:^(BOOL finished) {
                self.smallCircleView.hidden = NO;
            }];
        }
        
        
        
        
    }
    
    
    
    
    
}

//计算两个圆心得距离(根据勾股定理计算)
-(CGFloat)centerDistanceWithBigCircleCenter:(CGPoint)bigCircleCenter smallCircleCenter:(CGPoint)smallCircleCenter
{
    CGFloat offsetX = bigCircleCenter.x - smallCircleCenter.x;
    CGFloat offsetY = bigCircleCenter.y - smallCircleCenter.y;
    
    return fabsf( sqrtf(offsetX * offsetX + offsetY * offsetY));
    
}

//描述两圆之间的一条矩形路径

-(UIBezierPath*)pathWithBigCircleView:(UIView*)bigCircleView smallCircleView:(UIView*)smallCircleView
{
    //这里根据‘粘性效果计算图’里的公式来写就可以
    CGPoint bigCenter = bigCircleView.center;
    CGFloat x2 = bigCenter.x;
    CGFloat y2 = bigCenter.y;
    CGFloat r2 = bigCircleView.bounds.size.width  / 2;
    
    CGPoint smallCenter = smallCircleView.center;
    CGFloat x1 = smallCenter.x;
    CGFloat y1 = smallCenter.y;
    CGFloat r1 = smallCircleView.bounds.size.width  / 2;
    
    //获取圆心距离
    CGFloat d = [self centerDistanceWithBigCircleCenter:bigCenter smallCircleCenter:smallCenter];
    
    CGFloat sinθ = (x2 - x1) / d;
    CGFloat cosθ = (y2 - y1) / d;
    
    //坐标系基于父控件
    CGPoint pointA = CGPointMake(x1 - r1 * cosθ, y1 + r1 * sinθ);
    CGPoint pointB = CGPointMake(x1 + r1 * cosθ , y1 - r1 * sinθ);
    CGPoint pointC = CGPointMake(x2 + r2 * cosθ , y2 - r2 * sinθ);
    CGPoint pointD = CGPointMake(x2 - r2 * cosθ , y2 + r2 * sinθ);
    CGPoint pointO = CGPointMake(pointA.x + d / 2 * sinθ , pointA.y + d / 2 * cosθ);
    CGPoint pointP =  CGPointMake(pointB.x + d / 2 * sinθ , pointB.y + d / 2 * cosθ);
    
    UIBezierPath * path = [UIBezierPath bezierPath];
    
    [path moveToPoint:pointA];
    
    [path addLineToPoint:pointB];
    
    [path addQuadCurveToPoint:pointC controlPoint:pointP];
    
    [path addLineToPoint:pointD];
    
    [path addQuadCurveToPoint:pointA controlPoint:pointO];
    
    return path;
    
    
}



@end
