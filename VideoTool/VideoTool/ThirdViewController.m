//
//  ThirdViewController.m
//  VideoTool
//
//  Created by RWN on 2019/11/20.
//  Copyright © 2019年 RWN. All rights reserved.
//

#import "ThirdViewController.h"
#import <GPUImage/GPUImage.h>
#import "VideoTool.h"
#import "VideoController.h"
#import <iflyMSC/IFlyFaceSDK.h>
#import "IFlyFaceImage.h"
#import "IFlyFaceResultKeys.h"
#import "CalculatorTools.h"

#define POINTS_KEY @"POINTS_KEY"
#define RECT_KEY   @"RECT_KEY"
#define RECT_ORI   @"RECT_ORI"


@interface ThirdViewController ()<GPUImageVideoCameraDelegate>

@property (nonatomic, strong) GPUImageStillCamera*  videoCamera;

@property (nonatomic, strong) GPUImageFilter * filter ;

@property (nonatomic, strong) GPUImageMovieWriter *movieWriter;

@property (nonatomic, strong) GPUImageView *filterView;

@property (nonatomic, strong) GPUImageMovie *movieFile;

@property (nonatomic, strong) GPUImageUIElement *uiElement;

@property (nonatomic, strong) GPUImageAlphaBlendFilter *blendFilter;

@property (nonatomic, strong) NSURL *movieURL;

@property (nonatomic, copy) NSString *pathUrl;

@property (weak, nonatomic) IBOutlet UIButton *startBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;
@property (weak, nonatomic) IBOutlet UIStackView *stack;

@property(strong, nonatomic) CIDetector *faceDetector;
@property (nonatomic, strong ) IFlyFaceDetector  * iflyfaceDetector;
@property (nonatomic, strong)NSArray  *faceInfos; // 人脸信息集 每个人脸的 rect 和特征点 信息


@end

@implementation ThirdViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
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
    
    [self initVideoGPUImageCamerWithWaterImage];
    [self.view bringSubviewToFront:self.startBtn];
    [self.view bringSubviewToFront:self.nextBtn];
    [self.view bringSubviewToFront:self.stack];
    
}

-(void)initVideoGPUImageCamerWithWaterImage{
    
    self.videoCamera = [[GPUImageStillCamera alloc] initWithSessionPreset:AVCaptureSessionPreset640x480 cameraPosition:AVCaptureDevicePositionBack];
    self.videoCamera.delegate = self;
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
    
    
    
    // 磨皮滤镜
    GPUImageBrightnessFilter *bilateralFilter = [[GPUImageBrightnessFilter alloc] init];
    self.filter = bilateralFilter;
    
    // 美白滤镜-- 亮度 亮度：调整亮度（-1.0 - 1.0，默认为0.0）
    //    GPUImageBrightnessFilter *brightnessFilter = [[GPUImageBrightnessFilter alloc] init];
    //    self.brightnessFilter = brightnessFilter;
    
    UIImageView *waterImageView =[[UIImageView alloc] initWithFrame:CGRectMake(21, 64+25, 93, 36)];
    waterImageView.image = [UIImage imageNamed:@"water"];
    // 将水印放在一个跟视频大小相等的View上
    UIView *subView = [[UIView alloc] initWithFrame: CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height ) ];
//    [subView addSubview:waterImageView];
    
    self.uiElement = [[GPUImageUIElement alloc] initWithView:subView];
    _blendFilter = [[GPUImageAlphaBlendFilter alloc] init];
    _blendFilter.mix = 1;

    
    __weak typeof(self) weakSelf = self;
    [self.filter setFrameProcessingCompletionBlock:^(GPUImageOutput *outPut, CMTime time) {
        [weakSelf.uiElement update];
    }];
    
    
    //显示view
    GPUImageView *filterView = [[GPUImageView alloc] initWithFrame:CGRectMake(0, 0, UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height )  ];
    filterView.fillMode = kGPUImageFillModePreserveAspectRatioAndFill;
    
    self.filterView = filterView ;
    //组合
    [self.videoCamera addTarget:self.filter];
    //    [self.filter addTarget:self.filterView];
    [self.filter addTarget:self.blendFilter];
    [self.uiElement addTarget:self.blendFilter];
    [self.blendFilter addTarget:self.filterView];
    [self.blendFilter disableSecondFrameCheck];

    [self.view addSubview:filterView];
    //相机开始运行
    [self.videoCamera startCameraCapture];
    
    
    // 特征检测
    NSDictionary *detectorOptions = [[NSDictionary alloc] initWithObjectsAndKeys:CIDetectorAccuracyLow, CIDetectorAccuracy, nil];
    _faceDetector = [CIDetector detectorOfType:CIDetectorTypeFace context:nil options:detectorOptions];
    _iflyfaceDetector = [IFlyFaceDetector sharedInstance];
    [_iflyfaceDetector setParameter:@"1"  forKey:@"detect"];
    [_iflyfaceDetector setParameter:@"1" forKey:@"align"];
    
    
    
}

