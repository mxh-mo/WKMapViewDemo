//
//  ViewController.m
//  WKMapViewDemo
//
//  Created by 莫晓卉 on 2018/4/28.
//  Copyright © 2018年 莫晓卉. All rights reserved.
//

#import "ViewController.h"
#import <CoreLocation/CoreLocation.h>
#import <MapKit/MapKit.h>
#import "WWAnnotationView.h"
#import <Masonry/Masonry.h>

// 状态栏高度
#define kStatusHeight ([UIApplication sharedApplication].statusBarFrame.origin.y + [UIApplication sharedApplication].statusBarFrame.size.height)
#define kDefault (100)

@interface ViewController () <CLLocationManagerDelegate, MKMapViewDelegate, WWWAnnotationViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong) CLLocationManager *locationManager;
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) WWAnnotationView *currentAnnotationView;
@property (nonatomic, strong) UILabel *addressLb;
@property (nonatomic, strong) MKCircle *circle;
@property (nonatomic, assign) CLLocationCoordinate2D userCoordinate;
@end

@implementation ViewController {
  UILabel *_radiusLb;
  BOOL _followUserLoc;  // 是否跟踪用户定位
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _followUserLoc  = YES;
  [self setupView];
  
  if ([CLLocationManager locationServicesEnabled]) {
    self.locationManager = [[CLLocationManager alloc] init];
    self.locationManager.delegate = self;
    // 移动最大更新距离 (及移动距离超过此值, 就会受到回调)
    // 默认: kCLDistanceFilterNone 回调任何移动
    self.locationManager.distanceFilter = kCLDistanceFilterNone;
    // 最佳精准度 : kCLLocationAccuracyBest
    // 导航 : kCLLocationAccuracyBestForNavigation
    // 值越低精准度越高, 越耗电; 负值无效
    self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
    [self.locationManager requestAlwaysAuthorization];
    // 开始定位
    [self.locationManager startUpdatingLocation];
  } else {
    NSLog(@"定位服务不可用, 请设置");
  }
}

- (void)setupView {
  self.title = @"安全区域";
  
  UIView *bottomView = [[UIView alloc] init];
  [self.view addSubview:bottomView];
  bottomView.backgroundColor = [UIColor whiteColor];
  [bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.right.equalTo(self.view);
    make.bottom.equalTo(self.mas_bottomLayoutGuide);
    make.height.mas_equalTo(80);
  }];
  
  UIImageView *radiusImgV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_radius"]];
  [bottomView addSubview:radiusImgV];
  [radiusImgV mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.top.equalTo(bottomView).offset(16);
    make.height.width.mas_equalTo(15);
  }];
  
  _radiusLb = [[UILabel alloc] init];
//  _radiusLb.text = @"当前安全半径：1000米";
  _radiusLb.textColor = [UIColor blackColor];
  _radiusLb.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
  [bottomView addSubview:_radiusLb];
  [_radiusLb mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(radiusImgV.mas_right).offset(9);
    make.centerY.equalTo(radiusImgV);
    make.right.equalTo(bottomView).offset(-10);
  }];
  
  UIImageView *addressImgV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_radius"]];
  [bottomView addSubview:addressImgV];
  [addressImgV mas_makeConstraints:^(MASConstraintMaker *make) {
    make.leading.equalTo(radiusImgV);
    make.top.equalTo(radiusImgV.mas_bottom).offset(11);
    make.height.width.mas_equalTo(15);
  }];
  
  self.addressLb = [[UILabel alloc] init];
