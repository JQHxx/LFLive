//
//  NewLocalCameraView.h
//  OFweekPhone
//
//  Created by 胡晓伟 on 2018/4/13.
//  Copyright © 2018年 wayne. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LFLiveKit.h"
#import "SpreadButton.h"

@protocol NewLocalCameraViewDelegate <NSObject>

- (void)NewLocalCameraViewStartButtonClicked;

- (void)exitLive;

@end

@interface NewLocalCameraView : UIView

- (instancetype)initWithProtrait;

- (instancetype)initWithLandscape;

- (void)startStream:(NSString *)streamUrl;

- (void)endStream;

@property (nonatomic, strong) LFLiveSession *session;

@property (weak, nonatomic) id<NewLocalCameraViewDelegate> delegate;

@property (strong, nonatomic) SpreadButton *streamStartButton;

@end
