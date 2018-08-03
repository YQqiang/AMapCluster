//
//  BaseClusterViewController.h
//  operation4ios
//

#import <UIKit/UIKit.h>
#import "CoordinateQuadTree.h"
#import <MapKit/MapKit.h>
#import "BaseMAMapView.h"

@interface BaseClusterViewController : UIViewController;

@property (nonatomic, strong) BaseMAMapView *mapView;
@property (nonatomic, strong) CoordinateQuadTree *coordinateQuadTree;
@property (nonatomic, strong) NSMutableArray <NSObject <MKAnnotation>*>*selectedPoiArray;

- (void)creatZuoBiao:(NSArray <NSObject <MKAnnotation>*>*)ZuoBiao;
- (void)mapView:(MAMapView *)mapView didSelectAnnotationView:(MAAnnotationView *)view;
- (void)mapView:(MAMapView *)mapView didDeselectAnnotationView:(MAAnnotationView *)view;
- (MAAnnotationView *)mapView:(MAMapView *)mapView viewForAnnotation:(id<MAAnnotation>)annotation;
@end
