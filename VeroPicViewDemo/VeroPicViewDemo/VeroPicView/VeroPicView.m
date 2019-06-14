//
//  VeroPicView.m
//  Test3
//
//  Created by Veeco on 2018/7/30.
//  Copyright © 2018 Chance. All rights reserved.
//

#import "VeroPicView.h"
#import "UIView+WGExtension.h"

@interface VeroPicView () <UIScrollViewDelegate>

{
    /** SV */
    __weak UIScrollView *_SV;
    /** 数据源 */
    NSArray<UIImage *> *_imagesDatasource;
    /** 展示控件组 */
    NSArray<UIImageView *> *_items;
    /** 吉位的元素 */
    __weak UIImageView *_avoidItem;
    /** 吉位的元素下标 */
    NSUInteger _avoidIndex;
    /** 拖动的元素 */
    __weak UIImageView *_dragingItem;
    /** 吉位X */
    CGFloat _avoidPlaceX;
    /** 偏移计时器 */
    CADisplayLink *_timer;
    /** SV上的触点 */
    CGPoint _pointSV;
    /** 即将滑动松手时的x方向上的力度 最大暂定为4 */
    CGFloat _velocityX;
    /** 碰撞计数 */
    int _crashCount;
    /** 是否碰撞中(包含碰撞动画) */
    BOOL _crashing;
    /** 是否碰撞中结束拖曳 */
    BOOL _endWithCrashing;
    /** 碰撞中结束拖曳的SV触点 */
    CGPoint _endWithCrashingPointSV;
    /** 碰撞中结束拖曳的自身触点 */
    CGPoint _endWithCrashingPointSelf;
    /** 缩放时的聚焦元素 */
    UIImageView *_zoomFocusItem;
    /** 正在布局元素 */
    BOOL _layoutingItems;
    /** 布局元素计数 */
    int _layoutingItemsCount;
    /** 拖曳元素起始下标 */
    NSNumber *_dragBeginIndex;
    /** 拖曳元素结束下标 */
    NSNumber *_dragEndIndex;
    /** 显示子元素 */
    BOOL _showSubItems;
    /** 当前展示下标 */
    NSNumber *_currentIndex;
}

@end

// 默认元素距离
static const CGFloat kItemDis = 10;
// 动效时长
static const NSTimeInterval kAnimeTime = 0.2f;

@implementation VeroPicView

