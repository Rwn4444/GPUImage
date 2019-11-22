//
//  SecondViewController.m
//  VideoTool
//
//  Created by RWN on 2019/11/19.
//  Copyright © 2019年 RWN. All rights reserved.
//

#import "SecondViewController.h"
#import <GPUImage/GPUImage.h>
#import "VideoTool.h"
#import "VideoController.h"
#import "RWNGCDTime.h"
#import "TencentBeautyFilter.h"

static const NSInteger allTime = 30 ;

@interface SecondViewController ()

@property (nonatomic, strong) GPUImageStillCamera*  videoCamera;

@property (nonatomic, strong) GPUImageFilter * filter ;

@property (nonatomic, strong) GPUImageFilterGroup * normalFilter;

@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;

@property (nonatomic, strong) GPUImageView *filterView;

@property (nonatomic, strong) GPUImageMovie *movieFile;

@property (nonatomic, strong) GPUImageUIElement *uiElement;

@property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter;

@property (nonatomic, strong) NSURL *movieURL;

@property (nonatomic, copy) NSString *pathUrl;

@property (nonatomic, strong) NSMutableArray *videosArray;
@property (nonatomic, strong) NSMutableArray *timesArray;
@property (nonatomic, copy) NSString *timerIdentifier;
@property (nonatomic, assign) NSInteger  currentTime;
@property (nonatomic, assign) NSInteger  shootTime;


@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIButton *deleteBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;

@property (weak, nonatomic) IBOutlet UISlider *timeSlider;

@property (weak, nonatomic) IBOutlet UIStackView *stack;

@end

@implementation SecondViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.shootTime = 0 ;
    [self initGPUImageView];
    // Do any additional setup after loading the view.
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
    
    [self initVideoGPUImageCamer];
    [self.view bringSubviewToFront:self.startBtn];
    [self.view bringSubviewToFront:self.nextBtn];
    [self.view bringSubviewToFront:self.deleteBtn];
    [self.view bringSubviewToFront:self.timeSlider];
    [self.view bringSubviewToFront:self.stack];

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
    
    self.videoCamera.frameRate = 30;
    
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
    
    GPUImageFilterGroup * filterGroup = [[GPUImageFilterGroup alloc] init];
    self.normalFilter = filterGroup ;
    TencentBeautyFilter *filter = [[TencentBeautyFilter alloc] init];
    [self addGPUImageFilter:filter];
    // 磨皮滤镜
//    GPUImageBrightnessFilter *bilateralFilter = [[GPUImageBrightnessFilter alloc] init];
//    self.filter = bilateralFilter;
    
    // 美白滤镜-- 亮度 亮度：调整亮度（-1.0 - 1.0，默认为0.0）
    //    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    //    self.brightnessFilter = brightnessFilter;
    
    //显示view
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height )  ];
    filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    self.filterView = filterView ;
    //组合
    [self.videoCamera addTarget:self.normalFilter];
    [self.normalFilter addTarget:self.filterView];
    [self.view addSubview:filterView];
    //相机开始运行
    [self.videoCamera startCameraCapture];

    
}

/**
 原理：
 1. filterGroup(addFilter) 滤镜组添加每个滤镜
 2. 按添加顺序（可自行调整）前一个filter(addTarget) 添加后一个filter
 3. filterGroup.initialFilters = @[第一个filter]];
 4. filterGroup.terminalFilter = 最后一个filter;
 */
- (void)addGPUImageFilter:(GPUImageOutput<GPUImageInput> *)filter
{
    [_normalFilter addFilter:filter];
    
    GPUImageOutput<GPUImageInput> *newTerminalFilter = filter;
    
    NSInteger count = _normalFilter.filterCount;
    
    if (count == 1)
    {
        _normalFilter.initialFilters = @[newTerminalFilter];
        _normalFilter.terminalFilter = newTerminalFilter;
        
    } else
    {
        GPUImageOutput<GPUImageInput> *terminalFilter    = _normalFilter.terminalFilter;
        NSArray *initialFilters                          = _normalFilter.initialFilters;
        
        [terminalFilter addTarget:newTerminalFilter];
        
        _normalFilter.initialFilters = @[initialFilters[0]];
        _normalFilter.terminalFilter = newTerminalFilter;
    }
}







- (IBAction)startBtnClick:(UIButton *)sender {
    
    sender.selected = !sender.selected;
    if (sender.selected) {
        [self startRecord];
    }else{
        [self endRecord];
    }
    
}

