//
//  NewLocalCameraView.m
//  OFweekPhone
//
//  Created by 胡晓伟 on 2018/4/13.
//  Copyright © 2018年 wayne. All rights reserved.
//

#import "NewLocalCameraView.h"
#import "UIControl+YYAdd.h"
#import <Masonry.h>

#pragma mark -- 推流实时速度监控
inline static NSString *formatedSpeed(float bytes, float elapsed_milli) {
    if (elapsed_milli <= 0) {
        return @"N/A";
    }
    
    if (bytes <= 0) {
        return @"0 KB/s";
    }
    
    float bytes_per_sec = ((float)bytes) * 1000.f /  elapsed_milli;
    if (bytes_per_sec >= 1000 * 1000) {
        return [NSString stringWithFormat:@"%.2f MB/s", ((float)bytes_per_sec) / 1000 / 1000];
    } else if (bytes_per_sec >= 1000) {
        return [NSString stringWithFormat:@"%.1f KB/s", ((float)bytes_per_sec) / 1000];
    } else {
        return [NSString stringWithFormat:@"%ld B/s", (long)bytes_per_sec];
    }
}

#define SCREEN_WIDTH   [UIScreen mainScreen].bounds.size.width
#define SCREEN_HEIGHT [UIScreen mainScreen].bounds.size.height
#define StatusBar_HEIGHT [UIApplication sharedApplication].statusBarFrame.size.height

@interface NewLocalCameraView() <LFLiveSessionDelegate>

@property (nonatomic, weak) UIViewController *curViewController;

@property (nonatomic, strong) UIButton *switchCameraButton;
@property (nonatomic, strong) UIButton *torchButton;

@property (strong, nonatomic) UIImageView *shadowup;
@property (strong, nonatomic) UIView *redPoint;

@property (strong, nonatomic) LFLiveVideoConfiguration *videoConfiguration;


@end

@implementation NewLocalCameraView

#pragma mark -- 以竖屏初始化
- (instancetype)initWithProtrait {
    self = [super initWithFrame:CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT)];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _videoConfiguration = [LFLiveVideoConfiguration new];
        _videoConfiguration.videoSize = CGSizeMake(540, 960);
        _videoConfiguration.videoBitRate = 800*1024;
        _videoConfiguration.videoMaxBitRate = 1000*1024;
        _videoConfiguration.videoMinBitRate = 500*1024;
        _videoConfiguration.videoFrameRate = 24;
        _videoConfiguration.videoMaxKeyframeInterval = 48;
        _videoConfiguration.outputImageOrientation = UIInterfaceOrientationPortrait;
        _videoConfiguration.sessionPreset = LFCaptureSessionPreset540x960;
        
        [self requestAccessForVideo];
        [self requestAccessForAudio];
        
        [self initUI:YES];


    }
    return self;
}

#pragma mark -- 以横屏初始化
- (instancetype)initWithLandscape {
    self = [super initWithFrame:CGRectMake(0, 0, SCREEN_HEIGHT, SCREEN_WIDTH)];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        
        _videoConfiguration = [LFLiveVideoConfiguration new];
        _videoConfiguration.videoSize = CGSizeMake(1280, 720);
        _videoConfiguration.videoBitRate = 800*1024;
        _videoConfiguration.videoMaxBitRate = 1000*1024;
        _videoConfiguration.videoMinBitRate = 500*1024;
        _videoConfiguration.videoFrameRate = 15;
        _videoConfiguration.videoMaxKeyframeInterval = 30;
        _videoConfiguration.outputImageOrientation = UIInterfaceOrientationLandscapeRight;
        _videoConfiguration.sessionPreset = LFCaptureSessionPreset720x1280;
        
        [self requestAccessForVideo];
        [self requestAccessForAudio];
        
        [self initUI:NO];
        

    }
    return self;
}