#pragma mark - <System>

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super initWithFrame:frame]) {
        
        // 容器
        UIScrollView *SV = [UIScrollView new];
        [self addSubview:SV];
        _SV = SV;
        SV.layer.masksToBounds = NO;
        SV.delegate = self;
        SV.alwaysBounceHorizontal = YES;
        SV.showsHorizontalScrollIndicator = NO;
        [self addGestureRecognizer:[[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(didLongPressSelf:)]];
        
        // 拖动的元素
        UIImageView *dragingItem = [UIImageView new];
        [self addSubview:dragingItem];
        dragingItem.contentMode = UIViewContentModeScaleAspectFill;
        _dragingItem = dragingItem;
        dragingItem.alpha = 0;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    
    _SV.frame = self.bounds;
    
    if (_items.count) {
        
        const CGFloat itemWHMax = _items.count > 1 ? _SV.height - 51 : _SV.height;
        const CGFloat itemWHMin = itemWHMax / 4;
        
        [_items enumerateObjectsUsingBlock:^(UIImageView * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            
            self->_layoutingItemsCount++;
            self->_layoutingItems = YES;
            
            CGFloat itemWidth = 0;
            CGFloat itemHeight = 0;
            
            if (item.width > item.height) { // 横图
                
                itemHeight = item.height * itemWHMax / item.width;
                itemWidth = itemWHMax;
                if (itemHeight < itemWHMin) {
                    
                    itemHeight = itemWHMin;
                }
            }
            else { // 竖图
                
                itemWidth = item.width * itemWHMax / item.height;
                itemHeight = itemWHMax;
                if (itemWidth < itemWHMin) {
                    
                    itemWidth = itemWHMin;
                }
            }
            
            // 布局元素
            [UIView animateWithDuration:kAnimeTime animations:^{
                
                item.size = CGSizeMake(itemWidth, itemHeight);
                item.centerY = self->_SV.height / 2;
                
                if (idx == 0) {
                    
                    item.x = (self->_SV.width - item.width) / 2;
                }
                else {
                    
                    CGFloat last = CGRectGetMaxX(self->_items[idx - 1].frame);
                    item.x = last + (self.itemDis ? self.itemDis : kItemDis);
                }
                
                if (item == self->_zoomFocusItem) {
                    
                    // 缩放时的偏移量
                    [self->_SV setContentOffset:CGPointMake(item.centerX - self->_SV.width / 2, 0)];
                    
                    // 缩放时的拖动元素动画
                    const CGFloat scale = 1;
                    self->_dragingItem.size = CGSizeMake(item.width * scale, item.height * scale);
                    self->_dragingItem.center = CGPointMake(item.center.x - self->_SV.contentOffset.x, item.center.y);
                    
                    // 记录缩小后的吉位值
                    self->_avoidPlaceX = item.x;
                    
                    self->_zoomFocusItem = nil;
                }
            } completion:^(BOOL finished) {
                
                if (--self->_layoutingItemsCount == 0) {
                    
                    self->_layoutingItems = NO;
                    self->_showSubItems = NO;
                    [UIView animateWithDuration:kAnimeTime animations:^{
                        
                        self.alpha = 1;
                    }];
                }
                if (idx == self->_items.count - 1) {
                    
                    self->_SV.contentSize = CGSizeMake(CGRectGetMaxX(item.frame) + (self->_SV.width - item.width) / 2, 0);
                }
            }];
        }];
    }
}

#pragma mark - <Normal>

- (NSNumber *)currentIndex {
    
    return _currentIndex;
}

- (void)setDatasource:(NSObject<VeroPicViewDatasource> *)datasource {
    _datasource = datasource;
    
    [self reloadData];
}

/**
 刷新UI
 */
- (void)reloadData {
    
    self.alpha = 0;
    
    [_items makeObjectsPerformSelector:@selector(removeFromSuperview)];
    NSArray *arr = [self.datasource imagesInVeroPicView:self];
    if (arr.count == 0) {
        
        arr = @[];
    }
    _imagesDatasource = arr;
    if (_imagesDatasource.count) {
        
        NSMutableArray *arrM = @[].mutableCopy;
        
        [_imagesDatasource enumerateObjectsUsingBlock:^(UIImage * _Nonnull image, NSUInteger idx, BOOL * _Nonnull stop) {
            
            UIImageView *item = [[UIImageView alloc] initWithImage:image];
            [self->_SV addSubview:item];
            [arrM addObject:item];
            item.userInteractionEnabled = YES;
            [item addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapItem:)]];
            item.layer.masksToBounds = YES;
            item.contentMode = UIViewContentModeScaleAspectFill;
        }];
        _items = arrM;
        [self setNeedsLayout];
        [self layoutIfNeeded];
        
        [self scrollViewDidEndDragging:self->_SV willDecelerate:NO];
    }
}

/**
 监听SV长按
 
 @param longPress 手势
 */
- (void)didLongPressSelf:(UILongPressGestureRecognizer *)longPress {
    
    if (_items.count <= 1) {
        
        return;
    }
    CGPoint pointSelf = [longPress locationInView:self];
    pointSelf = CGPointMake(pointSelf.x, self.height / 2);
    CGPoint pointSV = CGPointMake(pointSelf.x + _SV.contentOffset.x, pointSelf.y);
    
    switch (longPress.state) {
            
        case UIGestureRecognizerStateBegan:
        {
            [self dragBeginWithPointSV:pointSV pointSelf:pointSelf];
        }
            break;
            
        case UIGestureRecognizerStateChanged:
            
            [self dragChangedWithPointSV:pointSV pointSelf:pointSelf];
            
            break;
            
        case UIGestureRecognizerStateEnded:
        {
            [self dragEndWithPointSV:pointSV pointSelf:pointSelf];
        }
            break;
            
        default:
            break;
    }
}

/**
 计时器回调
 */
