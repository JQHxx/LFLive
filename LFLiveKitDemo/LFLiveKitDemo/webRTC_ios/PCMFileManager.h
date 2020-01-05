//
//  PCMFileManager.h
//  LFLiveKitDemo
//
//  Created by HJQ on 2020/1/5.
//  Copyright © 2020 admin. All rights reserved.
//

#import <Foundation/Foundation.h>

// https://lvb.qcloud.com/weapp/utils/get_test_pushurl

NS_ASSUME_NONNULL_BEGIN
@class LFLiveAudioConfiguration;
@interface PCMFileManager : NSObject

+ (NSData *)denoiseData:(NSData *)data config: (LFLiveAudioConfiguration *) config;

@end

NS_ASSUME_NONNULL_END