//  self.addressLb.text = @"北京市海淀区新中关购物中心";
  self.addressLb.textColor = [UIColor blackColor];
  self.addressLb.font = [UIFont fontWithName:@"PingFangSC-Regular" size:14];
  [bottomView addSubview:self.addressLb];
  [self.addressLb mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.equalTo(addressImgV.mas_right).offset(9);
    make.centerY.equalTo(addressImgV);
    make.right.equalTo(bottomView).offset(-10);
  }];
  
  self.mapView = [[MKMapView alloc] init];
  self.mapView.delegate = self;
  self.mapView.mapType = MKMapTypeStandard; //地图的类型 标准
  self.mapView.showsCompass = YES;  //显示指南针
  self.mapView.showsScale = YES;  //显示比例尺
  self.mapView.showsTraffic = YES;  //显示交通状况
  self.mapView.showsBuildings = YES;  //显示建筑物
  self.mapView.showsUserLocation = NO; //显示用户所在的位置
  self.mapView.showsPointsOfInterest = YES; //显示感兴趣的东西
  [self.view addSubview:self.mapView];
  [self.mapView mas_makeConstraints:^(MASConstraintMaker *make) {
    make.left.top.right.equalTo(self.view);
    make.bottom.equalTo(bottomView.mas_top);
  }];
  
  UIButton *backUserLocBtn = [UIButton buttonWithType:UIButtonTypeCustom];
  [backUserLocBtn setImage:[UIImage imageNamed:@"icon_GPS"] forState:UIControlStateNormal];
  [backUserLocBtn addTarget:self action:@selector(clickBack) forControlEvents:UIControlEventTouchUpInside];
  [self.mapView addSubview:backUserLocBtn];
  [backUserLocBtn mas_makeConstraints:^(MASConstraintMaker *make) {
    make.right.bottom.equalTo(self.mapView).offset(-10);
    make.width.height.mas_equalTo(44);
  }];
  
  // 添加长按手势 切换聚焦
  UILongPressGestureRecognizer *lpress = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPress:)];
  lpress.minimumPressDuration = 0.5;
  [_mapView addGestureRecognizer:lpress];
  
  // 添加搜索框
  UISearchBar *searchBar = [[UISearchBar alloc] init];
  searchBar.delegate = self;
  [self.mapView addSubview:searchBar];
  [searchBar mas_makeConstraints:^(MASConstraintMaker *make) {
    make.top.equalTo(self.mapView).offset(kStatusHeight);
    make.left.equalTo(self.mapView).offset(20);
    make.right.equalTo(self.mapView).offset(-20);
    make.height.mas_equalTo(44);
  }];
}

#pragma mark - 点击右下角按钮, 返回用户定位
- (void)clickBack {
  _followUserLoc = YES;
  [self focusMapTo:self.userCoordinate];
}

#pragma mark - 拖动半径大小
- (void)changedRadius:(UIButton *)button {
  CGPoint point = [button convertPoint:button.center toView:self.mapView];
  CLLocationCoordinate2D coordinate = [self.mapView convertPoint:point toCoordinateFromView:self.mapView];
  CLLocation *currentloc = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
  CLLocation *loc = [[CLLocation alloc] initWithLatitude:self.currentAnnotationView.annotation.coordinate.latitude longitude:self.currentAnnotationView.annotation.coordinate.longitude];
  CGFloat mi = [currentloc distanceFromLocation:loc];
  _radiusLb.text = [NSString stringWithFormat:@"当前安全半径：%.1f米", mi];
}

#pragma mark - 长按手势
- (void)longPress:(UIGestureRecognizer *)gestureRecognizer {
  if (gestureRecognizer.state == UIGestureRecognizerStateBegan) {
    CGPoint touchPoint = [gestureRecognizer locationInView:self.mapView];
    CLLocationCoordinate2D coordinate = [self.mapView convertPoint:touchPoint toCoordinateFromView:self.mapView];
    [self focusMapTo:coordinate];
    return;
  }
}

#pragma mark - 点击搜索
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
  CLGeocoder *geocoder = [[CLGeocoder alloc]init];
  NSString *addressStr = searchBar.text;  //位置信息
  // 地理编码
  [geocoder geocodeAddressString:addressStr completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
    if (error!=nil || placemarks.count==0) {
      return ;
    }
    //创建placemark对象
    CLPlacemark *placemark = [placemarks firstObject];
    [self focusMapTo:placemark.location.coordinate];
  }];
  [searchBar endEditing:YES];
}

