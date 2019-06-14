//
//  VeroPicView.h
//  Test3
//
//  Created by Veeco on 2018/7/30.
//  Copyright © 2018 Chance. All rights reserved.
//

#import <UIKit/UIKit.h>
@class VeroPicView;

@protocol VeroPicViewDatasource <NSObject>

/**
 刷新本控件时回调

 @param veroPicView 自身
 @return 数据源图片
 */
- (nullable NSArray<UIImage *> *)imagesInVeroPicView:(nonnull __kindof VeroPicView *)veroPicView;

@end

@protocol VeroPicViewDelegate <NSObject>

@optional

/**
 拖曳图片结束时回调
 
 @param veroPicView 自身
 @param beginIndex 起始下标
 @param endIndex 结束下标
 */
- (void)veroPicView:(nonnull __kindof VeroPicView *)veroPicView didDragItemFinishWithBeginIndex:(NSUInteger)beginIndex endIndex:(NSUInteger)endIndex;

/**
 点击图片回调
 
 @param veroPicView 自身
 @param index 下标
 */
- (void)veroPicView:(nonnull __kindof VeroPicView *)veroPicView didTapItemWithIndex:(NSInteger)index;

/**
 滑动结束后回调
 
 @param veroPicView 自身
 */
- (void)didScrollInVeroPicView:(nonnull __kindof VeroPicView *)veroPicView;

@end

@interface VeroPicView : UIView

/** 数据源 */
@property (nullable, nonatomic, weak) NSObject<VeroPicViewDatasource> *datasource;
/** 代理 */
@property (nullable, nonatomic, weak) NSObject<VeroPicViewDelegate> *delegate;
/** 设置元素间距(默认为10) */
@property (assign, nonatomic) CGFloat itemDis;
/** 图片数据 */
@property (nullable, nonatomic, readonly) NSArray<UIImage *> *images;
/** 当前展示下标 */
@property (nullable, nonatomic, strong, readonly) NSNumber *currentIndex;

/**
 刷新UI
 */
- (void)reloadData;

@end
