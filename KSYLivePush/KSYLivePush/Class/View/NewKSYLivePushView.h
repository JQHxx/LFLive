//
//  NewKSYLivePushView.h
//  KSYLivePush
//
//  Created by OFweek01 on 2020/1/7.
//  Copyright © 2020 OFweek01. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <libksygpulive/KSYGPUStreamerKit.h>

NS_ASSUME_NONNULL_BEGIN

@protocol NewKSYLivePushViewDelegate <NSObject>

- (void)newKSYLivePushViewStartButtonClicked;

- (void)newKSYLivePushViewExitLive;

@end

@class SpreadButton;
@interface NewKSYLivePushView : UIView

#pragma mark - kit instance

@property (weak, nonatomic) id<NewKSYLivePushViewDelegate> delegate;

- (instancetype)initWithProtrait;

- (instancetype)initWithLandscape;

- (void)startStream:(NSString *)streamUrl;

- (void)endStream;

/**
 直播开始按钮
 */
@property (strong, nonatomic) SpreadButton *streamStartButton;

@end

NS_ASSUME_NONNULL_END
