//
//  ViewController.m
//  AMapCluster
//
//  Created by sungrow on 2018/8/2.
//  Copyright © 2018年 sungrow. All rights reserved.
//

#import "ViewController.h"
#import "PointModel.h"
#import "ClusterAnnotation.h"
#import "ClusterAnnotationView.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self loadData];
}

- (void)loadData {
    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSMutableArray *annos = [NSMutableArray array];
        NSArray *datas = [PointModel generateSampleData];
        for (PointModel *model in datas) {
            ClusterAnnotation *anno = [[ClusterAnnotation alloc] initWithCoordinate:model.coordinate count:0];
            [annos addObject:anno];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [self creatZuoBiao: datas];
            [self.mapView showAnnotations:annos animated:YES];
        });
    });
}

- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation {
    if ([annotation isKindOfClass:[ClusterAnnotation class]]) {
        static NSString *const AnnotatioViewReuseID = @"AnnotatioViewReuseID";
        ClusterAnnotationView *annotationView = (ClusterAnnotationView *)[mapView dequeueReusableAnnotationViewWithIdentifier:AnnotatioViewReuseID];;
        if (!annotationView) {
            annotationView = [[ClusterAnnotationView alloc] initWithAnnotation:annotation reuseIdentifier:AnnotatioViewReuseID];
        }
        
        /* 设置annotationView的属性. */
        annotationView.annotation = annotation;
        ClusterAnnotation *clusterAnno = (ClusterAnnotation *)annotation;
        NSInteger clusterCount = clusterAnno.count;
        [annotationView.btn setBackgroundImage:[UIImage imageNamed:@"单车2"] forState:UIControlStateNormal];
        [annotationView.btn setBackgroundImage:[UIImage imageNamed:@"单车_红"] forState:UIControlStateSelected];
        [annotationView.btn sizeToFit];
        annotationView.btn.center = annotationView.btn.superview.center;
        [annotationView.btn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        annotationView.btn.titleLabel.numberOfLines = 2;
        annotationView.btn.titleLabel.textAlignment = NSTextAlignmentCenter;
        [annotationView.btn setTitle:[NSString stringWithFormat:@"%zd", clusterCount] forState:UIControlStateNormal];
        /* 不弹出原生annotation */
        annotationView.canShowCallout = NO;
        return annotationView;
    }
    return nil;
}

@end