- (void)initUI:(BOOL)isProtrait {
    _shadowup = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"shadowup"]];
    _shadowup.userInteractionEnabled = YES;
    _shadowup.translatesAutoresizingMaskIntoConstraints = NO;
    [self addSubview:_shadowup];
    CGFloat statuBarHeight = UIApplication.sharedApplication.statusBarFrame.size.height;
    CGFloat bgHeight = statuBarHeight + 44.0;
    if (!isProtrait) {
        bgHeight = 64.0;
        statuBarHeight = 20.0;
    }
    [_shadowup mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.top.right.equalTo(self);
//        make.height.mas_equalTo(60);
        //2019.1.15适配X
        make.height.mas_equalTo(bgHeight);
    }];
    
    SpreadButton *backBtn = [SpreadButton buttonWithType:UIButtonTypeCustom];
    backBtn.minimumHitTestWidth = 100;
    backBtn.minimumHitTestHight = 60;
    [backBtn setImage:[UIImage imageNamed:@"turnback"] forState:UIControlStateNormal];
    [backBtn addTarget: self action:@selector(backAction) forControlEvents:UIControlEventTouchUpInside];
    [_shadowup addSubview:backBtn];
    [backBtn mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.centerY.equalTo(_shadowup);
        //2019.1.15适配X
        make.top.equalTo(_shadowup).offset(statuBarHeight+12);
        make.left.equalTo(_shadowup).offset(16);
        make.width.mas_equalTo(12);
        make.height.mas_equalTo(20);
    }];
    
    //streamStartButton
    _streamStartButton = [SpreadButton buttonWithType:UIButtonTypeSystem];
    _streamStartButton.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.45];
    _streamStartButton.layer.cornerRadius = 6;
    _streamStartButton.clipsToBounds = YES;
    _streamStartButton.minimumHitTestWidth = 150;
    _streamStartButton.minimumHitTestHight = 80;
    _streamStartButton.translatesAutoresizingMaskIntoConstraints = NO;
    [_streamStartButton setTitle:@"开启直播" forState:UIControlStateNormal];
    [_streamStartButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];

    
    //红点
    _redPoint = [[UIView alloc] init];
    _redPoint.backgroundColor = [UIColor redColor];
    // [UIColor vi_colorWithHex:0xe65e50];
    _redPoint.layer.cornerRadius = 3;
    _redPoint.hidden = YES;
    [_streamStartButton addSubview:_redPoint];
    
    [_streamStartButton addTarget:self action:@selector(streamStartButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [_shadowup addSubview:_streamStartButton];
    
    [_streamStartButton mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.center.equalTo(_shadowup);
        //2019.1.15适配X
        make.top.equalTo(_shadowup).offset(statuBarHeight+4.5);
        make.centerX.equalTo(self.shadowup);
        make.width.mas_equalTo(109);
        make.height.mas_equalTo(35);
    }];
    
    [_redPoint mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerY.equalTo(_streamStartButton);
        make.left.equalTo(_streamStartButton).offset(7);
        make.width.height.mas_equalTo(6);
    }];
   
    //闪光灯
    _torchButton = [[UIButton alloc] init];
    _torchButton.translatesAutoresizingMaskIntoConstraints =  NO;
    [_torchButton setImage:[UIImage imageNamed:@"light"] forState:UIControlStateNormal];
    [_shadowup addSubview:_torchButton];
    [_torchButton addTarget:self action:@selector(torchButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    NSLayoutConstraint *constraint;
    
    //右边距
    constraint = [NSLayoutConstraint
                  constraintWithItem:_torchButton
                  attribute:NSLayoutAttributeRight
                  relatedBy:NSLayoutRelationEqual
                  toItem:_shadowup
                  attribute:NSLayoutAttributeRight
                  multiplier:1.0f
                  constant:-8];
    [_shadowup addConstraint:constraint];
    
    //顶部边距
    constraint = [NSLayoutConstraint
                  constraintWithItem:_torchButton
                  attribute:NSLayoutAttributeCenterY
                  relatedBy:NSLayoutRelationEqual
                  toItem:_streamStartButton
                  attribute:NSLayoutAttributeCenterY
                  multiplier:1.0f
                  constant:0];
    [_shadowup addConstraint:constraint];
    
    //翻转摄像头
    _switchCameraButton = [[UIButton alloc] init];
    _switchCameraButton.translatesAutoresizingMaskIntoConstraints =  NO;
    [_switchCameraButton setImage:[UIImage imageNamed:@"turn"] forState:UIControlStateNormal];
    [_shadowup addSubview:_switchCameraButton];
    [_switchCameraButton addTarget:self action:@selector(switchCameraButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    
    //右边距
    constraint = [NSLayoutConstraint
                  constraintWithItem:_switchCameraButton
                  attribute:NSLayoutAttributeRight
                  relatedBy:NSLayoutRelationEqual
                  toItem:_torchButton
                  attribute:NSLayoutAttributeLeft
                  multiplier:1.0f
                  constant:-15];
    [self addConstraint:constraint];
    
    //顶部边距
    constraint = [NSLayoutConstraint
                  constraintWithItem:_switchCameraButton
                  attribute:NSLayoutAttributeCenterY
                  relatedBy:NSLayoutRelationEqual
                  toItem:_streamStartButton
                  attribute:NSLayoutAttributeCenterY
                  multiplier:1.0f
                  constant:0];
    [self addConstraint:constraint];
}

- (void)backAction {
    if (_delegate && [_delegate respondsToSelector:@selector(exitLive)]) {
        [_delegate exitLive];
    }
}

- (UIViewController*)getViewController:(UIView *)sender {
    for (UIView* next = [sender superview]; next; next = next.superview) {
        UIResponder* nextResponder = [next nextResponder];
        if ([nextResponder isKindOfClass:[UIViewController class]]) {
            return (UIViewController*)nextResponder;
        }
    }
    return nil;
}

#pragma mark -- 闪光灯按钮点击
- (void)torchButtonClicked {
    if(_session.captureDevicePosition == AVCaptureDevicePositionFront) {
        if(!self.curViewController) {
            self.curViewController = [self getViewController:self];
        }
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"提示" message:@"当前为前置摄像头，无法开启闪光灯" preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }]];
        [self.curViewController presentViewController:alert animated:YES completion:nil];
    }
    else {
        [self turnTorch];
    }
}

