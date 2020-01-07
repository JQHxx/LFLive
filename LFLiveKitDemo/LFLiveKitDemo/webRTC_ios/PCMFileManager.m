#import "PCMFileManager.h"
// 浮点算法
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
    /**
    * 总音频采样数 = 音频总时长(毫秒) / 10 * 采样率
     */
    int samplesCount = (int)data.length / 2;
    int level = 2;
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

/// webRTC降噪
/// @param data 要降噪的音频data
/// @param sampleRate 音频采样率
/// @param samplesCount 总音频采样数
/// @param level 0 - 3
+(NSData *) nsProcess:(NSData *)data  sampleRate: (uint32_t) sampleRate samplesCount: (int) samplesCount level: (int) level
{
    int16_t *buffer = (int16_t *)[data bytes];
    if (buffer == 0) return nil;
    if (samplesCount == 0) return nil;
    size_t samples = MIN(160, sampleRate / 100);
    if (samples == 0) return nil;
    uint32_t num_bands = 1;
    int16_t *input = buffer;
    size_t nTotal = (samplesCount / samples);
    NsHandle *nsHandle = WebRtcNs_Create();
    int status = WebRtcNs_Init(nsHandle, sampleRate);
    if (status != 0) {
        //printf("WebRtcNs_Init fail\n");
        return nil;
    }
    status = WebRtcNs_set_policy(nsHandle, level);
    if (status != 0) {
        // printf("WebRtcNs_set_policy fail\n");
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

/**
* 总音频采样数 = 音频总时长(毫秒) / 10 * 采样率
 */
+(NSData *) nsProcess:(NSData *)data  sampleRate: (uint32_t) sampleRate channels: (uint32_t) channels samplesCount: (int) samplesCount level: (int) level {
    int16_t *buffer = (int16_t *)[data bytes];
    if (buffer == 0) return nil;
    if (samplesCount == 0) return nil;
    size_t samples = MIN(160, sampleRate / 100);
    if (samples == 0) return nil;
    uint32_t num_bands = 1;
    int16_t *input = buffer;
    size_t frames = (samplesCount / (samples * channels));
    int16_t *frameBuffer = (int16_t *) malloc(sizeof(*frameBuffer) * channels * samples);
    NsHandle **NsHandles = (NsHandle **) malloc(channels * sizeof(NsHandle *));
    if (NsHandles == NULL || frameBuffer == NULL) {
        if (NsHandles)
            free(NsHandles);
        if (frameBuffer)
            free(frameBuffer);
        fprintf(stderr, "malloc error.\n");
        return nil;
    }
    for (int i = 0; i < channels; i++) {
        NsHandles[i] = WebRtcNs_Create();
        if (NsHandles[i] != NULL) {
            int status = WebRtcNs_Init(NsHandles[i], sampleRate);
            if (status != 0) {
                fprintf(stderr, "WebRtcNs_Init fail\n");
                WebRtcNs_Free(NsHandles[i]);
                NsHandles[i] = NULL;
            } else {
                status = WebRtcNs_set_policy(NsHandles[i], level);
                if (status != 0) {
                    fprintf(stderr, "WebRtcNs_set_policy fail\n");
                    WebRtcNs_Free(NsHandles[i]);
                    NsHandles[i] = NULL;
                }
            }
        }
        if (NsHandles[i] == NULL) {
            for (int x = 0; x < i; x++) {
                if (NsHandles[x]) {
                    WebRtcNs_Free(NsHandles[x]);
                }
            }
            free(NsHandles);
            free(frameBuffer);
            return nil;
        }
    }
    for (int i = 0; i < frames; i++) {
        for (int c = 0; c < channels; c++) {
            for (int k = 0; k < samples; k++)
                frameBuffer[k] = input[k * channels + c];

            int16_t *nsIn[1] = {frameBuffer};   //ns input[band][data]
            int16_t *nsOut[1] = {frameBuffer};  //ns output[band][data]
            WebRtcNs_Analyze(NsHandles[c], nsIn[0]);
            WebRtcNs_Process(NsHandles[c], (const int16_t *const *) nsIn, num_bands, nsOut);
            for (int k = 0; k < samples; k++)
                input[k * channels + c] = frameBuffer[k];
        }
        input += samples * channels;
    }

    for (int i = 0; i < channels; i++) {
        if (NsHandles[i]) {
            WebRtcNs_Free(NsHandles[i]);
        }
    }
    free(NsHandles);
    free(frameBuffer);
    return [NSData dataWithBytes:buffer length:[data length]];
}


@end
