//
//  PointModel.m
//  AMapCluster
//
//  Created by sungrow on 2018/8/3.
//  Copyright © 2018年 sungrow. All rights reserved.
//

#import "PointModel.h"

@implementation PointModel

- (CLLocationCoordinate2D)coordinate {
    if (self.longitude.length > 0 && self.latitude.length > 0) {
        return CLLocationCoordinate2DMake([self.latitude floatValue], [self.longitude floatValue]);
    }
    return kCLLocationCoordinate2DInvalid;
}

+ (NSArray <PointModel *>*)generateSampleData {
    NSString *filePath = [[NSBundle mainBundle] pathForResource:@"PointSampleDatas" ofType:@"json"];
    NSURL *fileUrl = [NSURL fileURLWithPath:filePath];
    NSData *jsonData = [NSData dataWithContentsOfURL:fileUrl];
    NSArray *dataArr = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingAllowFragments error:nil];
    NSMutableArray <PointModel *>*models = [NSMutableArray array];
    [dataArr enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        PointModel *model = [[PointModel alloc] init];
        model.latitude = [obj[@"latitude"] stringValue];
        model.longitude = [obj[@"longitude"] stringValue];
        [models addObject:model];
    }];
    return models;
}

@end