#pragma mark -- 切换摄像头前后按钮点击
- (void)switchCameraButtonClicked {
    AVCaptureDevicePosition devicePositon = self.session.captureDevicePosition;
    self.session.captureDevicePosition = (devicePositon == AVCaptureDevicePositionBack) ? AVCaptureDevicePositionFront : AVCaptureDevicePositionBack;
}

#pragma mark -- 开始直播/停止直播 按钮点击
- (void)streamStartButtonClicked:(id)sender {
    NSLog(@"streamStartButtonClicked");
    
    if(!self.curViewController) {
        self.curViewController = [self getViewController:self];
    }
    
    UIAlertController *alert = nil;
    
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        alert = [UIAlertController alertControllerWithTitle:@"需要\"相机\"使用权限" message:@"请在系统\"设置\"--\"OFweek\"--\"相机\"启用权限" preferredStyle:UIAlertControllerStyleAlert];
        
        
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }]];
        
        [self.curViewController presentViewController:alert animated:NO completion:nil];
        return;
    }
    
    status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if(status == AVAuthorizationStatusDenied || status == AVAuthorizationStatusRestricted) {
        alert = [UIAlertController alertControllerWithTitle:@"需要\"麦克风\"使用权限" message:@"请在系统\"设置\"--\"OFweek\"--\"麦克风\"启用权限" preferredStyle:UIAlertControllerStyleAlert];
        
        [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        }]];
        
        [self.curViewController presentViewController:alert animated:NO completion:nil];
        return;
    }
    
    [self.delegate NewLocalCameraViewStartButtonClicked];
    

}

#pragma mark -- 开始直播
- (void)startStream:(NSString *)streamUrl {
    LFLiveStreamInfo *stream = [LFLiveStreamInfo new];
    stream.url = streamUrl;
    [_session startLive:stream];
}

#pragma mark -- 停止直播
- (void)endStream {
    [_session stopLive];
    _session = nil;
}