-(void)startRecord{
    
    self.currentTime = 0;
    __weak typeof(self) weakSelf = self;
    self.timerIdentifier = [RWNGCDTime RWNTimeDoTask:^(dispatch_source_t timer) {
        self.currentTime ++ ;
        if (self.currentTime >= allTime) {
            [weakSelf endRecord];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            weakSelf.timeSlider.value = [self getAllTime] + self.currentTime;
        });
    } interval:1];
    
    
    //设置写入地址
    NSString *pathToMovie = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"LiveMovied_%ld.mp4",(long)self.shootTime]];
    self.pathUrl = pathToMovie;
    self.movieURL = [NSURL fileURLWithPath:pathToMovie];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:nil];
    }
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height ) ];
    //设置为liveVideo
    self.movieWriter.encodingLiveVideo = YES;
    self.movieWriter.shouldPassthroughAudio=YES;
    self.movieWriter.hasAudioTrack=YES;
    [self.filter addTarget:self.movieWriter];
    //设置声音
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    [self.movieWriter startRecording];
    self.shootTime ++ ;
    
    
}

-(void)endRecord{
    
    [RWNGCDTime cancaleTaskWithIdentifier:self.timerIdentifier];
    self.currentTime = 0;
    
    [self.filter removeTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = nil;
    [self.movieWriter finishRecording];
    [self.videosArray addObject:self.pathUrl];
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.timesArray addObject:@(self.timeSlider.value)];
    });
    
}


-(NSInteger)getAllTime{
    
    NSInteger time = 0;
    for (NSNumber * numberTime in self.timesArray) {
        time = time + [numberTime integerValue];
    }
    return time;
    
}


- (IBAction)deleteBtnClick:(UIButton *)sender {
    if (self.videosArray.count>0) {
        NSString * path =  [self.videosArray lastObject];
        if ([[NSFileManager defaultManager] fileExistsAtPath:path]) {
            [[NSFileManager defaultManager] removeItemAtPath:path error:nil];
        }
        [self.videosArray removeLastObject];
        if (self.timesArray.count >0) {
            [self.timesArray removeLastObject];
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            
            NSInteger allTime = [self getAllTime] + self.currentTime;
            self.timeSlider.value = allTime;
            NSLog(@"%ld",(long)allTime);
            
        });
    }else{
        NSLog(@"没有可以删除的视频");
    }
}

- (IBAction)nextBtnClick:(UIButton *)sender {
    if (self.currentTime > 0) {
        [self endRecord];
    }
    
    NSString *pathToMovie = [NSTemporaryDirectory() stringByAppendingPathComponent:@"outPut.mp4"];
    [VideoTool mergeAndExportVideos:self.videosArray withOutPath:pathToMovie outputFileType:AVFileTypeMPEG4  presetName:AVAssetExportPresetHighestQuality didComplete:^(NSError * _Nonnull error, NSURL * _Nonnull mergeFileURL) {
        
        NSLog(@"转换完成");
        [self addWaterMarkWithUrl:mergeFileURL];
//        VideoController * video = [[VideoController alloc] init];
//        video.videoUrl = mergeFileURL;
//        [self.navigationController pushViewController:video animated:YES];
        
        
    }];
    
}

///修改滤镜
- (IBAction)changeFilter:(UIButton *)sender {
    
//    switch (sender.tag) {
//        case 0:///关闭
//            self.filter = [[GPUImageBrightnessFilter alloc] init];
//            break;
//        case 1:///自然
//            self.filter = [[GPUImageBilateralFilter alloc] init];
//            break;
//        case 2:///怀旧
//            self.filter = [[GPUImageContrastFilter alloc] init];
//            break;
//        case 3:///粉嫩
//            self.filter = [[GPUImageSepiaFilter alloc] init];
//            break;
//        case 4:///黑白
//            self.filter = [[GPUImageSobelEdgeDetectionFilter alloc]init];
//            break;
//        case 5:///翻转摄像头
//            [self.videoCamera rotateCamera];
//            return;
//            break;
//        default:
//            [self.navigationController popViewControllerAnimated:YES];
//            return;
//            break;
//    }
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [self.videoCamera removeAllTargets];
//        [self.videoCamera addTarget:self.filter];
//        [self.filter addTarget:self.filterView];
//        if (self.movieWriter) {
//            [self.filter addTarget:self.movieWriter];
//        }
//    });
    if (sender.tag == 5) {
        [self.videoCamera rotateCamera];
    }else if (sender.tag == 6){
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self setNormalFilterIndex:sender.tag];
    }
    
    
}


- (void)setNormalFilterIndex:(NSInteger)index {
    //组合滤镜
    [self.videoCamera removeAllTargets];
    _normalFilter = [[GPUImageFilterGroup alloc] init];
    //    if (self.beautyLevel == 0 && self.brightLevel == 0) {//无美颜效果
    //        _normalFilter =  [self getDeafultFilter];
    //    }else {
    TencentBeautyFilter *beautyfilter = [[TencentBeautyFilter alloc] init];
    [self addGPUImageFilter:beautyfilter];
    //    }
    if (index == 0 ) {
        GPUImageOutput<GPUImageInput> *filter = [[GPUImageBrightnessFilter alloc] init];
        if (filter) [self addGPUImageFilter:filter];
    }else if (index == 1){
        GPUImageOutput<GPUImageInput> *filter = [[GPUImageBilateralFilter alloc] init];
        if (filter) [self addGPUImageFilter:filter];
    }else if (index == 2){
        GPUImageOutput<GPUImageInput> *filter = [[GPUImageContrastFilter alloc] init];
        if (filter) [self addGPUImageFilter:filter];
    }else if (index == 3){
        GPUImageOutput<GPUImageInput> *filter = [[GPUImageSepiaFilter alloc] init];
        if (filter) [self addGPUImageFilter:filter];
    }else{
        GPUImageOutput<GPUImageInput> *filter = [[GPUImageSobelEdgeDetectionFilter alloc] init];
        if (filter) [self addGPUImageFilter:filter];
    }
    
    [self.videoCamera addTarget:self.normalFilter];
    [self.normalFilter addTarget:self.filterView];
    if (self.movieWriter) {
        [self.normalFilter addTarget:self.movieWriter];
    }
}




