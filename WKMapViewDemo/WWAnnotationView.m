//
//  WWAnnotationView.m
//  WKMapViewDemo
//
//  Created by 莫晓卉 on 2018/5/1.
//  Copyright © 2018年 莫晓卉. All rights reserved.
//

#import "WWAnnotationView.h"
#import <Masonry/Masonry.h>

#define kMaxWidth ([UIScreen mainScreen].bounds.size.width-20)
static const CGFloat kDefaultWidth = 80;

@interface WWView : UIView
@property (nonatomic, strong) UIButton *button;
@property (nonatomic, copy) void(^changedRadius)(UIButton *button);
@end

@implementation WWView {
  UIView *_view;
  CAShapeLayer *_shapeLayer;
}

- (instancetype)initWithFrame:(CGRect)frame {
  self = [super initWithFrame:frame];
  if (self) {
    self.userInteractionEnabled = YES;
    _view = [[UIView alloc] init];
    _view.layer.borderColor =  [UIColor blueColor].CGColor;
    _view.backgroundColor = [[UIColor blueColor] colorWithAlphaComponent:.3];
    _view.layer.cornerRadius = (kDefaultWidth - 24) * 0.5;
    [self addSubview:_view];
    [_view mas_makeConstraints:^(MASConstraintMaker *make) {
      make.edges.equalTo(self).insets(UIEdgeInsetsMake(12, 12, 12, 12));
    }];
    
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    [_button setImage:[UIImage imageNamed:@"Oval 3"] forState:UIControlStateNormal];
    _button.adjustsImageWhenHighlighted = NO;
    [self addSubview:_button];
    [_button mas_makeConstraints:^(MASConstraintMaker *make) {
      make.width.height.mas_equalTo(24);
      make.right.equalTo(self);
      make.centerY.equalTo(self);
    }];
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panAction:)];
    [_button addGestureRecognizer:pan];
    
  }
  return self;
}

- (void)layoutSubviews {
  [super layoutSubviews];
  [self drawDashLine:_view lineLength:10 lineSpacing:5 lineColor:[UIColor orangeColor]];
}

#pragma mark - 拖拽手势
- (void)panAction:(UIPanGestureRecognizer *)pan {
  CGPoint p = [pan translationInView:pan.view];
  CGFloat x = p.x;
  if (x > 5) x = 5;
  if (x < -5) x = -5;
  
  CGFloat orginWidth = self.frame.size.width;
  CGFloat resultWidth = orginWidth + x;
  
  CGFloat width;
  if (resultWidth < kDefaultWidth) {
    width = kDefaultWidth;
  } else if (resultWidth > kMaxWidth) {
    width = kMaxWidth;
  } else {
    width = resultWidth;
  }
  
  [self mas_updateConstraints:^(MASConstraintMaker *make) {
    make.width.height.mas_equalTo(width);
  }];
  _view.layer.cornerRadius = (width - 24) * 0.5;
  if (self.changedRadius) {
    self.changedRadius(_button);
  }
}

/**
 ** lineView:       需要绘制成虚线的view
 ** lineLength:     虚线的宽度
 ** lineSpacing:    虚线的间距
 ** lineColor:      虚线的颜色
 **/
- (void)drawDashLine:(UIView *)lineView lineLength:(int)lineLength lineSpacing:(int)lineSpacing lineColor:(UIColor *)lineColor {
  if (_shapeLayer) {
    [_shapeLayer removeFromSuperlayer];
  }
  CAShapeLayer *shapeLayer = [CAShapeLayer layer];
  [shapeLayer setBounds:CGRectMake(0, 0, lineView.bounds.size.width, lineView.bounds.size.height)];
  [shapeLayer setPosition:CGPointMake(CGRectGetWidth(lineView.frame) * 0.5, CGRectGetHeight(lineView.frame))];
  [shapeLayer setFillColor:[UIColor clearColor].CGColor];
  // 设置虚线颜色为blackColor
  [shapeLayer setStrokeColor:lineColor.CGColor];
  // 设置虚线宽度
  [shapeLayer setLineWidth:3];
  [shapeLayer setLineJoin:kCALineJoinRound];
  // 设置线宽，线间距
  [shapeLayer setLineDashPattern:[NSArray arrayWithObjects:[NSNumber numberWithInt:lineLength], [NSNumber numberWithInt:lineSpacing], nil]];
  // 设置路径
  CGMutablePathRef path = CGPathCreateMutable();
  CGPathMoveToPoint(path, NULL, CGRectGetWidth(lineView.frame)*.5, 0);
  CGPathAddLineToPoint(path, NULL,CGRectGetWidth(lineView.frame), 0);
  [shapeLayer setPath:path];
  CGPathRelease(path);
  // 把绘制好的虚线添加上来
  [lineView.layer addSublayer:shapeLayer];
  _shapeLayer = shapeLayer;
}

@end


@implementation WWAnnotationView {
  WWView *_shawView;
  CGFloat _preWidth;
  CGFloat scale;
}

- (instancetype)initWithAnnotation:(id<MKAnnotation>)annotation reuseIdentifier:(NSString *)reuseIdentifier {
  self = [super initWithAnnotation:annotation reuseIdentifier:reuseIdentifier];
  if (self) {
    self.image = [UIImage imageNamed:@"icon_中心定位点"];
    _shawView = [[WWView alloc] init];
    __weak typeof(self) weakSelf = self;
    _shawView.changedRadius = ^(UIButton *button) {
      if (weakSelf.delegate) {
        [weakSelf.delegate changedRadius:button];
      }
    };
    self.touchBtn = _shawView.button;
    [self addSubview:_shawView];
    [_shawView mas_makeConstraints:^(MASConstraintMaker *make) {
      make.center.equalTo(self);
      make.width.height.mas_equalTo(kDefaultWidth);
    }];
  }
  return self;
}

#pragma mark - 扩大点击范围
- (BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event {
  [self layoutIfNeeded];
  if (CGRectContainsPoint(_shawView.frame, point) || CGRectContainsPoint(self.frame, point)) {
    return YES;
  }
  return NO;
}

@end