#pragma mark - 返回大头针
- (MKAnnotationView *)mapView:(MKMapView *)mapView viewForAnnotation:(id<MKAnnotation>)annotation {
  if ([annotation isKindOfClass:[MKPointAnnotation class]]) {
    WWAnnotationView *annotationView = (WWAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"WWAnnotationView"];
    if (!annotationView) {
      annotationView = [[WWAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"WWAnnotationView"];
      annotationView.delegate = self;
    }
    _currentAnnotationView = annotationView;
    return annotationView;
  }
  return nil;
}

#pragma mark - 获得用户定位
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
  CLLocation *newLocation = locations.lastObject;
  self.userCoordinate = newLocation.coordinate;
  MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01); //地图显示比例尺
  MKCoordinateRegion region = MKCoordinateRegionMake(newLocation.coordinate, span); //地图显示区域
  [self.mapView setRegion:region];
  [self.mapView setUserTrackingMode:MKUserTrackingModeFollow animated:YES]; // follow
  [self.locationManager stopUpdatingLocation];

  [self reverseGeocodeWith:manager.location];  // 反地理编码
}

#pragma mark - 用户定位更新了
- (void)mapView:(MKMapView *)mapView didUpdateUserLocation:(MKUserLocation *)userLocation {
  self.userCoordinate = userLocation.coordinate;
  if (_followUserLoc) {
    [self focusMapTo:userLocation.coordinate];
    _followUserLoc = NO;
  }
}

#pragma mark - 聚焦到...
- (void)focusMapTo:(CLLocationCoordinate2D)coordinate {
  MKCoordinateSpan span = MKCoordinateSpanMake(0.01, 0.01); //地图显示比例尺
  MKCoordinateRegion region = MKCoordinateRegionMake(coordinate, span); //地图显示区域
  NSLog(@"focusMapTo %f %f", coordinate.latitude, coordinate.longitude);
  NSArray *anns = self.mapView.annotations;
  [self.mapView removeAnnotations:anns];
  for (id ann in self.mapView.annotations) {
    if (![ann isKindOfClass:[MKUserLocation class]]) {
      [self.mapView removeAnnotation:ann];
    }
  }
  
  MKPointAnnotation *ann = [[MKPointAnnotation alloc] init];
  ann.coordinate = coordinate;
  [self.mapView addAnnotation:ann];
  [self.mapView setRegion:region];
  [self.mapView setUserTrackingMode:MKUserTrackingModeNone animated:YES];
  
  CLLocation *loc = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];
  [self reverseGeocodeWith:loc];  // 反地理编码
}

#pragma mark - 反地理编码 (更新label text)
- (void)reverseGeocodeWith:(CLLocation *)location {
  CLGeocoder *gecoder = [[CLGeocoder alloc] init];
  __weak typeof(self) weakSelf = self;
  [gecoder reverseGeocodeLocation:location completionHandler:^(NSArray<CLPlacemark *> * _Nullable placemarks, NSError * _Nullable error) {
    if (error != nil || placemarks.count == 0) {
      NSLog(@"%@", error);
      return;
    }
    for (CLPlacemark *placemark in placemarks) {
      NSDictionary *addressDic = placemark.addressDictionary;
      NSString *addressStr = [NSString stringWithFormat:@"%@%@%@", addressDic[@"City"], addressDic[@"SubLocality"], addressDic[@"Street"]];
      weakSelf.addressLb.text = addressStr;
    }
  }];
}

#pragma mark - 为了检测地图放大缩小, 更新半径距离
- (void)mapView:(MKMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
  if (self.currentAnnotationView && [self.currentAnnotationView isKindOfClass:[WWAnnotationView class]]) {
    [self changedRadius:self.currentAnnotationView.touchBtn];
  }
}

@end
