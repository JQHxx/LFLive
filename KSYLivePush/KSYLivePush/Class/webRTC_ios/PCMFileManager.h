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

+ (NSData *)denoiseData:(NSData *)data
                 config: (LFLiveAudioConfiguration *) config;

/// webRTC降噪
/// @param data 要降噪的音频data
/// @param sampleRate 音频采样率
/// @param samplesCount 总音频采样数
/// @param level 0 - 3 降噪等级
+(NSData *) nsProcess:(NSData *) data
           sampleRate:(uint32_t) sampleRate
         samplesCount:(int) samplesCount
                level:(int) level;

+(NSData *) nsProcess:(NSData *)data  sampleRate: (uint32_t) sampleRate channels: (uint32_t) channels samplesCount: (int) samplesCount level: (int) level;

@end

NS_ASSUME_NONNULL_END
