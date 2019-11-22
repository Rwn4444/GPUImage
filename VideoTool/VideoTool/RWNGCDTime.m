//
//  RWNGCDTime.m
//  GCDTime
//
//  Created by shenhua on 2018/9/3.
//  Copyright © 2018年 RWN. All rights reserved.
//

#import "RWNGCDTime.h"



@implementation RWNGCDTime

NSMutableDictionary * diction_;
dispatch_semaphore_t  semap_;

+(void)initialize{
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        diction_ = [NSMutableDictionary dictionary];
        semap_ =dispatch_semaphore_create(1);
    });
    
}

+(NSString *)RWNTimeDoTask:(taskBlock)task
                 startTime:(NSTimeInterval)start
                  interval:(NSTimeInterval)interval
                     async:(BOOL)async
                    repate:(BOOL)repate
             rightNowStart:(BOOL)rightNowStart;{
    
    if (!task || ((interval<=0) & repate)) return nil;
    
    dispatch_queue_t queue = async ? dispatch_get_global_queue(0, 0) :dispatch_get_main_queue();
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);
    dispatch_time_t startTime =dispatch_time(DISPATCH_TIME_NOW, start * NSEC_PER_SEC);
    dispatch_source_set_timer(timer,startTime, interval * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
    
    ///加锁
    dispatch_semaphore_wait(semap_, DISPATCH_TIME_FOREVER);
    NSString *identifer = [NSString stringWithFormat:@"%lu",(unsigned long)diction_.count];
    diction_[identifer]=timer;
    dispatch_semaphore_signal(semap_);
    
    dispatch_source_set_event_handler(timer, ^{
        task(timer);
        if (!repate) {
        }
    });
    if (rightNowStart) {
        dispatch_resume(timer);
    }
    return identifer;
    
}

+(NSString *)RWNTimeDoTask:(taskBlock)task
                  interval:(NSTimeInterval)interval{
    
   return [RWNGCDTime RWNTimeDoTask:task startTime:0 interval:interval async:YES repate:YES rightNowStart:YES];
    
}


+(NSString *)RWNTimeNWaitDoTask:(taskBlock)task
                       interval:(NSTimeInterval)interval{
    
    return [RWNGCDTime RWNTimeDoTask:task startTime:0 interval:interval async:YES repate:YES rightNowStart:NO];
    
}


+(void)startTaskWithIdentifier:(NSString *)identifier{
    
    if (identifier.length==0)  return;
    ///加锁
    dispatch_semaphore_wait(semap_, DISPATCH_TIME_FOREVER);
    dispatch_source_t timer = diction_[identifier];
    dispatch_semaphore_signal(semap_);
    if (timer) {
        dispatch_resume(timer);
    }
    
}

+(void)cancaleTaskWithIdentifier:(NSString *)identifier{
    
    if (identifier.length==0)  return;
    
    ///加锁
    dispatch_semaphore_wait(semap_, DISPATCH_TIME_FOREVER);
    dispatch_source_t timer = diction_[identifier];
    [diction_ removeObjectForKey:identifier];
    dispatch_semaphore_signal(semap_);
    if (timer) {
        dispatch_source_cancel(timer);
    }
    
}

+(void)suspendTaskWithIdentifier:(NSString *)identifier{
    
    if (identifier.length==0)  return;
    ///加锁
    dispatch_semaphore_wait(semap_, DISPATCH_TIME_FOREVER);
    dispatch_source_t timer = diction_[identifier];
    dispatch_semaphore_signal(semap_);
    if (timer) {
        dispatch_suspend(timer);
    }
    
}



@end

