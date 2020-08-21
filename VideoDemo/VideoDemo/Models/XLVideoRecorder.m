//
//  XLVideoRecorder.m
//  VideoDemo
//
//  Created by ZhongXiaoLong on 16/10/19.
//  Copyright © 2016年 zhongxiaolong. All rights reserved.
//

#import "XLVideoRecorder.h"
#import <AVFoundation/AVFoundation.h>

@interface XLVideoRecorder () <AVCaptureFileOutputRecordingDelegate>

@property (nonatomic) AVCaptureSession *mSession;
@property (nonatomic) AVCaptureMovieFileOutput *mFileOutput;
@end

@implementation XLVideoRecorder
@synthesize previewLayer = _previewLayer;

+ (XLVideoRecorder *)shared
{
    static XLVideoRecorder *s_videoRecorder = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        s_videoRecorder = [[XLVideoRecorder alloc] init];
    });

    return s_videoRecorder;
}

- (instancetype)init
{
    self = [super init];

    if (self)
    {
        [self initSession];
    }

    return self;
}

/**
 初始化视频相关对象
 */
- (void)initSession
{
    //初始化会话
    self.mSession = [[AVCaptureSession alloc] init];

    //设置分辨率
    if ([self.mSession canSetSessionPreset:AVCaptureSessionPresetHigh])
    {
        [self.mSession setSessionPreset:AVCaptureSessionPresetHigh];
    }

    //添加视频输入设备，默认使用后置摄像头
    AVCaptureDevice *captureDevice = [self captureDeviceWithPosion:AVCaptureDevicePositionBack];

    NSError *error = nil;
    AVCaptureDeviceInput *deviceInput = [[AVCaptureDeviceInput alloc] initWithDevice:captureDevice
                                                                               error:&error];

    if (error != nil)
    {
        NSLog(@"获取视频输入设备失败, error = %@", error);
        return;
    }

    //添加一个音频输入设备
    AVCaptureDevice *audioDevice = [[AVCaptureDevice devicesWithMediaType:AVMediaTypeAudio] firstObject];
    AVCaptureDeviceInput *audioInput = [[AVCaptureDeviceInput alloc] initWithDevice:audioDevice
                                                                              error:&error];

    if (error != nil)
    {
        NSLog(@"获取音频输入设备失败, error = %@", error);
        return;
    }

    //添加一个输出位置
    self.mFileOutput = [[AVCaptureMovieFileOutput alloc] init];

    //设置一直都有音频
    self.mFileOutput.movieFragmentInterval = kCMTimeInvalid;

    //添加输入设备到会话中
    if ([self.mSession canAddInput:deviceInput])
    {
        [self.mSession addInput:deviceInput];
    }

    if ([self.mSession canAddInput:audioInput])
    {
        [self.mSession addInput:audioInput];
    }

    AVCaptureConnection *connection = [self.mFileOutput connectionWithMediaType:AVMediaTypeVideo];

    //开启自动防抖
    if ([connection isVideoStabilizationSupported])
    {
        connection.preferredVideoStabilizationMode = AVCaptureVideoStabilizationModeAuto;
    }

    //添加输出设备到会话中
    if ([self.mSession canAddOutput:self.mFileOutput])
    {
        [self.mSession addOutput:self.mFileOutput];
    }
}

/**
 获取指定位置的摄像头设备

 @param aPosition 设备位置

 @return 位置对象
 */
- (AVCaptureDevice *)captureDeviceWithPosion:(AVCaptureDevicePosition)aPosition
{
    NSArray *cameras= [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];

    for (AVCaptureDevice *device in cameras)
    {
        if (device.position == aPosition)
        {
            return device;
        }
    }

    return nil;
}

#pragma mark - 外部接口
- (AVCaptureVideoPreviewLayer *)previewLayer
{
    if (_previewLayer == nil)
    {
        _previewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.mSession];
        _previewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill; //填充模式
    }

    return _previewLayer;
}

- (void)startRender
{
    if (![self.mSession isRunning])
    {
        [self.mSession startRunning];

        [self.mSession beginConfiguration];
        AVCaptureConnection *connection = [self.mFileOutput connectionWithMediaType:AVMediaTypeVideo];

        [self.mFileOutput setRecordsVideoOrientationAndMirroringChanges:YES
                                           asMetadataTrackForConnection:connection];
        [connection setVideoOrientation:AVCaptureVideoOrientationPortrait];
        [self.mSession commitConfiguration];
    }
}

- (void)stopRender
{
    if ([self.mSession isRunning])
    {
        [self.mSession stopRunning];
    }
}

- (void)startRecorder
{
    if (![self.mFileOutput isRecording])
    {
        if ([[NSFileManager defaultManager] fileExistsAtPath:[self outputFilePath]])
        {
            [[NSFileManager defaultManager] removeItemAtPath:[self outputFilePath]
                                                       error:nil];
        }

        NSURL *fileUrl = [NSURL fileURLWithPath:[self outputFilePath]];
        [self.mFileOutput startRecordingToOutputFileURL:fileUrl
                                      recordingDelegate:self];
    }
}

- (BOOL)isRecording
{
    return [self.mFileOutput isRecording];
}

- (void)stopRecorder
{
    if ([self.mFileOutput isRecording])
    {
        [self.mFileOutput stopRecording];
    }
}

- (NSString *)outputFilePath
{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES)
                          objectAtIndex:0];
    return [filePath stringByAppendingPathComponent:@"output.mov"];
}

#pragma mark - 视频录制回调
-(void)captureOutput:(AVCaptureFileOutput *)captureOutput didStartRecordingToOutputFileAtURL:(NSURL *)fileURL fromConnections:(NSArray *)connections
{
    NSLog(@"视频开始录制");

    if (self.didStartBlock)
    {
        self.didStartBlock();
    }
}

- (void)captureOutput:(AVCaptureFileOutput *)captureOutput didFinishRecordingToOutputFileAtURL:(NSURL *)outputFileURL fromConnections:(NSArray *)connections error:(NSError *)error
{
    if (error == nil)
    {
        NSLog(@"视频录制完成，存放路径为: %@", outputFileURL);
    }
    else
    {
        NSLog(@"视频录制出错, error = %@", error);
    }

    if (self.finishBlock)
    {
        self.finishBlock(outputFileURL, error);
    }
}

@end