- (void)willOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer{
    
    NSLog(@"123456");
    // 使用科大讯飞人脸识别
    IFlyFaceImage* faceImage=[self faceImageFromSampleBuffer:sampleBuffer];
    [self onOutputFaceImage:faceImage];
    faceImage = nil;
}


- (IFlyFaceImage *) faceImageFromSampleBuffer:(CMSampleBufferRef) sampleBuffer{
    
    //获取灰度图像数据
    CVPixelBufferRef pixelBuffer = (CVPixelBufferRef)CMSampleBufferGetImageBuffer(sampleBuffer);
    CVPixelBufferLockBaseAddress(pixelBuffer, 0);
    
    uint8_t *lumaBuffer  = (uint8_t *)CVPixelBufferGetBaseAddressOfPlane(pixelBuffer, 0);
    
    size_t bytesPerRow = CVPixelBufferGetBytesPerRowOfPlane(pixelBuffer,0);
    size_t width  = CVPixelBufferGetWidth(pixelBuffer);
    size_t height = CVPixelBufferGetHeight(pixelBuffer);
    
    CGColorSpaceRef grayColorSpace = CGColorSpaceCreateDeviceGray();
    
    CGContextRef context=CGBitmapContextCreate(lumaBuffer, width, height, 8, bytesPerRow, grayColorSpace,0);
    CGImageRef cgImage = CGBitmapContextCreateImage(context);
    
    //    cgImage = CGImageCreateWithImageInRect(cgImage, CGRectMake(0, , , <#CGFloat height#>))
    CVPixelBufferUnlockBaseAddress(pixelBuffer, 0);
    
    IFlyFaceDirectionType faceOrientation=[self faceImageOrientation];
    
    IFlyFaceImage* faceImage=[[IFlyFaceImage alloc] init];
    if(!faceImage){
        return nil;
    }
    
    CGDataProviderRef provider = CGImageGetDataProvider(cgImage);
    
    faceImage.data= (__bridge_transfer NSData*)CGDataProviderCopyData(provider);
    faceImage.width=width;
    faceImage.height=height;
    faceImage.direction=faceOrientation;
    
    CGImageRelease(cgImage);
    CGContextRelease(context);
    CGColorSpaceRelease(grayColorSpace);
    
    
    
    return faceImage;
    
}

-(IFlyFaceDirectionType)faceImageOrientation{
    
    IFlyFaceDirectionType faceOrientation=IFlyFaceDirectionTypeLeft;
    BOOL isFrontCamera=self.videoCamera.inputCamera.position==AVCaptureDevicePositionFront;
    switch (self.interfaceOrientation) {
        case UIDeviceOrientationPortrait:{//
            faceOrientation=IFlyFaceDirectionTypeLeft;
        }
            break;
        case UIDeviceOrientationPortraitUpsideDown:{
            faceOrientation=IFlyFaceDirectionTypeRight;
        }
            break;
        case UIDeviceOrientationLandscapeRight:{
            faceOrientation=isFrontCamera?IFlyFaceDirectionTypeUp:IFlyFaceDirectionTypeDown;
        }
            break;
        default:{//
            faceOrientation=isFrontCamera?IFlyFaceDirectionTypeDown:IFlyFaceDirectionTypeUp;
        }
            
            break;
    }
    
    return faceOrientation;
}
-(void)onOutputFaceImage:(IFlyFaceImage*)faceImg{
    
    NSString* strResult=[self.iflyfaceDetector trackFrame:faceImg.data withWidth:faceImg.width height:faceImg.height direction:(int)faceImg.direction];
    //    NSLog(@"result:%@",strResult);
    
    //此处清理图片数据，以防止因为不必要的图片数据的反复传递造成的内存卷积占用。
    faceImg.data=nil;
    
    NSMethodSignature *sig = [self methodSignatureForSelector:@selector(praseTrackResult:OrignImage:)];
    if (!sig) return;
    NSInvocation* invocation = [NSInvocation invocationWithMethodSignature:sig];
    [invocation setTarget:self];
    [invocation setSelector:@selector(praseTrackResult:OrignImage:)];
    [invocation setArgument:&strResult atIndex:2];
    [invocation setArgument:&faceImg atIndex:3];
    [invocation retainArguments];
    [invocation performSelectorOnMainThread:@selector(invoke) withObject:nil  waitUntilDone:NO];
    faceImg=nil;
}