- (void)addWaterMarkWithUrl:(NSURL *)videoURL{
    
    /* 使用GUPImage添加水印，原理上相当于添加一层滤镜  */
    self.movieFile = [[GPUImageMovie alloc] initWithURL:videoURL];
    //    _movieFile.runBenchmark = YES;
     self.movieFile.playAtActualSpeed = NO;
    
    // 获取视频的size，从而确定水印的位置
    AVAsset *asset = [AVAsset assetWithURL:videoURL];
    CGSize size = CGSizeZero;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if (tracks.count > 0) {
        AVAssetTrack *videoTrack = tracks.firstObject;
        size = CGSizeMake(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
    }
    
    // 文字水印（同理可添加图片）
//    UILabel *label = [[UILabel alloc] init];
//    label.text = @"@Ander";
//    label.font =[UIFont systemFontOfSize:18];
//    label.textColor = [UIColor redColor];
//    label.textAlignment = NSTextAlignmentCenter;
//    [label sizeToFit];
//    label.frame = CGRectMake(size.width - 100 - 20, size.height - 20 - 20, 100, 20);
//
    UIImageView *waterImageView =[[UIImageView alloc] initWithFrame:CGRectMake(21, 64+25, 93, 36)];
    waterImageView.image = [UIImage imageNamed:@"water"];
    // 将水印放在一个跟视频大小相等的View上
    UIView *subView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
    [subView addSubview:waterImageView];
    
    self.uiElement = [[GPUImageUIElement alloc] initWithView:subView];
    _blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    GPUImageFilter* progressFilter = [[GPUImageFilter alloc] init];
    
    //注意URL不要出错，不然下面会崩溃
    NSString *pathToMovie = [NSHomeDirectory() stringByAppendingPathComponent:@"Documents/Movie.mp4"];
    unlink([pathToMovie UTF8String]);   // 删除当前该路径下的文件
    NSURL *movieURL = [NSURL fileURLWithPath:pathToMovie];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:nil];
    }
    
    _movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:movieURL size:size];
    [_movieFile addTarget:progressFilter];
    [progressFilter addTarget:_blendFilter];
    [_uiElement addTarget:_blendFilter];
    
    _movieWriter.shouldPassthroughAudio = YES;
    // 判断是否有音轨
    if ([asset tracksWithMediaType:AVMediaTypeAudio].count > 0){
        _movieFile.audioEncodingTarget = _movieWriter;
    } else {
        _movieFile.audioEncodingTarget = nil;
    }
    [_movieFile enableSynchronizedEncodingUsingMovieWriter:_movieWriter];
    [_blendFilter addTarget:_movieWriter];
    
    [_movieWriter startRecording];
    [_movieFile startProcessing];
    __weak typeof(self) weakSelf = self;
    //渲染
    [progressFilter setFrameProcessingCompletionBlock:^(GPUImageOutput *output, CMTime time) {
//        dispatch_async(dispatch_get_main_queue(), ^{
//            waterImageView.hidden = NO;
//        });
        // 这句必须有
        [weakSelf.uiElement update];
    }];
    
   
    
    
    [_movieWriter setCompletionBlock:^{
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf.blendFilter removeTarget:strongSelf.movieWriter];
            [strongSelf.movieWriter finishRecording];
            
            VideoController * video = [[VideoController alloc] init];
            video.videoUrl = movieURL;
            [strongSelf.navigationController pushViewController:video animated:YES];
        });
        
    }];
    
    /*
    思考1：响应链解析中的GPUImageFilter有什么作用？是否可以去掉？
    思考2：frameProcessingCompletionBlock里面需要做什么样的操作？为什么？
    思考3：能否对图像水印进行复杂的位置变换？
    
   
    思考1：目的是每帧回调；去掉会导致图像无法显示。
    思考2：回调需要调用update操作；因为update只会输出一次纹理信息，只适用于一帧。
    思考3：在回调中对UIView进行操作即可；或者使用GPUImageTransformFilter。
    */
    
}






-(NSMutableArray *)videosArray{
    if (!_videosArray) {
        _videosArray = [NSMutableArray array];
    }
    return _videosArray;
}

-(NSMutableArray *)timesArray{
    if (!_timesArray) {
        _timesArray = [NSMutableArray array];
    }
    return _timesArray;
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
