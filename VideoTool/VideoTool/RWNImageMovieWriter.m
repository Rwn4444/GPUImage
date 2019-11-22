//
//  RWNImageMovieWriter.m
//  VideoTool
//
//  Created by RWN on 2019/11/18.
//  Copyright © 2019年 RWN. All rights reserved.
//

#import "RWNImageMovieWriter.h"

@interface RWNImageMovieWriter (){
    
    BOOL _isPause;
    //    BOOL _isAudioOn;
    CMTime _offset;
    CMTime _timeOffset;
    CMTime _last;
    BOOL _isDisCount;
    
}

@end


@implementation RWNImageMovieWriter


-(void)newFrameReadyAtTime:(CMTime)frameTime atIndex:(NSInteger)textureIndex{
    
    if (_isPause) {
        return;
    }
    if (_isDisCount) {
        _isDisCount = NO;
        _offset = CMTimeSubtract(frameTime, _last);
        if (_offset.value > 0) {
            _timeOffset = CMTimeAdd(_timeOffset, _offset);
        }
    }
    _last = frameTime;
    frameTime = CMTimeSubtract(frameTime, _timeOffset);
    //    NSLog(@"_timeOffset->%lf, ->%lf", _timeOffset.value, _timeOffset.timescale);
    [super newFrameReadyAtTime:frameTime atIndex:textureIndex];
    
}

-(void)pause{
    _isPause = YES;
}

-(void)continueWrite{
    _isPause = NO;
}

-(void)configure{
    _timeOffset = CMTimeMake(0, 1);
    _isDisCount = YES;
    //_isAudioOn = YES;
    _offset = kCMTimeZero;
}

-(void)processAudioBuffer:(CMSampleBufferRef)audioBuffer{
    if (_isPause) {
        return;
    }
    [super processAudioBuffer:audioBuffer];
    
}



@end
