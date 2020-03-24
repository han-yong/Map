//
//  ViewController.m
//  HYMapDemo
//
//  Created by Monk on 2020/3/23.
//  Copyright © 2020 Mac. All rights reserved.
//

#import "ViewController.h"
#import <MAMapKit/MAMapKit.h>
#import <AMapSearchKit/AMapSearchKit.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import "RankButton.h"

#define     Screen_Width         [UIScreen mainScreen].bounds.size.width
#define     Screen_Height        [UIScreen mainScreen].bounds.size.height
//获取状态栏的高度 iPhone X - 44pt  其他20pt
#define StatusBarHeight                     [[UIApplication sharedApplication] statusBarFrame].size.height

//获取导航栏的高度 - （不包含状态栏高度） 44pt
#define NavigationBarHeight                 self.navigationController.navigationBar.frame.size.height

//屏幕底部  tabBar高度49pt + 安全视图高度34pt(iPhone X)
#define TabbarHeight                        self.tabBarController.tabBar.frame.size.height

//屏幕顶部 导航栏高度（包含状态栏高度）
#define NavigationHeight                    (StatusBarHeight + NavigationBarHeight)

@interface ViewController ()<MAMapViewDelegate,AMapSearchDelegate>{
    CLLocation *_currentLocation;
    AMapNearbySearchManager *_nearbyManager;
    
    AMapSearchAPI *_search;
    RankButton *_currentButton;
    NSArray *_keArray;
}

@property (nonatomic, strong) MAMapView *mapView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.title = @"周边搜索";
    self.view.backgroundColor = [UIColor whiteColor];
    
    _keArray = @[@"餐厅",@"地铁",@"景区",@"酒店",@"商场",@"娱乐"];
    [self initMapViews];
    [self initSearchPoi];
    [self initButtons];
}

- (void)initSearchPoi {
    _search = [[AMapSearchAPI alloc] init];
    _search.delegate = self;
}

- (void)initMapViews {
    [AMapServices sharedServices].enableHTTPS = YES;
    ///初始化地图
    self.mapView = [[MAMapView alloc] initWithFrame:CGRectMake(0, NavigationHeight, Screen_Width, Screen_Height - NavigationHeight - 74)];
    self.mapView.delegate = self;
    self.mapView.compassOrigin = CGPointMake(_mapView.compassOrigin.x, 22);
    self.mapView.scaleOrigin = CGPointMake(_mapView.scaleOrigin.x, 22);
    [self.view addSubview:self.mapView];
    
    self.mapView.showsUserLocation = YES;
    self.mapView.userTrackingMode = MAUserTrackingModeNone;
    
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(30.307566, 120.097446);
    _currentLocation = [[CLLocation alloc] initWithLatitude:coordinate.latitude longitude:coordinate.longitude];;
    
    MAPointAnnotation *bigPoint = [[MAPointAnnotation alloc] init];
    bigPoint.coordinate = coordinate;
    bigPoint.title = @"标题";
    bigPoint.subtitle = @"介绍";
    [self.mapView addAnnotation:bigPoint];
    
    [self.mapView setCenterCoordinate:coordinate animated:YES];
    
    MACoordinateRegion viewRegion = MACoordinateRegionMakeWithDistance(coordinate,2000, 2000);
    MACoordinateRegion adjustedRegion = [self.mapView regionThatFits:viewRegion];
    [self.mapView setRegion:adjustedRegion animated:YES];
    
}

- (void)initSearchsWithTypes:(NSString *)types {
    if (_currentLocation == nil || _search == nil) {
        return;
    }
    
    AMapPOIAroundSearchRequest *request = [[AMapPOIAroundSearchRequest alloc] init];
    request.location = [AMapGeoPoint locationWithLatitude:_currentLocation.coordinate.latitude longitude:_currentLocation.coordinate.longitude];
    //    request.types = types;
    request.keywords = types;
    /* 按照距离排序. */
    request.sortrule = 0;
    request.requireExtension  = YES;
    [_search AMapPOIAroundSearch:request];
}

