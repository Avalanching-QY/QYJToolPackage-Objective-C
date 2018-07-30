//
//  QYJCardAnimationNillView.m
//  QYJToolPackage-Objective-C
//
//  Created by Avalanching on 2018/7/26.
//  Copyright © 2018年 Avalanching. All rights reserved.
//

#import "QYJCardAnimationNillView.h"

@interface QYJCardAnimationNillView ()

@property (nonatomic, copy) NSString *identifier;

@end

@implementation QYJCardAnimationNillView

- (void)addIdentifier:(NSString *)identifier {
    _identifier = identifier;
}

- (NSString *)getIdentifier {
    if (_identifier) {
        return _identifier;
    } else {
        return @"isnill";
    }
}

@end
