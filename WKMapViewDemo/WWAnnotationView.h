//
//  WWAnnotationView.h
//  WKMapViewDemo
//
//  Created by 莫晓卉 on 2018/5/1.
//  Copyright © 2018年 莫晓卉. All rights reserved.
//

#import <MapKit/MapKit.h>

@protocol WWWAnnotationViewDelegate <NSObject>
- (void)changedRadius:(UIButton *)button;
@end

@interface WWAnnotationView : MKAnnotationView

@property (nonatomic, weak) id<WWWAnnotationViewDelegate> delegate;
@property (nonatomic, strong) UIButton *touchBtn;

@end
