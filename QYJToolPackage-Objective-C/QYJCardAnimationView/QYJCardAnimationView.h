//
//  QYJCardAnimationView.h
//  QYJToolPackage-Objective-C
//
//  Created by Avalanching on 2018/7/26.
//  Copyright © 2018年 Avalanching. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "QYJCardAnimationNillView.h"
#import "QYJCardCell.h"

typedef NS_ENUM(NSInteger, QYJCardAnimationViewStyle) {
    QYJCardAnimationViewStyleTransverse     = 0, // 横向排列
    QYJCardAnimationViewStylePortraitDown   = 1, // 纵向排列从下方添加
    QYJCardAnimationViewStylePortraitUp     = 2, // 纵向排列从上方添加
};

@class QYJCardAnimationView;

@protocol QYJCardAnimationViewDelegate <NSObject>

@optional

- (void)cardAnimationView:(QYJCardAnimationView *)cardAnimationView didSelectRowAtIndex:(NSInteger)index;

@end

@protocol QYJCardAnimationViewDataSource <NSObject>

@required
/**
 * 有多少张卡片
 */
- (NSInteger)rowNumberOfcardAnimationView;

/**
 * 每张卡片具体内容
 */
- (QYJCardAnimationNillView *)cardAnimationView:(QYJCardAnimationView *)cardAnimationView viewForRowAtIndexPath:(NSInteger)index;

/**
 * 顶部卡片的大小
 */
- (CGSize)sizeOfRowInCardAnimationView;

@end

@interface QYJCardAnimationView : UIView 

@property (nonatomic, weak) id<QYJCardAnimationViewDataSource>dataSource;

@property (nonatomic, weak) id<QYJCardAnimationViewDelegate>delegate;

- (instancetype)initWithStyle:(QYJCardAnimationViewStyle)style;

- (QYJCardAnimationNillView *)dequeueReusableViewWithIdentifier:(NSString *)identifier;

- (void)resetDataSource;

- (void)reloadAllDataSource;

- (void)updateStyle:(QYJCardAnimationViewStyle)style;

@end