-(void)praseTrackResult:(NSString*)result OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!result){
        return;
    }
    
    @try {
        NSError* error;
        NSData* resultData=[result dataUsingEncoding:NSUTF8StringEncoding];
        NSDictionary* faceDic=[NSJSONSerialization JSONObjectWithData:resultData options:NSJSONReadingMutableContainers error:&error];
        resultData=nil;
        if(!faceDic){
            return;
        }
        
        NSString* faceRet=[faceDic objectForKey:KCIFlyFaceResultRet];
        NSArray* faceArray=[faceDic objectForKey:KCIFlyFaceResultFace];
        faceDic=nil;
        
        int ret=0;
        if(faceRet){
            ret=[faceRet intValue];
        }
        
        //没有检测到人脸或发生错误
        if (ret || !faceArray || [faceArray count]<1) {
            if (!self.faceInfos) {
                return;
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                [self performSelector:@selector(hideFace) withObject:nil afterDelay:0.1];
                
            } ) ;
            return;
        }
        
        //检测到人脸
        
        NSMutableArray *arrPersons = [NSMutableArray array] ;
        
        for(id faceInArr in faceArray)
        {
            
            if(faceInArr && [faceInArr isKindOfClass:[NSDictionary class]]){
                
                NSDictionary* positionDic=[faceInArr objectForKey:KCIFlyFaceResultPosition];
                NSString* rectString=[self praseDetect:positionDic OrignImage: faceImg];
                positionDic=nil;
                
                NSDictionary* landmarkDic=[faceInArr objectForKey:KCIFlyFaceResultLandmark];
                NSMutableDictionary* strPoints=[self praseAlign:landmarkDic OrignImage:faceImg];
                landmarkDic=nil;
                
                
                NSMutableDictionary *dicPerson = [NSMutableDictionary dictionary] ;
                if(rectString){
                    [dicPerson setObject:rectString forKey:RECT_KEY];
                }
                if(strPoints){
                    [dicPerson setObject:strPoints forKey:POINTS_KEY];
                }
                
                strPoints=nil;
                
                [dicPerson setObject:@"0" forKey:RECT_ORI];
                [arrPersons addObject:dicPerson] ;
                
                dicPerson=nil;
                
            }
        }
        dispatch_async(dispatch_get_main_queue(), ^{
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideFace) object:nil];
            //            [self showFaceLandmarksAndFaceRectWithPersonsArray:arrPersons];
            self.faceInfos = arrPersons;
            
//            [self reSetFaceUI];
            //            [self needUpdateFace];
        } ) ;
        
        faceArray=nil;
    }
    @catch (NSException *exception) {
        NSLog(@"prase exception:%@",exception.name);
    }
    @finally {
    }
    
}

-(NSString*)praseDetect:(NSDictionary* )positionDic OrignImage:(IFlyFaceImage*)faceImg{
    
    if(!positionDic){
        return nil;
    }
    
    // 判断摄像头方向
    BOOL isFrontCamera=self.videoCamera.inputCamera.position==AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat width = self.view.bounds.size.width;
    CGFloat widthScaleBy = width / faceImg.height;
    CGFloat heightScaleBy = width/0.75 / faceImg.width;
    
    CGFloat bottom =[[positionDic objectForKey:KCIFlyFaceResultBottom] floatValue];
    CGFloat top=[[positionDic objectForKey:KCIFlyFaceResultTop] floatValue];
    CGFloat left=[[positionDic objectForKey:KCIFlyFaceResultLeft] floatValue];
    CGFloat right=[[positionDic objectForKey:KCIFlyFaceResultRight] floatValue];
    
    
    float cx = (left+right)/2;
    float cy = (top + bottom)/2;
    float w = right - left;
    float h = bottom - top;
    
    float ncx = cy ;
    float ncy = cx ;
    
    CGRect rectFace = CGRectMake(ncx-w/2 ,ncy-w/2 , w, h);
    
    if(!isFrontCamera){
        rectFace=rSwap(rectFace);
        rectFace=rRotate90(rectFace, faceImg.height, faceImg.width);
    }
    
    rectFace=rScale(rectFace, widthScaleBy, heightScaleBy);
    
    //    if (_scale == 1) {
    //        rectFace =
    //    }
    
    return NSStringFromCGRect(rectFace);
    
}