- (void)initButtons {
    
    for (int i = 0; i < _keArray.count; i ++) {
        RankButton *button = [RankButton buttonWithType:UIButtonTypeCustom];
        button.picTileRange = 5;
        button.tag = i + 100;
        button.type = buttonTypePicTop;
        [button setTitle:_keArray[i] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [button setTitleColor:[UIColor redColor] forState:UIControlStateSelected];
        button.frame = CGRectMake(Screen_Width/_keArray.count * i, Screen_Height - 64, Screen_Width/_keArray.count, 44);
        [button setImage:[UIImage imageNamed:_keArray[i]] forState:UIControlStateNormal];
        [button setImage:[UIImage imageNamed:[NSString stringWithFormat:@"%@-红",_keArray[i]]] forState:UIControlStateSelected];
        [button addTarget:self action:@selector(buttonClick:) forControlEvents:UIControlEventTouchUpInside];
        button.titleLabel.font = [UIFont systemFontOfSize:13];
        [self.view addSubview:button];
    }
}

#pragma mark --  MAMapViewDelegate
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view {
    //    if ([view.annotation isKindOfClass:[MAUserLocation class]]) {
    if (_currentLocation) {
        //反编码
        AMapReGeocodeSearchRequest *requst = [[AMapReGeocodeSearchRequest alloc] init];
        requst.location = [AMapGeoPoint locationWithLatitude:view.annotation.coordinate.latitude longitude:view.annotation.coordinate.longitude];
        [_search AMapReGoecodeSearch:requst];
    }
    //    }
}

- (void)mapView:(MAMapView *)mapView didUpdateUserLocation:(MAUserLocation *)userLocation updatingLocation:(BOOL)updatingLocation {
    //    _currentLocation = userLocation.location;
}

- (MAAnnotationView*)mapView:(MAMapView *)mapView viewForAnnotation:(id <MAAnnotation>)annotation;
{
    // 需要强制转化类型
    MAPinAnnotationView *annotationView = (MAPinAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:@"annotationID"];
    
    if (annotationView == nil) {
        annotationView = [[MAPinAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:@"annotationID"];
    }
    //    annotationView.pinColor = MAPinAnnotationColorGreen;
    annotationView.image = [UIImage imageNamed:@"location"];
    annotationView.canShowCallout = YES;       //设置气泡可以弹出，默认为NO
    annotationView.animatesDrop = YES;        //设置标注动画显示，默认为NO
    annotationView.draggable = YES;        //设置标注可以拖动，默认为NO
    annotationView.canShowCallout = YES;
    return annotationView;
}

#pragma mark --  AMapSearchDelegate
- (void)onPOISearchDone:(AMapPOISearchBaseRequest *)request response:(AMapPOISearchResponse *)response {
    
    //    if (response.pois.count == 0)
    //    {
    //        return;
    //    }
    
    NSArray* array = [NSArray arrayWithArray:self.mapView.annotations];
    [self.mapView removeAnnotations:array];
    
    for (AMapPOI *poi in response.pois) {
        [self ZuLinXing_creatAnnotationWithPont:poi.location poi:poi];
    }
}

- (void)onReGeocodeSearchDone:(AMapReGeocodeSearchRequest *)request response:(AMapReGeocodeSearchResponse *)response {
    NSString *str = response.regeocode.addressComponent.city;
    if (str.length == 0) {
        str = response.regeocode.addressComponent.province;
    }
    self.mapView.userLocation.title = str;
    self.mapView.userLocation.subtitle = response.regeocode.formattedAddress;
}

- (void)ZuLinXing_creatAnnotationWithPont:(AMapGeoPoint *)point poi:(AMapPOI *)poi{
    // 大头针里面具有属性
    MAPointAnnotation *bigPoint = [[MAPointAnnotation alloc] init];
    bigPoint.coordinate = CLLocationCoordinate2DMake(point.latitude, point.longitude);
    bigPoint.title = [NSString stringWithFormat:@"%@%@%@",poi.name,poi.district,poi.businessArea];
    bigPoint.subtitle = [NSString stringWithFormat:@"%@%@",poi.address,poi.indoorData.floorName ? : @""];
    // 把大头针加到地图上
    [_mapView addAnnotation:bigPoint];
}

#pragma mark -- buttonClick
- (void)buttonClick:(RankButton *)sender {
    _currentButton.selected = NO;
    sender.selected = YES;
    _currentButton = sender;
    [self initSearchsWithTypes:_keArray[sender.tag - 100]];
}


@end
