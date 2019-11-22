//
//  RWNImageMovieWriter.h
//  VideoTool
//
//  Created by RWN on 2019/11/18.
//  Copyright © 2019年 RWN. All rights reserved.
//

#import <GPUImage/GPUImage.h>

NS_ASSUME_NONNULL_BEGIN

@interface RWNImageMovieWriter : GPUImageMovieWriter

-(void)pause;

-(void)continueWrite;

-(void)configure;//每次暂停或者播放之前都要调用


@end

NS_ASSUME_NONNULL_END