-(NSMutableDictionary *)praseAlign:(NSDictionary* )landmarkDic OrignImage:(IFlyFaceImage*)faceImg{
    if(!landmarkDic){
        return nil;
    }
    
    // 判断摄像头方向
    BOOL isFrontCamera=self.videoCamera.inputCamera.position==AVCaptureDevicePositionFront;
    
    // scale coordinates so they fit in the preview box, which may be scaled
    CGFloat width =  self.view.bounds.size.width;
    CGFloat widthScaleBy = width / faceImg.height;
    CGFloat heightScaleBy = width/0.75 / faceImg.width;
    
    NSMutableDictionary *arrStrPoints = [NSMutableDictionary dictionary] ;
    NSEnumerator* keys=[landmarkDic keyEnumerator];
    for(id key in keys){
        id attr=[landmarkDic objectForKey:key];
        if(attr && [attr isKindOfClass:[NSDictionary class]]){
            
            id attr=[landmarkDic objectForKey:key];
            CGFloat x=[[attr objectForKey:KCIFlyFaceResultPointX] floatValue];
            CGFloat y=[[attr objectForKey:KCIFlyFaceResultPointY] floatValue];
            
            CGPoint p = CGPointMake(y,x);
            
            if(!isFrontCamera){
                p=pSwap(p);
                p=pRotate90(p, faceImg.height, faceImg.width);
            }
            
            p=pScale(p, widthScaleBy, heightScaleBy);
            
            //            NSDictionary *dict = @{key : NSStringFromCGPoint(p)};
            //            [arrStrPoints addObject:dict];
            [arrStrPoints setObject:NSStringFromCGPoint(p) forKey:key];
            //            dict = nil;
            
        }
    }
    return arrStrPoints;
    
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
    
    //设置写入地址
    NSString *pathToMovie = [NSTemporaryDirectory() stringByAppendingPathComponent:@"LiveMovied.mp4"];
    self.pathUrl = pathToMovie;
    self.movieURL = [NSURL fileURLWithPath:pathToMovie];
    if ([[NSFileManager defaultManager] fileExistsAtPath:pathToMovie]) {
        [[NSFileManager defaultManager] removeItemAtPath:pathToMovie error:nil];
    }
    self.movieWriter = [[GPUImageMovieWriter alloc] initWithMovieURL:self.movieURL size:CGSizeMake(UIScreen.mainScreen.bounds.size.width, UIScreen.mainScreen.bounds.size.height)];
    //设置为liveVideo
    self.movieWriter.encodingLiveVideo = YES;
    self.movieWriter.shouldPassthroughAudio=YES;
    self.movieWriter.hasAudioTrack=YES;
    [self.filter addTarget:self.movieWriter];
    //设置声音
    self.videoCamera.audioEncodingTarget = self.movieWriter;
    [self.movieWriter startRecording];
    
}

-(void)endRecord{
    [self.filter removeTarget:self.movieWriter];
    self.videoCamera.audioEncodingTarget = nil;
    [self.movieWriter finishRecording];
}






- (IBAction)nextBtnClick:(UIButton *)sender {
    
    VideoController * video = [[VideoController alloc] init];
    video.videoUrl = self.movieURL;
    [self.navigationController pushViewController:video animated:YES];
    
}

///修改滤镜
- (IBAction)changeFilter:(UIButton *)sender {
    
    switch (sender.tag) {
        case 0:///关闭
            self.filter = [[GPUImageBrightnessFilter alloc] init];
            break;
        case 1:///自然
            self.filter = [[GPUImageBilateralFilter alloc] init];
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



/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
