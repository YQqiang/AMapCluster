//
//  PointModel.h
//  AMapCluster
//
//  Created by sungrow on 2018/8/3.
//  Copyright © 2018年 sungrow. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>

@interface PointModel : NSObject<MKAnnotation>

@property (nonatomic, copy) NSString *latitude;
@property (nonatomic, copy) NSString *longitude;
@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

+ (NSArray <PointModel *>*)generateSampleData;

@end
