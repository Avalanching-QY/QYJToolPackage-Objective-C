//
//  QYJCardCell.m
//  QYJToolPackage-Objective-C
//
//  Created by Avalanching on 2018/7/27.
//  Copyright © 2018年 Avalanching. All rights reserved.
//

#import "QYJCardCell.h"

@implementation QYJCardCell

- (void)layoutSubviews {
    [super layoutSubviews];
    self.contentLabel.frame = self.bounds;
    [self addSubview:self.contentLabel];
}

- (UILabel *)contentLabel {
    if (!_contentLabel) {
        _contentLabel = [[UILabel alloc] init];
        _contentLabel.font = [UIFont systemFontOfSize:17];
        _contentLabel.textColor = [UIColor orangeColor];
    }
    return _contentLabel;
}

@end
