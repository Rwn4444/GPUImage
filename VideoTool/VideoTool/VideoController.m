//
//  VideoController.m
//  VideoTool
//
//  Created by RWN on 2019/11/15.
//  Copyright © 2019年 RWN. All rights reserved.
//

#import "VideoController.h"
#import <AVKit/AVKit.h>

@interface VideoController ()

@property (nonatomic, strong) AVPlayer *player;

@property (nonatomic, strong) AVPlayerLayer *playerLayer;

@end

@implementation VideoController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:self.videoUrl];
    //如果要切换视频需要调AVPlayer的replaceCurrentItemWithPlayerItem:方法
    self.player = [AVPlayer playerWithPlayerItem:playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.frame = CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height);
    self.playerLayer.autoreverses = YES;
    //放置播放器的视图
    [self.view.layer addSublayer:self.playerLayer];
    [_player play];
    
    // Do any additional setup after loading the view.
}



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
