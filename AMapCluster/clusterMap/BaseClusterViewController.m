//
//  BaseClusterViewController.m
//  operation4ios
//

#import "BaseClusterViewController.h"
#import "ClusterAnnotationView.h"
#import "ClusterAnnotation.h"

@interface BaseClusterViewController ()<MAMapViewDelegate>

@property (nonatomic, assign) BOOL shouldRegionChangeReCalculate;

@end

@implementation BaseClusterViewController

- (BaseMAMapView *)mapView {
    if (!_mapView) {
        _mapView = [[BaseMAMapView alloc] init];
        _mapView.delegate = self;
    }
    return _mapView;
}

- (id)init {
    if (self = [super init]) {
        self.coordinateQuadTree = [[CoordinateQuadTree alloc] init];
        self.selectedPoiArray = [NSMutableArray array];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.coordinateQuadTree = [[CoordinateQuadTree alloc] init];
        self.selectedPoiArray = [NSMutableArray array];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.mapView];
    self.mapView.translatesAutoresizingMaskIntoConstraints = NO;
    [self.mapView.topAnchor constraintEqualToAnchor:self.view.topAnchor].active = YES;
    [self.mapView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor].active = YES;
    [self.mapView.leftAnchor constraintEqualToAnchor:self.view.leftAnchor].active = YES;
    [self.mapView.rightAnchor constraintEqualToAnchor:self.view.rightAnchor].active = YES;
    
    // 设置用户位置为地图中心点
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.3 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.mapView setCenterCoordinate:self.mapView.userLocation.coordinate animated:YES];
    });
    self.shouldRegionChangeReCalculate = NO;
}

- (void)dealloc {
    [self.coordinateQuadTree clean];
}

#pragma mark - update Annotation
/* 更新annotation. */
- (void)updateMapViewAnnotationsWithAnnotations:(NSArray *)annotations {
    /* 用户滑动时，保留仍然可用的标注，去除屏幕外标注，添加新增区域的标注 */
    NSMutableSet *before = [NSMutableSet setWithArray:self.mapView.annotations];
    [before removeObject:[self.mapView userLocation]];
    NSSet *after = [NSSet setWithArray:annotations];
    
    /* 保留仍然位于屏幕内的annotation. */
    NSMutableSet *toKeep = [NSMutableSet setWithSet:before];
    [toKeep intersectSet:after];
    
    /* 需要添加的annotation. */
    NSMutableSet *toAdd = [NSMutableSet setWithSet:after];
    [toAdd minusSet:toKeep];
    
    /* 删除位于屏幕外的annotation. */
    NSMutableSet *toRemove = [NSMutableSet setWithSet:before];
    [toRemove minusSet:after];
    
    /* 更新. */
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.mapView addAnnotations:[toAdd allObjects]];
        [self.mapView removeAnnotations:[toRemove allObjects]];
    });
}

- (void)addAnnotationsToMapView:(MAMapView *)mapView {
    @synchronized(self) {
        if (self.coordinateQuadTree.root == nil || !self.shouldRegionChangeReCalculate) {
            NSLog(@"tree is not ready.");
            return;
        }
        MAMapRect visibleRect = mapView.visibleMapRect;
        double distance = 50.f * [self.mapView metersPerPointForZoomLevel:self.mapView.zoomLevel];
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            /* 根据屏幕距离 进行annotation聚合. */
            NSArray *annotations = [weakSelf.coordinateQuadTree clusteredAnnotationsWithinMapRect:visibleRect withDistance:distance];
            /* 更新annotation. */
            [weakSelf updateMapViewAnnotationsWithAnnotations:annotations];
        });
    }
}

-(void)creatZuoBiao:(NSArray <NSObject <MKAnnotation>*>*)ZuoBiao {
    @synchronized(self) {
        self.shouldRegionChangeReCalculate = NO;
        // 清理
        [self.selectedPoiArray removeAllObjects];
        [self.mapView removeAnnotations:self.mapView.annotations];
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            // 1. 此处给出坐标点
            /* 建立四叉树. */
            [self.coordinateQuadTree buildTreeWithPOIs:ZuoBiao];
            self.shouldRegionChangeReCalculate = YES;
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.8 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [self addAnnotationsToMapView:self.mapView];
            });
        });
    }
}

#pragma mark - MAMapViewDelegate
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view {
    if (![view isKindOfClass:[ClusterAnnotationView class]]) return;
    ClusterAnnotation *annotation = (ClusterAnnotation *)view.annotation;
    if (mapView.zoomLevel < mapView.maxZoomLevel && annotation.pois.count > 1) {
        [mapView deselectAnnotation:annotation animated:NO];
        // 若有点聚合, 则直接下钻到能够显示所有点的地图层级
        NSMutableArray *tempAnnos = [NSMutableArray array];
        for (NSObject<MKAnnotation>*mapPs in annotation.pois) {
            ClusterAnnotation *anno = [[ClusterAnnotation alloc] initWithCoordinate:mapPs.coordinate count:0];
            [tempAnnos addObject:anno];
        }
        [mapView showAnnotations:tempAnnos animated:YES];
        return;
    }
    ((ClusterAnnotationView *)view).btn.selected = YES;
    for (NSObject<MKAnnotation>*mapPs in annotation.pois) {
        [self.selectedPoiArray addObject:mapPs];
    }
}

- (void)mapView:(MAMapView *)mapView didDeselectAnnotationView:(MAAnnotationView *)view {
    [self.selectedPoiArray removeAllObjects];
    if (![view isKindOfClass:[ClusterAnnotationView class]]) return;
    ((ClusterAnnotationView *)view).btn.selected = false;
}

- (void)mapView:(MAMapView *)mapView regionDidChangeAnimated:(BOOL)animated {
    [self addAnnotationsToMapView:self.mapView];
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {
    if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        /* dequeue重用annotationView. */
        static NSString *const AnnotatioViewReuseID = @"AnnotatioViewReuseID";
        ClusterAnnotationView *annotationView = (ClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotatioViewReuseID];
        if (!annotationView) {
            annotationView = [[ClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotatioViewReuseID];
        }
        
        /* 设置annotationView的属性. */
        annotationView.annotation = annotation;
        annotationView.count = [(ClusterAnnotation *)annotation count];
        /* 不弹出原生annotation */
        annotationView.canShowCallout = NO;
        return annotationView;
    }
    return nil;
}

@end
