# VeroPicView
模仿Vero图片展示

#### 不废话直接看效果(长按后可拖曳图片进行换位)
![1.gif](https://upload-images.jianshu.io/upload_images/2404215-bb3c48ba7288d819.gif?imageMogr2/auto-orient/strip)

#### 使用方法
1. 由于继承自 UIView, 所以引用头文件后像一般控件般使用即可:
```objc
    VeroPicView *veroView = [VeroPicView new];
    [self.view addSubview:veroView];
    veroView.size = CGSizeMake(self.view.width, self.view.width);
    veroView.centerY = self.view.height / 2;
    veroView.datasource = self;
    veroView.delegate = self;
```
2. 类似 UITableView 实现对应的数据源方法:
```objc
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
```
3. 有需要的话可以实现对应的代理方法:
```objc
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
```
最后附上github地址
https://github.com/Veeco/VeroPicView

##### 最近忙着人生大事很少回复希望大家多多见谅, 如有意见或其它想法可以多多提出, 谢谢!
