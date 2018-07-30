//
//  CarViewController.m
//  QYJToolPackage-Objective-C
//
//  Created by Avalanching on 2018/7/30.
//  Copyright © 2018年 Avalanching. All rights reserved.
//

#import "CarViewController.h"
#import "QYJCardAnimationView.h"

@interface CarViewController ()<QYJCardAnimationViewDelegate, QYJCardAnimationViewDataSource>
@property (nonatomic, strong) QYJCardAnimationView *cardview;

@property (nonatomic, assign) NSInteger count;


@end

@implementation CarViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.count = 10;
    /**
     QYJCardAnimationViewStyleTransverse     = 0, // 横向排列
     QYJCardAnimationViewStylePortraitDown   = 1, // 纵向排列从下方添加
     QYJCardAnimationViewStylePortraitUp     = 2, // 纵向排列从上方添加
     */
    _cardview = [[QYJCardAnimationView alloc] initWithStyle:QYJCardAnimationViewStylePortraitUp];
    _cardview.dataSource = self;
    _cardview.delegate = self;
    _cardview.frame = self.view.bounds;
    [self.view addSubview:_cardview];
}

- (IBAction)addCardButtonActioln:(id)sender {
    self.count += 5;
    [self.cardview reloadAllDataSource];
}
- (IBAction)reset:(id)sender {
    self.count = 5;
    [self.cardview resetDataSource];
}

- (IBAction)deleteCard:(id)sender {
    self.count -= 4;
    if (_count<= 0) {
        _count = 0;
    }
    [self.cardview reloadAllDataSource];
}

#pragma mark - QYJCardAnimationViewDelegate

- (void)cardAnimationView:(QYJCardAnimationView *)cardAnimationView didSelectRowAtIndex:(NSInteger)index {
    NSLog(@"you touch the card of NO.%ld", index);
}

#pragma mark - QYJCardAnimationViewDataSource
/**
 * 有多少张卡片
 */
- (NSInteger)rowNumberOfcardAnimationView {
    return self.count;
}

/**
 * 每张卡片具体内容
 */
- (QYJCardAnimationNillView *)cardAnimationView:(QYJCardAnimationView *)cardAnimationView viewForRowAtIndexPath:(NSInteger)index {
    static NSString *const identifier = @"QYJCardAnimationNillViewIdentifier";
    QYJCardCell *cell = (QYJCardCell *)[cardAnimationView dequeueReusableViewWithIdentifier:identifier];
    if (!cell) {
        cell = [[QYJCardCell alloc] init];
        cell.backgroundColor = [UIColor greenColor];
    }
    NSLog(@"index:%ld", index);
    cell.contentLabel.text = [NSString stringWithFormat:@"index:%ld", index];
    return cell;
}

/**
 * 顶部卡片的大小
 */
- (CGSize)sizeOfRowInCardAnimationView {
    return CGSizeMake(300, 400);
}


@end
