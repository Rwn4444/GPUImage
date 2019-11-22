//
//  RWNGCDTime.h
//  GCDTime
//
//  Created by shenhua on 2018/9/3.
//  Copyright © 2018年 RWN. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void(^taskBlock)(dispatch_source_t timer);

@interface RWNGCDTime : NSObject


/**
 创建一个定时器

 @param task 任务
 @param start 几秒后执行
 @param interval 时间间隔
 @param async 同步异步
 @param repate 是否重复
 @return 定时器标识
 */
+(NSString *)RWNTimeDoTask:(taskBlock)task
           startTime:(NSTimeInterval)start
           interval:(NSTimeInterval)interval
           async:(BOOL)async
           repate:(BOOL)repate
           rightNowStart:(BOOL)rightNowStart;


/**
  创建一个定时器

 @param task 任务
 @param interval 时间间隔
 @return 定时器标识
 */
+(NSString *)RWNTimeDoTask:(taskBlock)task
                  interval:(NSTimeInterval)interval;


/**
 创建一个定时器暂时不启动
 
 @param task 任务
 @param interval 时间间隔
 @return 定时器标识
 */
+(NSString *)RWNTimeNWaitDoTask:(taskBlock)task
                       interval:(NSTimeInterval)interval;

/**
 打开定时器通过标识
 
 @param identifier 定时器标识
 */
+(void)startTaskWithIdentifier:(NSString *)identifier;

/**
  取消定时器通过标识

 @param identifier 定时器标识
 */
+(void)cancaleTaskWithIdentifier:(NSString *)identifier;


/**
 暂停定时器通过标识
 
 @param identifier 定时器标识
 */
+(void)suspendTaskWithIdentifier:(NSString *)identifier;

@end
