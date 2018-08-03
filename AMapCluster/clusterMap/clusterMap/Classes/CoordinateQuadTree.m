//
//  CoordinateQuadTree.m
//  operation4ios
//

#import "CoordinateQuadTree.h"
#import "ClusterAnnotation.h"
#import <MapKit/MapKit.h>

void *debug_Ymalloc(char *fileName, int lineNumber, int size) {
    void *addr = malloc(size);
    NSLog(@"%@ %d addr=0x%08X size=%d", [NSString stringWithUTF8String:fileName], lineNumber, (uint32_t)addr, size);
    return addr;
}

#define malloc(size) debug_Ymalloc(__FILE__, __LINE__, size)

void debug_Yfree(char *fileName, int lineNumber, void *addr) {
    
    NSLog(@"%@ %d addr=0x%08X", [NSString stringWithUTF8String:fileName], lineNumber, (uint32_t)addr);
    free(addr);
}

//#define free(addr)  do{                                           \
//                        debug_Yfree(__FILE__, __LINE__, addr);    \
//                        addr = NULL;                              \
//                    }while(0)


QuadTreeNodeData QuadTreeNodeDataForAMapPOI(NSObject <MKAnnotation>*poi)
{
    return QuadTreeNodeDataMake(poi.coordinate.latitude, poi.coordinate.longitude, (__bridge_retained void *)(poi));
}

BoundingBox BoundingBoxForMapRect(MAMapRect mapRect)
{
    CLLocationCoordinate2D topLeft = MACoordinateForMapPoint(mapRect.origin);
    CLLocationCoordinate2D botRight = MACoordinateForMapPoint(MAMapPointMake(MAMapRectGetMaxX(mapRect), MAMapRectGetMaxY(mapRect)));
    
    CLLocationDegrees minLat = botRight.latitude;
    CLLocationDegrees maxLat = topLeft.latitude;
    
    CLLocationDegrees minLon = topLeft.longitude;
    CLLocationDegrees maxLon = botRight.longitude;
    
    return BoundingBoxMake(minLat, minLon, maxLat, maxLon);
}

float CellSizeForZoomLevel(double zoomLevel)
{
    /*zoomLevel越大，cellSize越小. */
    if (zoomLevel < 13.0)
    {
        return 64;
    }
    else if (zoomLevel <15.0)
    {
        return 32;
    }
    else if (zoomLevel <18.0)
    {
        return 16;
    }
    else if (zoomLevel < 20.0)
    {
        return 8;
    }
    
    return 64;
}

NSInteger TBZoomScaleToZoomLevel(MAZoomScale scale) {
    double totalTilesAtMaxZoom = MAMapSizeWorld.width / 256.0;
    NSInteger zoomLevelAtMaxZoom = log2(totalTilesAtMaxZoom);
    NSInteger zoomLevel = MAX(0, zoomLevelAtMaxZoom - floor(log2f(scale) + 0.5));
    
    return zoomLevel;
}

float TBCellSizeForZoomScale(MAZoomScale zoomScale) {
    NSInteger zoomLevel = TBZoomScaleToZoomLevel(zoomScale);
    NSLog(@">>>>>>> zoomLevel = %zd ", zoomLevel);
    switch (zoomLevel) {
        case 13:
        case 14:
        case 15:
            return 4;
        case 16:
        case 17:
        case 18:
            return 8;
        case 19:
        case 20:
            return 16;
        case 21:
        case 22:
            return 55;
        case 23:
        case 24:
        case 25:
        case 26:
            return 88;
        case 27:
        case 28:
        case 29:
            return 92;
        case 30:
            return 88;
        case 31:
        case 32:
        case 33:
        case 34:
        case 35:
        case 36:
            return 88;
        default:
            return 88;
    }
}

