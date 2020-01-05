//
//  PCMFileManager.m
//  LFLiveKitDemo
//
//  Created by HJQ on 2020/1/5.
//  Copyright © 2020 admin. All rights reserved.
//

#import "PCMFileManager.h"
#include "noise_suppression.h"
#import "LFLiveAudioConfiguration.h"
#import <AVFoundation/AVFoundation.h>

@implementation PCMFileManager

+ (NSData *)denoiseData:(NSData *)data config: (LFLiveAudioConfiguration *) config{
    /*
     buffer 要降噪的音频buf
     sampleRate 音频采样率
     samplesCount 音频位数
     int level 降噪等级 0-3 最高为3
     */
    int16_t *buffer = (int16_t *)[data bytes];
    uint32_t sampleRate = (uint32_t)config.audioSampleRate;
    int samplesCount = (int)data.length / 2;
    int level = 1;
    if (buffer == 0) return nil;
    if (samplesCount == 0) return nil;
    // 16000 ~ 480000
    size_t samples = MIN(160, sampleRate / 100);
    if (samples == 0) return nil;
    uint32_t num_bands = 1;
    int16_t *input = buffer;
    size_t nTotal = (samplesCount / samples);
    NsHandle *nsHandle = WebRtcNs_Create();
    int status = WebRtcNs_Init(nsHandle, sampleRate);
    if (status != 0) {
    //        printf("WebRtcNs_Init fail\n");
        return nil;
    }
    // WebRtcNsx_set_policy nMode是策略的选项，但是数值越高，效果越好，估计对性能有影响，不建议在CPU性能不佳的环境使用。只能取4个值：0，1，2，3
    status = WebRtcNs_set_policy(nsHandle, level);
    if (status != 0) {
    //        printf("WebRtcNs_set_policy fail\n");
        return nil;
    }
    for (int i = 0; i < nTotal; i++) {
        int16_t *nsIn[1] = {input};   //ns input[band][data]
        int16_t *nsOut[1] = {input};  //ns output[band][data]
        WebRtcNs_Analyze(nsHandle, nsIn[0]);
        WebRtcNs_Process(nsHandle, (const int16_t *const *) nsIn, num_bands, nsOut);
        input += samples;
    }
    WebRtcNs_Free(nsHandle);

    return [NSData dataWithBytes:buffer length:[data length]];
}

@end
