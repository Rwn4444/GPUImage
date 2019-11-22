//
//  VideoTool.m
//  VideoTool
//
//  Created by RWN on 2019/11/19.
//  Copyright © 2019年 RWN. All rights reserved.
//

#import "VideoTool.h"
#import <AVFoundation/AVFoundation.h>
@implementation VideoTool

/* 合成视频|转换视频格式
 @param videosPathArray:合成视频的路径数组
 @param outpath:输出路径
 @param outputFileType:视频格式
 @param presetName:分辨率
 @param  completeBlock  mergeFileURL:合成后新的视频URL
 */
+ (void)mergeAndExportVideos:(NSArray *)videosPathArray withOutPath:(NSString *)outPath outputFileType:(NSString *)outputFileType  presetName:(NSString *)presetName   didComplete:(void(^)(NSError *error,NSURL *mergeFileURL) )completeBlock{
    
    if (videosPathArray.count ==0) {
//        NSLog(@"请添加视频");
        NSError *error =[NSError errorWithDomain:NSCocoaErrorDomain code:0 userInfo:@{NSLocalizedDescriptionKey:@"视频数目不能为0"}];
        if (completeBlock) {
            completeBlock(error,nil);
        }
        return;
    }
    
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *audioTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    CMTime totalDuration = kCMTimeZero;
    for (int i = 0; i < videosPathArray.count; i++) {
        
        NSDictionary* options = @{AVURLAssetPreferPreciseDurationAndTimingKey:@YES
                                  
                                  };
        AVURLAsset *asset =[AVURLAsset URLAssetWithURL:[NSURL fileURLWithPath:videosPathArray[i]] options:options];
        NSError *erroraudio = nil;
        //获取AVAsset中的音频 或者视频
        AVAssetTrack *assetAudioTrack = [[asset tracksWithMediaType:AVMediaTypeAudio] firstObject];
        //向通道内加入音频或者视频
        BOOL ba = [audioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                      ofTrack:assetAudioTrack
                                       atTime:totalDuration
                                        error:&erroraudio];
        NSLog(@"erroraudio:%@%d",erroraudio,ba);
        NSError *errorVideo = nil;
        AVAssetTrack *assetVideoTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] firstObject];
        BOOL bl = [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                                      ofTrack:assetVideoTrack
                                       atTime:totalDuration
                                        error:&errorVideo];
        NSLog(@"errorVideo:%@%d",errorVideo,bl);
        totalDuration = CMTimeAdd(totalDuration, asset.duration);
    }
    unlink([outPath UTF8String]);
    NSURL *mergeFileURL = [NSURL fileURLWithPath:outPath];
    if ([[NSFileManager defaultManager] fileExistsAtPath:outPath]) {
        [[NSFileManager defaultManager] removeItemAtPath:outPath error:nil];
        
    }
    //输出
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:presetName];
    exporter.outputURL = mergeFileURL;
    exporter.outputFileType = outputFileType;
    exporter.shouldOptimizeForNetworkUse = YES;
    //因为exporter.progress不可以被监听 所以在这里可以开启定时器取 exporter的值查看进度
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (exporter.status) {
                case AVAssetExportSessionStatusFailed:{
                    if (completeBlock) {
                        completeBlock(exporter.error,mergeFileURL);
                    }
                    break;
                }
                case AVAssetExportSessionStatusCancelled:{
                    NSLog(@"Export Status: Cancell");
                    break;
                }
                case AVAssetExportSessionStatusCompleted: {
                    if (completeBlock) {
                        completeBlock(nil,mergeFileURL);
                    }
                    break;
                }
                case AVAssetExportSessionStatusUnknown: {
                    NSLog(@"Export Status: Unknown");
                    break;
                }
                case AVAssetExportSessionStatusExporting : {
                    
                    NSLog(@"Export Status: Exporting");
                    break;
                }
                case AVAssetExportSessionStatusWaiting: {
                    
                    NSLog(@"Export Status: Wating");
                    break;
                }
                    
            };
            
            
        });
        
    }];
    
}


+(void)cleanTempVideoWithUrl:(NSString *)pathUrl{
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathUrl]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathUrl error:nil];
    }
    
}




@end
