//
//  ViewController.m
//  VeroPicViewDemo
//
//  Created by Veeco on 2019/6/13.
//  Copyright © 2019 Chance. All rights reserved.
//

#import "ViewController.h"
#import "VeroPicView.h"
#import "UIView+WGExtension.h"

@interface ViewController () <VeroPicViewDatasource, VeroPicViewDelegate>

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    VeroPicView *veroView = [VeroPicView new];
    [self.view addSubview:veroView];
    veroView.size = CGSizeMake(self.view.width, self.view.width);
    veroView.centerY = self.view.height / 2;
    veroView.datasource = self;
    veroView.delegate = self;
}

#pragma mark - <VeroPicViewDatasource>

/**
 刷新本控件时回调
 
 @param veroPicView 自身
 @return 数据源图片
 */
- (nullable NSArray<UIImage *> *)imagesInVeroPicView:(nonnull __kindof VeroPicView *)veroPicView {
    
    NSMutableArray<UIImage *> *arrM = @[].mutableCopy;
    for (int i = 1; i <= 5; i++) {
        
        UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%d.jpeg", i]];
        if (image) {
            
            [arrM addObject:image];
        }
    }
    return arrM;
}

#pragma mark - <VeroPicViewDelegate>

/**
 拖曳图片结束时回调
 
 @param veroPicView 自身
 @param beginIndex 起始下标
 @param endIndex 结束下标
 */
- (void)veroPicView:(nonnull __kindof VeroPicView *)veroPicView didDragItemFinishWithBeginIndex:(NSUInteger)beginIndex endIndex:(NSUInteger)endIndex {
    
    NSLog(@"%s, beginIndex = %zd, endIndex = %zd", __func__, beginIndex, endIndex);
}

/**
 点击图片回调
 
 @param veroPicView 自身
 @param index 下标
 */
- (void)veroPicView:(nonnull __kindof VeroPicView *)veroPicView didTapItemWithIndex:(NSInteger)index {
    
    NSLog(@"%s, index = %zd", __func__, index);
}

/**
 滑动结束后回调
 
 @param veroPicView 自身
 */
- (void)didScrollInVeroPicView:(nonnull __kindof VeroPicView *)veroPicView {
    
    NSLog(@"%s", __func__);
}

@end
