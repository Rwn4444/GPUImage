//
//  VideoTool.h
//  VideoTool
//
//  Created by RWN on 2019/11/19.
//  Copyright © 2019年 RWN. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface VideoTool : NSObject


/* 合成视频|转换视频格式
 @param videosPathArray:合成视频的路径数组
 @param outpath:输出路径
 @param outputFileType:视频格式
 @param presetName:分辨率
 @param  completeBlock  mergeFileURL:合成后新的视频URL
 */
+ (void)mergeAndExportVideos:(NSArray *)videosPathArray withOutPath:(NSString *)outPath outputFileType:(NSString *)outputFileType  presetName:(NSString *)presetName   didComplete:(void(^)(NSError *error,NSURL *mergeFileURL) )completeBlock;



+(void)cleanTempVideo;


@end

NS_ASSUME_NONNULL_END
