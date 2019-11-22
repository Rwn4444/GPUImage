//
//  ViewController.m
//  VideoTool
//
//  Created by RWN on 2019/11/13.
//  Copyright © 2019年 RWN. All rights reserved.
//

#import "ViewController.h"
#import <GPUImage/GPUImage.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <GPUImageBeautifyFilter/GPUImageBeautifyFilter.h>
#import "VideoController.h"
#import "TencentBeautyFilter.h"
#import "RWNImageMovieWriter.h"
@interface ViewController ()

//@property (nonatomic, strong) GPUImageStillCamera* stillCamera;

@property (nonatomic, strong) GPUImageStillCamera*  videoCamera;

@property (nonatomic, strong) GPUImageFilter * filter ;

@property (nonatomic, strong) RWNImageMovieWriter *movieWriter;

@property (nonatomic, strong) GPUImageView *filterView;
///磨皮
@property (nonatomic, strong) GPUImageBilateralFilter *bilateralFilter;
///美白
@property (nonatomic, strong) GPUImageBrightnessFilter *brightnessFilter;

@property (nonatomic, strong) NSURL *movieURL;

@property (weak, nonatomic) IBOutlet UIButton *startBtn;

@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (weak, nonatomic) IBOutlet UIStackView *filterStack;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initGPUImageView];
    // Do any additional setup after loading the view, typically from a nib.
}


-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    
}


-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}


-(void)initGPUImageView{
    
//    [self initPhotoGPUImageCamer];
    [self initVideoGPUImageCamer];
    [self.view bringSubviewToFront:self.startBtn];
    [self.view bringSubviewToFront:self.nextBtn];
    [self.view bringSubviewToFront:self.filterStack];
    
}


- (IBAction)nextBtnClick:(UIButton *)sender {
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.filter removeTarget:self.movieWriter];
        self.videoCamera.audioEncodingTarget = nil;
        [self.movieWriter finishRecording];
        self.movieWriter = nil;
        
        
        VideoController * video = [[VideoController alloc] init];
        video.videoUrl = self.movieURL;
        [self.navigationController pushViewController:video animated:YES];
        
    });
    
    
    
}

- (IBAction)startOrEndBtnClick:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    if (sender.selected) {///打开
        dispatch_async(dispatch_get_main_queue(), ^{
            
            if (self.movieWriter) {
                [self.movieWriter continueWrite];
            }else{
                //设置写入地址
                NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/LiveMovied.mp4"];
                self.movieURL = [NSURL fileURLWithPath:pathToMovie];
                if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
                    [[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:nil];
                }
                self.movieWriter = [[RWNImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height ) ];
                //设置为liveVideo
                self.movieWriter.encodingLiveVideo = YES;
                self.movieWriter.shouldPassthroughAudio=YES;
                self.movieWriter.hasAudioTrack=YES;
                [self.filter addTarget:self.movieWriter];
                //设置声音
                self.videoCamera.audioEncodingTarget = self.movieWriter;
                [self.movieWriter configure];
                [self.movieWriter startRecording];
            }
           
        });
    }else{///关闭
        [self.movieWriter configure];
        [self.movieWriter pause];
    }
    
}
// 磨皮滤镜 0-10 越小磨皮越厉害 值越小，磨皮效果越好
- (IBAction)moqisliderChanged:(UISlider *)sender {
    [self.bilateralFilter setDistanceNormalizationFactor:sender.value];
    NSLog(@"%f",sender.value);
}
///美白滤镜- 0-0.5 亮度
- (IBAction)beautifulSlideChanged:(UISlider *)sender {
    self.brightnessFilter.brightness = sender.value;
    NSLog(@"%f",sender.value);
}


///修改滤镜
- (IBAction)changeFilter:(UIButton *)sender {
    
    switch (sender.tag) {
        case 0:///关闭
            self.filter = [[GPUImageBilateralFilter alloc] init];
            break;
        case 1:///自然
            self.filter = [[TencentBeautyFilter alloc] init];
            break;
        case 2:///怀旧
            self.filter = [[GPUImageContrastFilter alloc] init];
            break;
        case 3:///粉嫩
            self.filter = [[GPUImageSepiaFilter alloc] init];
            break;
        case 4:///黑白
            self.filter = [[GPUImageSobelEdgeDetectionFilter alloc]init];
            break;
        case 5:///翻转摄像头
            [self.videoCamera rotateCamera];
            return;
            break;
        default:
            [self.navigationController popViewControllerAnimated:YES];
            return;
            break;
    }
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.videoCamera removeAllTargets];
        [self.videoCamera addTarget:self.filter];
        [self.filter addTarget:self.filterView];
        if (self.movieWriter) {
            [self.filter addTarget:self.movieWriter];
        }
    });
    
}


