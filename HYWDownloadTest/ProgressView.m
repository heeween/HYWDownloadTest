//
//  ProgressView.m
//  04-重绘-下载进度
//
//  Created by xiaomage on 15/6/17.
//  Copyright (c) 2015年 xiaomage. All rights reserved.
//

#import "ProgressView.h"
#define HYWColr(r,g,b) [UIColor colorWithRed:((r) / 255.0) green:((g) / 255.0 ) blue:((b) / 255.0 ) alpha:0.3]




@interface ProgressView ()
/**贝斯尔曲线 */
@property (nonatomic, strong) UIBezierPath *path;
@end



@implementation ProgressView

- (UIBezierPath *)path {
    if (_path == nil) {
        _path = [[UIBezierPath alloc] init];
    }
    return _path;
}

- (void)setProgress:(CGFloat)progress {
    _progress = progress;
    [self setNeedsDisplay];
    
}

- (void)drawRect:(CGRect)rect {
    // Drawing code
    
    
    // 计算中心店
    CGFloat radius = MIN(rect.size.width, rect.size.height) * 0.5;
    CGPoint center = CGPointMake(rect.size.width * 0.5, rect.size.height * 0.5);
    
    // 计算半径和弧度值
    CGFloat MAXradius = sqrt(pow(rect.size.width * 0.5, 2) + pow(rect.size.height * 0.5, 2));
    CGFloat endA = -M_PI_2 + _progress * M_PI * 2;
    
    // 画扇形
    [self.path moveToPoint:center];
    [self.path addLineToPoint:CGPointMake(center.x, radius - MAXradius)];
    [self.path addArcWithCenter:center radius:MAXradius startAngle:-M_PI_2 endAngle:endA clockwise:NO];
    [self.path addLineToPoint:center];
    
    // 设置颜色并生产蒙版
    if (self.progress ==  0) {[self.backgroundColor set];}
    else {[HYWColr(222, 222, 222) set];}
    [self.path fill];
    
    // 清空蒙版,否则self.path这个对象会很大,变成耗时操作
    self.path = nil;
}


@end


