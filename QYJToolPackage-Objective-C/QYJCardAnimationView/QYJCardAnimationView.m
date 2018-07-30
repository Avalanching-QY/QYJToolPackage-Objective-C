//
//  QYJCardAnimationView.m
//  QYJToolPackage-Objective-C
//
//  Created by Avalanching on 2018/7/26.
//  Copyright © 2018年 Avalanching. All rights reserved.
//

#import "QYJCardAnimationView.h"

static CGFloat viewinterval = 15.0f;

static CGFloat viewScale = 0.04f;

@interface QYJCardAnimationView ()

/**
 * CardAnimationView的风格
 */
@property (nonatomic, assign) QYJCardAnimationViewStyle style;

/**
 * 当前第一个View
 */
@property (nonatomic, strong) QYJCardAnimationNillView *topView;

/**
 * 被推出的View
 */
@property (nonatomic, strong) QYJCardAnimationNillView *pushView;

/**
 * 用于存放没有推出界面的view的数组
 */
@property (nonatomic, strong) NSMutableArray<QYJCardAnimationNillView *> *viewsContainer;

/**
 * 当前第几张
 */
@property (nonatomic, assign) NSInteger currentCount;

/**
 * 最大的元素个数
 */
@property (nonatomic, assign) NSInteger maxCount;

/**
 *  界面上还未推出的个数
 */
@property (nonatomic, assign) NSInteger displayCount;

/**
 * 第一个显示的View的中心点
 */
@property (nonatomic, assign) CGPoint topViewCenter;

/**
 * 推出的View的中心点
 */
@property (nonatomic, assign) CGPoint pushViewCenter;

/**
 * 中心点
 */
@property (nonatomic, assign) CGPoint viewCenterPoint;

/**
 * 是否可以移动
 */
@property (nonatomic, assign) BOOL moveEnable;

/**
 * 是否循环
 */
@property (nonatomic, assign) BOOL cycleEnable;

/**
 * 是否忽略手势
 */
@property (nonatomic, assign) BOOL ignoreGestures;

/**
 * 是否刷新全部
 */
@property (nonatomic, assign) BOOL reloadAll;

/**
 * 第一个卡牌的大小
 */
@property (nonatomic, assign) CGSize viewSize;

/**
 * 缓存池水
 */
@property (nonatomic, strong) NSMutableDictionary *cachePool;

/**
 * 记录大小
 */
@property (nonatomic, assign) CGRect lastFrame;

@end

@implementation QYJCardAnimationView

- (instancetype)initWithStyle:(QYJCardAnimationViewStyle)style {
    self = [super init];
    if (self) {
        _style = style;
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    _currentCount = 0;
    _maxCount = 0;
    _displayCount = 0;
    _cycleEnable = NO;
    _viewSize = CGSizeZero;
    _reloadAll = YES;
    _displayCount = 5;
}

// 大小改变了 重新布局
- (void)layoutSubviews {
    [super layoutSubviews];
    _viewCenterPoint = CGPointMake(self.frame.size.width / 2.0, self.frame.size.height / 2.0);
    if (_reloadAll) {
        // 重新布局
        [self commonInit];
        [self addSubviewToWindows];
        self.lastFrame = self.frame;
    } else {
        // 调整当前的布局
        [self adjustmentSubViewFrame];
    }
}

#pragma mark - public

- (void)resetDataSource {
    [self commonInit];
    for (QYJCardAnimationNillView *view in self.viewsContainer.reverseObjectEnumerator) {
        [view removeFromSuperview];
        [self addCachePoolWithView:view];
    }
    for (QYJCardAnimationNillView *view in self.subviews) {
        [view removeFromSuperview];
    }
    [self addSubviewToWindows];
}

- (void)reloadAllDataSource {
    [self addSubviewToWindows];
}

- (QYJCardAnimationNillView *)dequeueReusableViewWithIdentifier:(NSString *)identifier {
    if (!self.cachePool) {
        return nil;
    }
    
    if (!identifier) {
        return nil;
    }
    
    NSArray *array = [self.cachePool objectForKey:identifier];
    if ([array isKindOfClass:[NSArray class]]) {
        if (array.count > 0) {
            NSMutableArray *temp = array.mutableCopy;
            QYJCardAnimationNillView *view = temp.firstObject;
            [temp removeObject:view];
            [self.cachePool setObject:temp forKey:identifier];
            return view;
        }
    }
    return nil;
}

#pragma mark - private

- (void)viewAddGestureWithView:(UIView *)view {
    
    view.layer.borderColor = [UIColor colorWithRed:223.0 / 255.0 green:224.0 / 255.0 blue:225 / 255.0 alpha:1].CGColor;
    view.layer.borderWidth = 1;
    view.layer.shadowColor = [UIColor lightGrayColor].CGColor;
    view.layer.shadowOpacity = 0.6;
    view.layer.shadowOffset = CGSizeMake(0, 1);
    view.alpha = 1;
    
    // 清除手势
    for (UIGestureRecognizer *ges in view.gestureRecognizers.objectEnumerator) {
        [view removeGestureRecognizer:ges];
    }
    
    // 添加手势
    UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panGestureRecognizerAction:)];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didSelectCard:)];
    [view addGestureRecognizer:pan];
    [view addGestureRecognizer:tap];
}