#pragma mark ---- 录像相机 -----
-(void)initVideoGPUImageCamer{
    
    self.videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPresetHigh cameraPosition:AVCaptureDevicePositionBack];
    //输出方向为竖屏
    self.videoCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    //前者摄像头水平镜像，后置摄像头水平镜像
//    self.videoCamera.horizontallyMirrorRearFacingCamera = YES;
    self.videoCamera.horizontallyMirrorFrontFacingCamera = YES;
    ///打印log日志
//    self.videoCamera.runBenchmark = YES;
    ///解决录制开始和结束的时候闪一下的问题
    [self.videoCamera addAudioInputsAndOutputs];
    
    if ([self.videoCamera.inputCamera lockForConfiguration:nil]) {
        //自动对焦
        if ([self.videoCamera.inputCamera isFocusModeSupported:AVCaptureFocusModeContinuousAutoFocus]) {
            [self.videoCamera.inputCamera setFocusMode:AVCaptureFocusModeContinuousAutoFocus];
        }
        //自动曝光
        if ([self.videoCamera.inputCamera isExposureModeSupported:AVCaptureExposureModeContinuousAutoExposure]) {
            [self.videoCamera.inputCamera setExposureMode:AVCaptureExposureModeContinuousAutoExposure];
        }
        //自动白平衡
        if ([self.videoCamera.inputCamera isWhiteBalanceModeSupported:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance]) {
            [self.videoCamera.inputCamera setWhiteBalanceMode:AVCaptureWhiteBalanceModeContinuousAutoWhiteBalance];
        }
        
        [self.videoCamera.inputCamera unlockForConfiguration];
    }
    
    
    
    // 磨皮滤镜
    GPUImageBilateralFilter *bilateralFilter = [[GPUImageBilateralFilter alloc] init];
    self.filter = bilateralFilter;
    
    // 美白滤镜-- 亮度 亮度：调整亮度（-1.0 - 1.0，默认为0.0）
//    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
//    self.brightnessFilter = brightnessFilter;
    
    //显示view
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height )  ];
    filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    self.filterView = filterView ;
    //组合
    [self.videoCamera addTarget:self.filter];
    [self.filter addTarget:self.filterView];
    [self.view addSubview:filterView];
    //相机开始运行
    [self.videoCamera startCameraCapture];
    
}


/*
-(void)saveVideo{
 
    dispatch_async(dispatch_get_main_queue(), ^{
        self.videoCamera.audioEncodingTarget = nil;
        [self.filter removeTarget:self.movieWriter];
        [self.movieWriter finishRecording];
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        if ([library videoAtPathIsCompatibleWithSavedPhotosAlbum:self.movieURL]) {
            [library writeVideoAtPathToSavedPhotosAlbum:self.movieURL completionBlock:^(NSURL *assetURL, NSError *error) {
                if (!error) {
                    NSLog(@"成功了");
//                    [[NSFileManager defaultManager] removeItemAtURL:_movieURL error:nil];
                }
                
            }];
        }
    });
    
}

#pragma mark ---- 拍照相机 -----
///初始化拍照相机

-(void)initPhotoGPUImageCamer{
    
    GPUImageView *primaryView = [[GPUImageView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    primaryView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];
    self.filter = filter;
    
    GPUImageStillCamera* stillCamera = [[GPUImageStillCamera alloc] init];
    self.stillCamera = stillCamera;
    //设置相机方向
    stillCamera.outputImageOrientation = UIInterfaceOrientationPortrait;
    
    [stillCamera addTarget:filter];
    [filter addTarget:primaryView];
    [stillCamera startCameraCapture];
    [self.view addSubview:primaryView];
    
}


///保存到相册
-(void)saveImageToabulm{
    
    [self.stillCamera capturePhotoAsJPEGProcessedUpToFilter:self.filter withCompletionHandler:^(NSData *processedJPEG, NSError *error){
        
        // Save to assets library
        ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];
        [library writeImageDataToSavedPhotosAlbum:processedJPEG metadata:self.stillCamera.currentCaptureMetadata completionBlock:^(NSURL *assetURL, NSError *error2)
         {
             if (error2) {
                 NSLog(@"ERROR: the image failed to be written");
             }
             else {
                 NSLog(@"PHOTO SAVED - assetURL: %@", assetURL);
             }
             
             runOnMainQueueWithoutDeadlocking(^{
                 //                 [photoCaptureButton setEnabled:YES];
             });
         }];
    }];
    
    
}

*/



@end
