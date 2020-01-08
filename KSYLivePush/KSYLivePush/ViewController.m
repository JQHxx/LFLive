//
//  ViewController.m
//  KSYLivePush
//
//  Created by OFweek01 on 2020/1/7.
//  Copyright © 2020 OFweek01. All rights reserved.
//

#import "ViewController.h"
#import "NewKSYLivePushView.h"

@interface ViewController ()

@property (nonatomic, strong) NewKSYLivePushView *bgView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.bgView = [[NewKSYLivePushView alloc] initWithProtrait];
    [self.bgView startStream:@"rtmp://3891.livepush.myqcloud.com/live/3891_user_49fd0d98_e947?bizid=3891&txSecret=268eaa2cd0d1d56257c1169912289392&txTime=5E155486"];
    [self.view addSubview:self.bgView];
}


@end