/**
 * 删除所有的子view
 */
- (void)removeAllSubView {
    _pushView = nil;
    _viewsContainer = @[].mutableCopy;
    _cachePool = @{}.mutableCopy;
    for (UIView *view in self.subviews) {
        [view removeFromSuperview];
    }
}

- (void)addSubviewToWindows {
    // 获取基本数据
    // 获取个数
    if ([self.dataSource respondsToSelector:@selector(rowNumberOfcardAnimationView)]) {
        _maxCount = [self.dataSource rowNumberOfcardAnimationView];
    }
    
    if (_maxCount == 0) {
        [self removeAllSubView];
        return;
    }
    
    // 获取第一个的大小
    if ([self.dataSource respondsToSelector:@selector(sizeOfRowInCardAnimationView)]) {
        _viewSize = [self.dataSource sizeOfRowInCardAnimationView];
    }
    
    if (self.currentCount > 0) {
        // 已经加载过了
        
        if (self.currentCount >= _maxCount - 1) {
            // 加载到最后一张
            self.currentCount = _maxCount - 1;
            if (self.viewsContainer.count > 0) {
                if ([self.dataSource respondsToSelector:@selector(cardAnimationView:viewForRowAtIndexPath:)]) {
                    self.topView = [self.dataSource cardAnimationView:self viewForRowAtIndexPath:self.currentCount];
                    self.topView.alpha = 1;
                }
                for (QYJCardAnimationNillView *view in self.viewsContainer) {
                    // 加入缓存池
                    [view removeFromSuperview];
                    [self addCachePoolWithView:view];
                }
                // 重塑显示数组
                self.viewsContainer = @[self.topView].mutableCopy;
                self.topView.frame = CGRectMake(0, 0, _viewSize.width, _viewSize.height);
                self.topView.center = self.viewCenterPoint;
                [self viewAddGestureWithView:self.topView];
                [self addSubview:self.topView];
            }
        } else {
            
            // 补全不够张数
            NSInteger currentDisplayCount = self.viewsContainer.count;
            NSInteger subCount = _maxCount - _currentCount;
            if (currentDisplayCount == self.displayCount) {
                return;
            }
            
            NSInteger addCount = self.displayCount - currentDisplayCount;
            if (addCount >= subCount) {
                addCount = subCount;
            }
            
            for (NSInteger i = 0; i < addCount; i++) {
                QYJCardAnimationNillView *view = nil;
                if ([self.dataSource respondsToSelector:@selector(cardAnimationView:viewForRowAtIndexPath:)]) {
                    view = [self.dataSource cardAnimationView:self viewForRowAtIndexPath:_currentCount + i + currentDisplayCount];
                }
                if (view == nil) {
                    return;
                }
                view.frame = CGRectMake(0, 0, _viewSize.width, _viewSize.height);
                view.center = CGPointMake(_viewCenterPoint.x + ((currentDisplayCount + i) * [self horizontalIncrement]), _viewCenterPoint.y + ((currentDisplayCount + i) * [self verticalIncrement]));
                view.transform = CGAffineTransformMakeScale(1 - ((i + currentDisplayCount) * viewScale), 1 - ((i + currentDisplayCount) * viewScale));
                [self viewAddGestureWithView:view];
                [self.viewsContainer addObject:view];
                [self addSubview:view];
                [self sendSubviewToBack:view];
            }
            
        }
        return;
    }
    
    // 删除子视图
    [self.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSInteger displaycount = 5;
    if (displaycount > _maxCount) {
        displaycount = _maxCount;
    }
    // 初始化缓存池
    self.cachePool = @{}.mutableCopy;
    self.viewsContainer = @[].mutableCopy;
    for (NSInteger i = 0; i < displaycount + 1; i++) {
        QYJCardAnimationNillView *view = nil;
        if ([self.dataSource respondsToSelector:@selector(cardAnimationView:viewForRowAtIndexPath:)]) {
            view = [self.dataSource cardAnimationView:self viewForRowAtIndexPath:i];
            view.frame = CGRectMake(0, 0, _viewSize.width, _viewSize.height);
        }
        // 防止返回了一个nil导致崩溃
        if (!view) {
            view = [[QYJCardAnimationNillView alloc] initWithFrame:CGRectMake(0, 0, _viewSize.width, _viewSize.height)];
            view.backgroundColor = [UIColor orangeColor];
        }
        
        view.center = CGPointMake(_viewCenterPoint.x + (i * [self horizontalIncrement]), _viewCenterPoint.y + (i * [self verticalIncrement]));
        
        view.transform = CGAffineTransformMakeScale(1 - (i * viewScale), 1 - (i * viewScale));
        
        [self viewAddGestureWithView:view];
        
        // 布局
        if (i < displaycount) {
            // 首先显示界面上的
            [self.viewsContainer addObject:view];
            [self addSubview:view];
            [self sendSubviewToBack:view];
        } else {
            // 界面显示玩了存入缓存池
            [self addCachePoolWithView:view];
        }
    }
    
    self.topView = self.viewsContainer[0];
    self.topViewCenter = self.topView.center;
    self.reloadAll = NO;
}

- (void)adjustmentSubViewFrame {
    
    if (!CGRectEqualToRect(self.frame, self.lastFrame)) {
        CGFloat x = self.viewCenterPoint.x - CGRectGetWidth(self.frame) / 2.0 - CGRectGetWidth(self.pushView.frame) / 2.0;
        CGFloat y = self.viewCenterPoint.y;
        self.pushViewCenter = CGPointMake(x, y);
        
        x = (self.bounds.size.width / 2.0);
        y = self.bounds.size.height / 2.0;
        self.viewCenterPoint = CGPointMake(x, y);
        
        for (NSInteger i = 0; i < self.viewsContainer.count; i++) {
            QYJCardAnimationNillView *view = self.viewsContainer[i];
            x = self.viewCenterPoint.x + (i * [self horizontalIncrement]);
            y = self.viewCenterPoint.y + (i * [self verticalIncrement]);
            view.center = CGPointMake(x, y);
        }
        self.lastFrame = self.frame;
    }
}

- (BOOL)addCachePoolWithView:(QYJCardAnimationNillView *)view {
    view.alpha = 1;
    view.hidden = NO;
    NSString *identifier = [view getIdentifier];
    NSMutableArray *array = [self.cachePool objectForKey:identifier];
    if (array.count == 0 || !array) {
        array = @[].mutableCopy;
    }
    [array addObject:view];
    [self.cachePool setObject:array forKey:identifier];
    
    return YES;
}

#pragma mark - increment

- (CGFloat)horizontalIncrement {
    if (self.style == QYJCardAnimationViewStyleTransverse) {
        return viewinterval;
    } else if (self.style == QYJCardAnimationViewStylePortraitUp) {
        return 0;
    } else if (self.style == QYJCardAnimationViewStylePortraitDown) {
        return 0;
    } else {
        return 0;
    }
}

- (CGFloat)verticalIncrement {
    if (self.style == QYJCardAnimationViewStylePortraitDown) {
        return viewinterval;
    } else if (self.style == QYJCardAnimationViewStylePortraitUp) {
        return -viewinterval;
    } else {
        return 0;
    }
}

#pragma mark - GestureRecognizer Action

- (void)panGestureRecognizerAction:(UIPanGestureRecognizer *)gesture {
    if (self.currentCount >= self.maxCount && !self.cycleEnable) {
        return;
    }
    CGPoint transition = [gesture translationInView:self.topView];
    if (gesture.state == UIGestureRecognizerStateBegan) {
        [self panGestureRecognizerStateStart:gesture transition:transition];
    } else if (gesture.state == UIGestureRecognizerStateChanged) {
        [self panGestureRecognizerStateChange:gesture transition:transition];
    } else if (gesture.state == UIGestureRecognizerStateEnded) {
        [self panGestureRecognizerStateEnd:gesture transition:transition];
    } else {
        [self panGestureRecognizerStateEnd:gesture transition:transition];
    }
}

- (void)didSelectCard:(UITapGestureRecognizer *)tap {
    if ([self.delegate respondsToSelector:@selector(cardAnimationView:didSelectRowAtIndex:)]) {
        [self.delegate cardAnimationView:self didSelectRowAtIndex:self.currentCount];
    }
}

#pragma mark - Animation
// 手势开始
- (void)panGestureRecognizerStateStart:(UIPanGestureRecognizer *)panGesture transition:(CGPoint)transition {
    if (transition.x < 0) {
        if (self.currentCount >= self.maxCount - 1) {
            self.moveEnable = NO;
            self.ignoreGestures = YES;
        } else {
            self.ignoreGestures = NO;
            self.moveEnable = YES;
        }
    } else if (transition.x > 0) {
        self.moveEnable = NO;
        self.ignoreGestures = NO;
        if (self.currentCount > 0) {
            // 手势相应上一张卡片
            if ([self.dataSource respondsToSelector:@selector(cardAnimationView:viewForRowAtIndexPath:)]) {
                self.pushView = [self.dataSource cardAnimationView:self viewForRowAtIndexPath:self.currentCount - 1];
                [self viewAddGestureWithView:self.pushView];
            }
            
            // 设置卡片
            self.pushView.frame = CGRectMake(0, 0, self.viewSize.width, self.viewSize.height);
            self.pushViewCenter = CGPointMake(_viewCenterPoint.x - CGRectGetWidth(self.frame) / 2.0 - CGRectGetWidth(_pushView.frame) / 2.0, _viewCenterPoint.y);
            self.pushView.center = self.pushViewCenter;
            self.pushView.transform = CGAffineTransformMakeScale(1.0, 1.0);
            [self addSubview:self.pushView];
            
            __weak __typeof(self) weakSelf = self;
            for (NSInteger i = 0; i < self.viewsContainer.count; i ++) {
                QYJCardAnimationNillView *view = self.viewsContainer[i];
                CGPoint center = view.center;
                center.x = self.viewCenterPoint.x + (i * [self horizontalIncrement]);
                center.y = self.viewCenterPoint.y + (i * [self verticalIncrement]);
                [UIView animateWithDuration:0.25 animations:^{
                    view.center = center;
                    view.transform = CGAffineTransformMakeScale(1.0 - (i + 1) * viewScale, 1.0 - (i + 1) * viewScale);
                    if (i == weakSelf.viewsContainer.count - 1) {
//                        view.alpha = 0;
                    }
                }];
            }
        }
    } else {
        self.moveEnable = NO;
        self.ignoreGestures = YES;
    }
}

// 手势改变
- (void)panGestureRecognizerStateChange:(UIPanGestureRecognizer *)panGesture transition:(CGPoint)transition {
    if (self.ignoreGestures) {
        return;
    }
    
    if (self.moveEnable) {
        CGPoint center = self.topView.center;
        center.x = self.viewCenterPoint.x + transition.x;
        self.topView.center = center;
    } else {
        if (self.currentCount > 0) {
            CGPoint center = self.pushView.center;
            center.x = self.pushViewCenter.x + transition.x;
            self.pushView.center = center;
        }
    }
}

// 手势结束
- (void)panGestureRecognizerStateEnd:(UIPanGestureRecognizer *)panGesture transition:(CGPoint)transition {
    if (_ignoreGestures) {
        return;
    }
    if (self.moveEnable) {
        self.topViewCenter = self.topView.center;
        if (self.topViewCenter.x < self.viewCenterPoint.x - 50.0) {
            __weak __typeof(self)weakSelf = self;
            CGPoint center = self.topView.center;
            center.x = (-CGRectGetWidth(self.topView.frame) - CGRectGetWidth(self.frame)) / 2.0;
            
            // 调整每个试图大小 和 距离
            [UIView animateWithDuration:0.25 animations:^{
                __strong __typeof(self)strongSelf = weakSelf;
                strongSelf.topView.center = center;
                for (NSInteger i = 1; i < strongSelf.viewsContainer.count; i++) {
                    QYJCardAnimationNillView *view = self.viewsContainer[i];
                    if (view != strongSelf.topView) {
                        NSInteger index = i - 1;
                        CGPoint subviewcenter = view.center;
                        subviewcenter.y = strongSelf.viewCenterPoint.y + (index * [strongSelf verticalIncrement]);
                        subviewcenter.x = strongSelf.viewCenterPoint.x + (index * [strongSelf horizontalIncrement]);
                        CGFloat scale = 1.0 - (i - 1) * viewScale;
                        view.transform = CGAffineTransformMakeScale(scale, scale);
                        view.center = subviewcenter;
                    }
                }
            } completion:^(BOOL finished) {
                __strong __typeof(self)strongSelf = weakSelf;
                if (strongSelf.maxCount - strongSelf.currentCount > strongSelf.displayCount) {
                    QYJCardAnimationNillView *view = nil;
                    
                    if ([strongSelf.dataSource respondsToSelector:@selector(cardAnimationView:viewForRowAtIndexPath:)]) {
                        view = [strongSelf.dataSource cardAnimationView:strongSelf viewForRowAtIndexPath:(strongSelf.currentCount + strongSelf.displayCount)];
                        [strongSelf viewAddGestureWithView:view];
                    }
                    view.frame = CGRectMake(0, 0, strongSelf.viewSize.width, strongSelf.viewSize.height);
                    view.center = CGPointMake(strongSelf.viewCenterPoint.x + ((strongSelf.displayCount - 1) * [strongSelf horizontalIncrement]), strongSelf.viewCenterPoint.y + ((strongSelf.displayCount - 1) * [strongSelf verticalIncrement]));
                    
                    CGFloat scale = 1.0 - (strongSelf.displayCount - 1) * viewScale;
                    view.transform = CGAffineTransformMakeScale(scale, scale);
                    [strongSelf addSubview:view];
                    [strongSelf sendSubviewToBack:view];
                    [strongSelf.viewsContainer addObject:view];
                }
                strongSelf.pushView = strongSelf.topView;
                strongSelf.pushViewCenter = strongSelf.topView.center;
                [strongSelf.viewsContainer removeObject:strongSelf.pushView];
                [strongSelf.pushView removeFromSuperview];
                [strongSelf addCachePoolWithView:strongSelf.pushView];
                
                strongSelf.topView = strongSelf.viewsContainer[0];
                strongSelf.topViewCenter = strongSelf.topView.center;
                
                strongSelf.currentCount ++;
            }];
        } else {
            CGPoint center = self.topView.center;
            center.x = self.viewCenterPoint.x;
            [UIView animateWithDuration:0.25 animations:^{
                self.topView.center = center;
            } completion:^(BOOL finished) {
                self.topViewCenter = self.topView.center;
            }];
        }
    } else {
        if (self.currentCount > 0) {
            if (self.pushView.center.x >= self.viewCenterPoint.x - CGRectGetWidth(self.pushView.frame) * 3 / 4.0) {
                __weak __typeof(self) weakSelf = self;
                [UIView animateWithDuration:0.25 animations:^{
                    __strong __typeof(self) strongSelf = weakSelf;
                    strongSelf.pushView.center = strongSelf.viewCenterPoint;
                    for (NSInteger i = 0; i < strongSelf.viewsContainer.count; i++) {
                        QYJCardAnimationNillView *view = self.viewsContainer[i];
                        NSInteger index = i + 1;
                        CGPoint subviewcenter = view.center;
                        subviewcenter.y = strongSelf.viewCenterPoint.y + (index * [strongSelf verticalIncrement]);
                        subviewcenter.x = strongSelf.viewCenterPoint.x + (index * [strongSelf horizontalIncrement]);
                        view.center = subviewcenter;
                        if (i == 0) {
                            CGFloat scale = 1.0 - (1 * viewScale);
                            view.transform = CGAffineTransformMakeScale(scale, scale);
                        } else {
                            CGFloat scale = 1.0 - (++index - 1) * viewScale;
                            view.transform = CGAffineTransformMakeScale(scale, scale);
                        }
                    }
                } completion:^(BOOL finished) {
                    __strong __typeof(self) strongSelf = weakSelf;
                    [strongSelf.viewsContainer insertObject:strongSelf.pushView atIndex:0];
                    strongSelf.topView = strongSelf.pushView;
                    if (strongSelf.viewsContainer.count > strongSelf.displayCount) {
                        strongSelf.pushView = strongSelf.viewsContainer.lastObject;
                        [strongSelf.viewsContainer removeObject:strongSelf.pushView];
                        [strongSelf.pushView removeFromSuperview];
                        [strongSelf addCachePoolWithView:strongSelf.pushView];
                    }
                    strongSelf.currentCount --;
                }];
            } else {
                __weak __typeof(self)weakSelf = self;
                for (NSInteger i = 0; i < self.viewsContainer.count ; i++) {
                    QYJCardAnimationNillView *view = self.viewsContainer[i];
                    [UIView animateWithDuration:0.25 animations:^{
                        __strong __typeof(self)strongSelf = weakSelf;
                        CGPoint center = view.center;
                        center.y -= [self verticalIncrement];
                        center.x -= [self horizontalIncrement];
                        view.center = center;
                        CGFloat scale = 1.0 - i * viewScale;
                        view.transform = CGAffineTransformMakeScale(scale, scale);
                        if (1 == strongSelf.viewsContainer.count - 1) {
                            view.alpha = 1;
                        }
                    } completion:^(BOOL finished) {
                        
                    }];
                }
                
                [UIView animateWithDuration:0.25 animations:^{
                    __strong __typeof(self)strongSelf = weakSelf;
                    CGFloat x = strongSelf.viewCenterPoint.x - CGRectGetWidth(strongSelf.frame) / 2.0 - CGRectGetWidth(strongSelf.pushView.frame) / 2.0;
                    CGFloat y = strongSelf.viewCenterPoint.y;
                    strongSelf.pushView.center = CGPointMake(x, y);
                } completion:^(BOOL finished) {
                    __strong __typeof(self)strongSelf = weakSelf;
                    [strongSelf.pushView removeFromSuperview];
                    [strongSelf addCachePoolWithView:strongSelf.pushView];
                }];
            }
        }
    }
}

@end