BoundingBox quadTreeNodeDataArrayForPOIs(QuadTreeNodeData *dataArray, NSMutableArray <NSObject <MKAnnotation>*>* pois)
{
    //此处要数组第一个元素的经纬度
        CLLocationDegrees minX = pois.firstObject.coordinate.latitude;
        CLLocationDegrees maxX = pois.firstObject.coordinate.latitude;

        CLLocationDegrees minY = pois.firstObject.coordinate.longitude;
        CLLocationDegrees maxY = pois.firstObject.coordinate.longitude;
    for (NSInteger i = 0; i < [pois count]; i++)
    {
        dataArray[i] = QuadTreeNodeDataForAMapPOI(pois[i]);
        //        NSLog(@"dataArray[i].x:%f",dataArray[i].x);
        //         NSLog(@"dataArray[i].y:%f",dataArray[i].y);
        if (dataArray[i].x < minX)
        {
            minX = dataArray[i].x;
        }
        
        if (dataArray[i].x > maxX)
        {
            maxX = dataArray[i].x;
        }
        
        if (dataArray[i].y < minY)
        {
            minY = dataArray[i].y;
        }
        
        if (dataArray[i].y > maxY)
        {
            maxY = dataArray[i].y;
        }
    }
    
    return BoundingBoxMake(minX, minY, maxX, maxY);
}

#pragma mark -

@implementation CoordinateQuadTree

#pragma mark Utility
/* 查询区域内数据的个数. */


- (NSArray *)clusteredAnnotationsWithinMapRect:(MAMapRect)rect withZoomScale:(double)zoomScale andZoomLevel:(double)zoomLevel
{
    double CellSize = TBCellSizeForZoomScale(zoomScale);
    double scaleFactor = zoomScale / CellSize;
    zoomLevel = TBZoomScaleToZoomLevel(zoomScale);
    NSLog(@">>>>>>> CellSize = %lf ", CellSize);
    NSLog(@">>>>>>> scaleFactor = %lf ", scaleFactor);
    
    NSInteger minX = floor(MAMapRectGetMinX(rect) * scaleFactor);
    NSInteger maxX = floor(MAMapRectGetMaxX(rect) * scaleFactor);
    NSInteger minY = floor(MAMapRectGetMinY(rect) * scaleFactor);
    NSInteger maxY = floor(MAMapRectGetMaxY(rect) * scaleFactor);
    
    NSMutableArray *clusteredAnnotations = [[NSMutableArray alloc] init];
    for (NSInteger x = minX; x <= maxX; x++)
    {
        for (NSInteger y = minY; y <= maxY; y++)
        {
            MAMapRect mapRect = MAMapRectMake(x / scaleFactor, y / scaleFactor, 1.0 / scaleFactor, 1.0 / scaleFactor);
            
            __block double totalX = 0;
            __block double totalY = 0;
            __block int     count = 0;
            
            NSMutableArray *pois = [[NSMutableArray alloc] init];
            
            /* 查询区域内数据的个数. */
            QuadTreeGatherDataInRange(self.root, BoundingBoxForMapRect(mapRect), ^(QuadTreeNodeData data)
                                      {
                                          totalX += data.x;
                                          totalY += data.y;
                                          count++;
                                          [pois addObject:(__bridge id _Nonnull)(data.data)];
                                      });
            
            /* 若区域内仅有一个数据. */
            if (count == 1)
            {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX, totalY);
                ClusterAnnotation *annotation = [[ClusterAnnotation alloc] initWithCoordinate:coordinate count:count];
                annotation.pois = pois;
                
                [clusteredAnnotations addObject:annotation];
            }
            
            /* 若区域内有多个数据 按数据的中心位置画点. */
            if (count > 1)
            {
                CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(totalX / count, totalY / count);
                ClusterAnnotation *annotation = [[ClusterAnnotation alloc] initWithCoordinate:coordinate count:count];
                annotation.pois  = pois;
                
                [clusteredAnnotations addObject:annotation];
            }
        }
    }
    
    return [NSArray arrayWithArray:clusteredAnnotations];
}

