//
//  ClusterAnnotationView.h
//  operation4ios
//

#import <MAMapKit/MAMapKit.h>

@interface ClusterAnnotationView : MAAnnotationView

@property (nonatomic, assign) NSUInteger count;
/** 显示聚合的数字 */
@property (nonatomic, strong)UIButton *btn;

@end