#pragma mark -- liveSession liveStateDidChange
- (void)liveSession:(LFLiveSession *)session liveStateDidChange:(LFLiveState)state {
//    NSLog(@"liveStateDidChange: %lu %ld %ld %ld %ld %ld %ld", (unsigned long)state, LFLiveReady, LFLivePending, LFLiveStart, LFLiveStop, LFLiveError, LFLiveRefresh);
    switch (state) {
        case LFLiveReady:
            NSLog(@"未连接");
            _streamStartButton.userInteractionEnabled = YES;
            [_streamStartButton setTitle:@"开启直播" forState:UIControlStateNormal];
            _redPoint.hidden = YES;
            break;
        case LFLivePending:
            NSLog(@"连接中");
            _streamStartButton.userInteractionEnabled = NO;
            [_streamStartButton setTitle:@"连接中..." forState:UIControlStateNormal];
            _redPoint.hidden = YES;
            break;
        case LFLiveStart:
            NSLog(@"已连接");
            _streamStartButton.userInteractionEnabled = YES;
            [_streamStartButton setTitle:@"停止直播" forState:UIControlStateNormal];
            _redPoint.hidden = NO;
            break;
        case LFLiveError:
            NSLog(@"连接错误");
            _streamStartButton.userInteractionEnabled = YES;
            [_streamStartButton setTitle:@"开启直播" forState:UIControlStateNormal];
            _redPoint.hidden = YES;
            break;
        case LFLiveStop:
            NSLog(@"未连接");
            _streamStartButton.userInteractionEnabled = YES;
            [_streamStartButton setTitle:@"开启直播" forState:UIControlStateNormal];
            _redPoint.hidden = YES;
            break;
        default:
            break;
    }
}

#pragma mark -- liveSession debugInfo
- (void)liveSession:(nullable LFLiveSession *)session debugInfo:(nullable LFLiveDebug *)debugInfo {
    NSLog(@"debugInfo uploadSpeed: %@", formatedSpeed(debugInfo.currentBandwidth, debugInfo.elapsedMilli));
}

#pragma mark -- liveSession errorCode
- (void)liveSession:(nullable LFLiveSession *)session errorCode:(LFLiveSocketErrorCode)errorCode {
    NSLog(@"errorCode: %lu", (unsigned long)errorCode);
}

#pragma mark -- Session Getter Setter
- (LFLiveSession *)session {
    if (!_session) {
        LFLiveAudioConfiguration *audioConfig = [LFLiveAudioConfiguration defaultConfigurationForQuality:LFLiveAudioQuality_Default];
        _session = [[LFLiveSession alloc] initWithAudioConfiguration:audioConfig videoConfiguration:_videoConfiguration captureType:LFLiveCaptureDefaultMask];
        _session.delegate = self;
        _session.showDebugInfo = NO;
        _session.preView = self;
    }
    return _session;
}

#pragma mark - 请求摄像头权限
- (void)requestAccessForVideo {
    __weak typeof(self) _self = self;
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            // 许可对话没有出现，发起授权许可
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
                if (granted) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        [_self.session setRunning:YES];
                    });
                }
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            // 已经开启授权，可继续
            dispatch_async(dispatch_get_main_queue(), ^{
                [_self.session setRunning:YES];
            });
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted: {
            break;
        }
        default:
            break;
    }
}

#pragma mark - 请求麦克风权限
- (void)requestAccessForAudio {
    AVAuthorizationStatus status = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    switch (status) {
        case AVAuthorizationStatusNotDetermined: {
            [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            }];
            break;
        }
        case AVAuthorizationStatusAuthorized: {
            break;
        }
        case AVAuthorizationStatusDenied:
        case AVAuthorizationStatusRestricted: {
            NSString *str = @"请在系统\"设置\"--\"OFweek\"--\"麦克风\"启用权限";
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"需要\"麦克风\"使用权限" message:str preferredStyle:UIAlertControllerStyleAlert];
            
            
            [alert addAction:[UIAlertAction actionWithTitle:@"知道了" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            }]];
            break;
        }
            break;
        default:
            break;
    }
}

#pragma mark - 闪光灯打开/关闭
- (void)turnTorch {
    Class captureDeviceClass = NSClassFromString(@"AVCaptureDevice");
    if (captureDeviceClass != nil) {
        AVCaptureDevice *device = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
        if ([device hasTorch] && [device hasFlash]){
            NSError *error;
            if ([device lockForConfiguration:&error]) {
                if(device.flashMode == AVCaptureFlashModeOff) {
                    [device setTorchMode:AVCaptureTorchModeOn];
                    [device setFlashMode:AVCaptureFlashModeOn];
                }
                else if (device.flashMode == AVCaptureFlashModeOn) {
                    [device setTorchMode:AVCaptureTorchModeOff];
                    [device setFlashMode:AVCaptureFlashModeOff];
                }
                
                [device unlockForConfiguration];
            }
        }
    }
}

@end