#pragma mark - cluster by distance

///按照annotation.coordinate之间的距离进行聚合
- (NSArray<ClusterAnnotation *> *)clusteredAnnotationsWithinMapRect:(MAMapRect)rect withDistance:(double)distance {
    __block NSMutableArray<NSObject<MKAnnotation>*> *allAnnotations = [[NSMutableArray alloc] init];
    QuadTreeGatherDataInRange(self.root, BoundingBoxForMapRect(rect), ^(QuadTreeNodeData data) {
        [allAnnotations addObject:(__bridge NSObject<MKAnnotation> * _Nonnull)(data.data)];
    });
    
    NSMutableArray<ClusterAnnotation *> *clusteredAnnotations = [[NSMutableArray alloc] init];
    for (NSObject<MKAnnotation> *aAnnotation in allAnnotations) {
        CLLocationCoordinate2D resultCoor = aAnnotation.coordinate;
        
        ClusterAnnotation *cluster = [self getClusterForAnnotation:aAnnotation inClusteredAnnotations:clusteredAnnotations withDistance:distance];
        if (cluster == nil) {
            ClusterAnnotation *aResult = [[ClusterAnnotation alloc] initWithCoordinate:resultCoor count:1];
            aResult.pois = @[aAnnotation].mutableCopy;
            
            [clusteredAnnotations addObject:aResult];
        } else {
            // 求多个坐标的中心位置,会出现聚合后重叠的bug
//            double totalX = cluster.coordinate.latitude * cluster.count + resultCoor.latitude;
//            double totalY = cluster.coordinate.longitude * cluster.count + resultCoor.longitude;
            NSInteger totalCount = cluster.count + 1;
            
            cluster.count = totalCount;
//            cluster.coordinate = CLLocationCoordinate2DMake(totalX / totalCount, totalY / totalCount);
            [cluster.pois addObject:aAnnotation];
        }
    }
    
    return clusteredAnnotations;
}

- (ClusterAnnotation *)getClusterForAnnotation:(NSObject<MKAnnotation> *)annotation inClusteredAnnotations:(NSArray<ClusterAnnotation *> *)clusteredAnnotations withDistance:(double)distance {
    if ([clusteredAnnotations count] <= 0 || annotation == nil) {
        return nil;
    }
    CLLocation *annotationLocation = [[CLLocation alloc] initWithLatitude:annotation.coordinate.latitude  longitude:annotation.coordinate.longitude];
    for (ClusterAnnotation *aCluster in clusteredAnnotations) {
        CLLocation *clusterLocation = [[CLLocation alloc] initWithLatitude:aCluster.coordinate.latitude longitude:aCluster.coordinate.longitude];
        double dis = [clusterLocation distanceFromLocation:annotationLocation];
        if (dis < distance) {
            return aCluster;
        }
    }
    
    return nil;
}

#pragma mark Initilization
// 2. 此处接受坐标点
- (void)buildTreeWithPOIs:(NSMutableArray <NSObject <MKAnnotation>*>*)pois
{
    //    NSLog(@"----pois.count:%ld",pois.count);
    QuadTreeNodeData *dataArray = malloc(sizeof(QuadTreeNodeData) * [pois count]);
    
    BoundingBox maxBounding = quadTreeNodeDataArrayForPOIs(dataArray, pois);
    
    /*若已有四叉树，清空.*/
    [self clean];
    
    NSLog(@"build tree.");
    /*建立四叉树索引. */ //从此有root
    self.root = QuadTreeBuildWithData(dataArray, [pois count], maxBounding, 4);
    
    free(dataArray);
    dataArray = NULL;
}

#pragma mark Life Cycle

- (void)clean
{
    if (self.root)
    {
        NSLog(@"free tree.");
        FreeQuadTreeNode(self.root);
    }
}

@end