- (void)dida {
    
    if (_layoutingItems) {
        
        return;
    }
    CGFloat scale = ABS(_dragingItem.centerX - self.width / 2) / (self.width / 2);
    CGFloat maxSpeed = 10;
    CGFloat offsetPer = scale * maxSpeed;
    
    // 偏移视野
    if (_dragingItem.centerX < self.width / 2 && _SV.contentOffset.x > 0) {
        
        CGPoint offset = _SV.contentOffset;
        offset.x -= offsetPer;
        [_SV setContentOffset:offset animated:NO];
        self->_pointSV = CGPointMake(self->_pointSV.x - offsetPer, 0);
    }
    else if (_dragingItem.centerX > _SV.width / 2 && _SV.contentOffset.x < (_SV.contentSize.width - _SV.width)) {
        
        CGPoint offset = _SV.contentOffset;
        offset.x += offsetPer;
        [_SV setContentOffset:offset animated:NO];
        self->_pointSV = CGPointMake(self->_pointSV.x + offsetPer, 0);
    }
}

/**
 开启计时器
 */
- (void)timerOn {
    
    if (!_timer) {
        
        _timer = [CADisplayLink displayLinkWithTarget:self selector:@selector(dida)];
        [_timer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
    }
}

/**
 关闭计时器
 */
- (void)timerOff {
    
    [_timer invalidate];
    _timer = nil;
}

/**
 监听元素点击
 
 @param tap 手势
 */
- (void)didTapItem:(UITapGestureRecognizer *)tap {
    
    UIImageView *item = (UIImageView *)tap.view;
    if ([item isKindOfClass:[UIImageView class]] && item.image) {
        
        if (item.alpha == 1) {
            
            if ([self.delegate respondsToSelector:@selector(veroPicView:didTapItemWithIndex:)]) {
                [self.delegate veroPicView:self didTapItemWithIndex:[_items indexOfObject:item]];
            }
        }
    }
}

/**
 拖拽开始 找到被拖拽的item
 
 @param pointSV SV上的触碰点
 @param pointSelf 自身上的触碰点
 */
- (void)dragBeginWithPointSV:(CGPoint)pointSV pointSelf:(CGPoint)pointSelf {
    
    if (_layoutingItems) {
        
        return;
    }
    // 寻找点长按的元素
    [_items enumerateObjectsUsingBlock:^(UIImageView * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (CGRectContainsPoint(item.frame, pointSV) && item.alpha == 1) {
            
            // 记录起始下标
            self->_dragBeginIndex = @(idx);
            
            // 拖动的元素出现
            self->_dragingItem.size = CGSizeMake(item.width, item.height);
            self->_dragingItem.center = CGPointMake(item.center.x - self->_SV.contentOffset.x, item.center.y);
            self->_dragingItem.image = item.image;
            self->_dragingItem.alpha = 1;
            
            // 被长按的元素隐藏
            self->_avoidItem = item;
            self->_avoidItem.alpha = 0;
            
            // 记录全局变量
            self->_avoidIndex = idx;
            self->_zoomFocusItem = item;
            
            [UIView animateWithDuration:kAnimeTime animations:^{
                
                // 整体缩小
                CGFloat centerY = self.centerY;
                self.height /= 2;
                self.centerY = centerY;
                
            } completion:^(BOOL finished) {
                
                [self timerOn];
            }];
            *stop = YES;
        }
    }];
}

/**
 正在被拖拽
 
 @param pointSV SV上的触碰点
 @param pointSelf 自身上的触碰点
 */
- (void)dragChangedWithPointSV:(CGPoint)pointSV pointSelf:(CGPoint)pointSelf {
    
    if (!_avoidItem || _layoutingItems) {
        
        return;
    }
    _dragingItem.center = pointSelf;
    _pointSV = pointSV;
    
    // 寻找碰撞元素
    [_items enumerateObjectsUsingBlock:^(UIImageView * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        
        __block NSUInteger index = self->_avoidIndex;
        if (index != idx) {
            
            CGRect crashFrame = CGRectZero;
            
            // 吉位在左
            if (index < idx) {
                
                crashFrame = CGRectMake(item.x + item.width / 2, item.y, item.width / 2, item.height);
            }
            // 吉位在右
            else {
                
                crashFrame = CGRectMake(item.x, item.y, item.width / 2, item.height);
            }
            
            // 如果有碰撞区域内
            if (self->_avoidItem != item && CGRectContainsPoint(crashFrame, self->_pointSV)) {
                
                self->_crashCount++;
                self->_crashing = YES;
                
                __block CGFloat newAvoidPlaceX = item.x;
                __block CGFloat avoidPlaceX = self->_avoidPlaceX;
                const CGFloat itemDis = self.itemDis ? self.itemDis : kItemDis;
                
                [UIView animateWithDuration:kAnimeTime animations:^{
                    
                    // 吉位在左
                    if (index < idx) {
                        
                        UIImageView *afterItem = self->_items[index + 1];
                        
                        afterItem.x = avoidPlaceX;
                        newAvoidPlaceX = CGRectGetMaxX(afterItem.frame) + itemDis;
                        
                        index++;
                        
                        while (index < self->_items.count - 1) {
                            
                            afterItem = self->_items[index + 1];
                            
                            if (afterItem.x <= item.x) {
                                
                                afterItem.x = CGRectGetMaxX(self->_items[index].frame) + itemDis;
                                newAvoidPlaceX = CGRectGetMaxX(afterItem.frame) + itemDis;
                                
                                index++;
                            }
                            else {
                                
                                break;
                            }
                        }
                    }
                    
                    // 吉位在右
                    else {
                        
                        if (index != 0) {
                            
                            UIImageView *beforeItem = self->_items[index - 1];
                            
                            beforeItem.x = CGRectGetMaxX(self->_items[index].frame) - beforeItem.width;
                            
                            index--;
                            
                            while (index > 0) {
                                
                                beforeItem = self->_items[index - 1];
                                
                                if (beforeItem.x >= item.x) {
                                    
                                    beforeItem.x = self->_items[index].x - itemDis - beforeItem.width;
                                    
                                    index--;
                                }
                                else {
                                    
                                    break;
                                }
                            }
                        }
                    }
                } completion:^(BOOL finished) {
                    
                    self->_avoidPlaceX = newAvoidPlaceX;
                    self->_avoidItem.x = newAvoidPlaceX;
                    self->_avoidIndex = (int)idx;
                    [self sortItems];
                    if (--self->_crashCount == 0) {
                        
                        self->_crashing = NO;
                    }
                    if (self->_endWithCrashing) {
                        
                        [self dragEndWithPointSV:self->_endWithCrashingPointSV pointSelf:self->_endWithCrashingPointSelf];
                    }
                }];
                *stop = YES;
            }
        }
    }];
}

/**
 拖拽结束
 
 @param pointSV SV上的触碰点
 @param pointSelf 自身上的触碰点
 */
- (void)dragEndWithPointSV:(CGPoint)pointSV pointSelf:(CGPoint)pointSelf {
    
    if (!_avoidItem) {
        
        return;
    }
    
    if (_crashing) {
        
        _endWithCrashing = YES;
        _endWithCrashingPointSV = pointSV;
        _endWithCrashingPointSelf = pointSelf;
        
        return;
    }
    _endWithCrashing = NO;
    _endWithCrashingPointSV = CGPointZero;
    _endWithCrashingPointSelf = CGPointZero;
    
    [self timerOff];
    
    // 空白元素现形
    _avoidItem.center = pointSV;
    _avoidItem.alpha = 1;
    [_SV bringSubviewToFront:_avoidItem];
    
    // 隐藏拖动元素
    _dragingItem.alpha = 0;
    _dragingItem.image = nil;
    _dragingItem.frame = CGRectZero;
    
    // 重新排列
    [self sortItems];
    
    // 记录拖曳结束下标
    _dragEndIndex = @([_items indexOfObject:_avoidItem]);
    
    _zoomFocusItem = _avoidItem;
    _showSubItems = YES;
    
    [UIView animateWithDuration:kAnimeTime animations:^{
        
        CGFloat centerY = self.centerY;
        self.height *= 2;
        self.centerY = centerY;
        
    } completion:^(BOOL finished) {
        
        self->_avoidItem = nil;
        self->_avoidPlaceX = 0;
        self->_avoidIndex = 0;
        self->_pointSV = CGPointZero;
        self->_currentIndex = @([self findItemWhichShoudFucosOn]);
        
        if (self->_dragBeginIndex && self->_dragEndIndex) {
            
            NSUInteger beginIndex = self->_dragBeginIndex.unsignedIntegerValue;
            NSUInteger endIndex = self->_dragEndIndex.unsignedIntegerValue;
            
            if (beginIndex != endIndex) {
                
                if ([self.delegate respondsToSelector:@selector(veroPicView:didDragItemFinishWithBeginIndex:endIndex:)]) {
                    [self.delegate veroPicView:self didDragItemFinishWithBeginIndex:beginIndex endIndex:endIndex];
                }
            }
        }
    }];
}

/**
 排序
 */
- (void)sortItems {
    
    NSMutableArray *arrM = _items.mutableCopy;
    if (arrM.count) {
        
        _items = [arrM sortedArrayUsingComparator:^NSComparisonResult(UIImageView * _Nonnull obj1, UIImageView * _Nonnull obj2) {
            
            return obj1.centerX > obj2.centerX;
        }];
    }
}

/**
 设置SV偏移至目标元素上
 
 @param itemIndex 元素下标
 */
- (void)setOffsetFucosOnItemWithItemIndex:(NSUInteger)itemIndex {
    
    UIImageView *focusItem = _items[itemIndex];
    CGFloat offsetX = focusItem.x - (_SV.width - focusItem.width) / 2;
    [UIView animateWithDuration:kAnimeTime animations:^{
        
        [self->_items enumerateObjectsUsingBlock:^(UIImageView * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
            
            if (item != focusItem) {
                
                item.alpha = 0.3f;
            }
        }];
        focusItem.alpha = 1;
        [self->_SV setContentOffset:CGPointMake(offsetX, 0) animated:NO];
        
    } completion:^(BOOL finished) {
            
        self->_currentIndex = @(itemIndex);

        if ([self.delegate respondsToSelector:@selector(didScrollInVeroPicView:)]) {
            [self.delegate didScrollInVeroPicView:self];
        }
    }];
}

/**
 寻找应该对焦的元素
 
 @return 元素下标
 */
- (NSUInteger)findItemWhichShoudFucosOn {
    
    // 对焦
    __block CGFloat offset = CGFLOAT_MAX;
    __block NSUInteger index = 0;
    
    [self->_items enumerateObjectsUsingBlock:^(UIImageView * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        
        const CGFloat itemOffset = ABS(item.centerX - self->_SV.contentOffset.x - self->_SV.width / 2);
        
        if (itemOffset < offset) {
            
            offset = itemOffset;
            index = idx;
        }
        else {
            
            *stop = YES;
        }
    }];
    
    return index;
}

- (NSArray<UIImage *> *)images {
    
    if (!_items.count) {
        
        return nil;
    }
    NSMutableArray *images = @[].mutableCopy;
    [_items enumerateObjectsUsingBlock:^(UIImageView * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        
        if (idx != self->_items.count - 1) {
            
            [images addObject:item.image];
        }
    }];
    
    return images;
}

#pragma mark - <UIScrollViewDelegate>

- (void)scrollViewWillEndDragging:(UIScrollView *)scrollView withVelocity:(CGPoint)velocity targetContentOffset:(inout CGPoint *)targetContentOffset {
    
    if (_items.count == 0) {
        
        return;
    }
    
    // 记录力度
    _velocityX = velocity.x;
    if (_velocityX < 0) {
        
        _velocityX -= 0.5f;
    }
    else {
        
        _velocityX += 0.5f;
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate {
    
    if (_items.count == 0) {
        
        return;
    }
    
    if (!decelerate) {
        
        NSUInteger index = [self findItemWhichShoudFucosOn];
        [self setOffsetFucosOnItemWithItemIndex:index];
    }
    else {
        
        __block NSInteger index = [self findItemWhichShoudFucosOn];
        
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            [self->_SV setContentOffset:self->_SV.contentOffset animated:NO];
            
            int velocityX = (int)self->_velocityX;
            index += velocityX;
            if (index < 0) {
                
                index = 0;
            }
            else if (index > self->_items.count - 1) {
                
                index = self->_items.count - 1;
            }
            [self setOffsetFucosOnItemWithItemIndex:index];
        });
    }
}

@end
