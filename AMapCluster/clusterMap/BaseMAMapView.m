//
//  BaseMAMapView.m
//  operation4ios
//

#import "BaseMAMapView.h"

@interface BaseMAMapView ()

@end

@implementation BaseMAMapView

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        [self createUI];
    }
    return self;
}

- (void)awakeFromNib {
    [super awakeFromNib];
    [self createUI];
}

- (void)createUI {
    // 地图使用的公共设置
    self.showsCompass = false;
    self.rotateEnabled = false;
    self.rotateCameraEnabled = false;
    [self performSelector:@selector(setShowsWorldMap:) withObject:@YES];
//    [self performSelector:NSSelectorFromString(@"setMapLanguage:") withObject:@(1)];
}

@end
