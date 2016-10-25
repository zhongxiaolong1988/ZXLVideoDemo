//
//  ViewController.m
//  VideoDemo
//
//  Created by ZhongXiaoLong on 16/10/19.
//  Copyright © 2016年 zhongxiaolong. All rights reserved.
//

#import "ViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "XLVideoRecorder.h"
#import <AssetsLibrary/AssetsLibrary.h>
#import <SVProgressHUD.h>
#import "XLVideoEidt.h"
#import "XLTipsView.h"

typedef enum _XLAlertViewType
{
    XLAlertViewTypeError = 100,     //出错提示
    XLAlertViewTypeCompress,        //开始压缩提示
    XLAlertViewTypeEdit             //后续编辑提示

}XLAlertViewType;

@interface ViewController () <UIAlertViewDelegate>
{

}
@property (nonatomic) UIButton *mRecorderBtn;
@property (nonatomic) UILabel *mTimeLabel;

@property (nonatomic) NSTimer *mVideoTimer;
@property (nonatomic) NSTimeInterval mVideoTime;
@property (nonatomic) NSDate *mStartDate;

@property (nonatomic) NSURL *mOutputUrl;

@property (nonatomic) NSTimer *mCompressTimer;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.

    //初始化视频录制器
    __weak ViewController *weakSelf = self;

    [XLVideoRecorder shared].didStartBlock = ^(){

        //开始录制时开始计时
        [weakSelf startTimer];
    };

    [XLVideoRecorder shared].finishBlock = ^(NSURL *outputUrl, NSError *error){


        if (weakSelf.mVideoTime < 10)
        {
            [weakSelf stopTimer];
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                message:@"录制视频时长小于10秒，请重新录制."
                                                               delegate:self
                                                      cancelButtonTitle:@"好的"
                                                      otherButtonTitles:nil];
            alertView.tag = XLAlertViewTypeError;
            [alertView show];
            return;
        }

        [weakSelf stopTimer];

        weakSelf.mOutputUrl = outputUrl;
        long long fileSize = [[XLVideoEidt shared] fileSizeWithUrl:outputUrl];

        NSString *message = [NSString stringWithFormat:@"视频存放于:%@，文件大小:%@, 点击继续开始压缩", [weakSelf getLastPath:[outputUrl path]], [[XLVideoEidt shared] fileSizeStrWithSize:fileSize]];
        UIAlertView *nextAlertView = [[UIAlertView alloc] initWithTitle:@"录制完成"
                                                                message:message
                                                               delegate:self
                                                      cancelButtonTitle:@"取消"
                                                      otherButtonTitles:@"继续", nil];
        nextAlertView.tag = XLAlertViewTypeCompress;
        [nextAlertView show];
    };

    //初始化界面
    [self initUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];

    [[XLVideoRecorder shared] startRender];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[XLVideoRecorder shared] stopRender];
}

- (void)initUI
{
    self.title = @"视频录制";

    static const CGFloat kBottomBarHeight = 90;
    static const CGFloat kBtnWidth = 80;
    static const CGFloat kBtnHeight = 50;

    UIView *videoView = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                 0,
                                                                 self.view.bounds.size.width,
                                                                 self.view.bounds.size.height - kBottomBarHeight)];

    videoView.backgroundColor = [UIColor grayColor];
    [self.view addSubview:videoView];

    AVCaptureVideoPreviewLayer *previewLayer = [XLVideoRecorder shared].previewLayer;

    previewLayer.frame = videoView.bounds;
    [videoView.layer addSublayer:previewLayer];

    //底部bar
    UIView *bottomBar = [[UIView alloc] initWithFrame:CGRectMake(0,
                                                                 self.view.bounds.size.height - kBottomBarHeight,
                                                                 self.view.bounds.size.width,
                                                                 kBottomBarHeight)];
    bottomBar.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:bottomBar];

    UIButton *recorderBtn = [UIButton buttonWithType:UIButtonTypeSystem];

    [recorderBtn setFrame:CGRectMake((self.view.bounds.size.width - kBtnWidth) / 2,
                                     (bottomBar.bounds.size.height - kBtnHeight) / 2,
                                     kBtnWidth,
                                     kBtnHeight)];
    recorderBtn.titleLabel.font = [UIFont systemFontOfSize:17];
    [recorderBtn setTitle:@"开始录制" forState:UIControlStateNormal];
    [recorderBtn addTarget:self
                    action:@selector(recorderBtnPressed:)
          forControlEvents:UIControlEventTouchUpInside];

    [bottomBar addSubview:recorderBtn];
    self.mRecorderBtn = recorderBtn;

    //时间显示
    UILabel *timeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20,
                                                                   (bottomBar.bounds.size.height - kBtnHeight) /2,
                                                                   kBtnWidth,
                                                                   kBtnHeight)];

    timeLabel.font = [UIFont systemFontOfSize:16];
    timeLabel.textColor = [UIColor redColor];
    [bottomBar addSubview:timeLabel];
    self.mTimeLabel = timeLabel;
    [self.mTimeLabel setText:@"0:00"];
}

- (void)recorderBtnPressed:(UIButton *)aButton
{
    XLVideoRecorder *recorder = [XLVideoRecorder shared];

    if ([recorder isRecording])
    {
        [recorder stopRecorder];
        [aButton setTitle:@"开始录制" forState:UIControlStateNormal];
    }
    else
    {
        [recorder startRecorder];
        [aButton setTitle:@"停止录制" forState:UIControlStateNormal];
    }
}

- (void)startTimer
{
    if (self.mVideoTimer != nil &&
        [self.mVideoTimer isValid])
    {
        [self.mVideoTimer invalidate];
        self.mVideoTimer = nil;
    }

    self.mStartDate = [NSDate date];
    self.mVideoTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                        target:self
                                                      selector:@selector(handleTimer:)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)stopTimer
{
    if (self.mVideoTimer != nil &&
        [self.mVideoTimer isValid])
    {
        [self.mVideoTimer invalidate];
        self.mVideoTimer = nil;
    }

    self.mStartDate = nil;
    self.mVideoTime = 0;
    [self.mTimeLabel setText:@"0:00"];
}

- (void)handleTimer:(NSTimer *)timer
{
    NSDate *curDate = [NSDate date];

    self.mVideoTime = [curDate timeIntervalSinceDate:self.mStartDate];

    dispatch_async(dispatch_get_main_queue(), ^{

        [self.mTimeLabel setText:[self timeStringWithTime:self.mVideoTime]];

    });
}

- (void)startCompressTimer
{
    [self stopCompressTimer];

    self.mCompressTimer = [NSTimer scheduledTimerWithTimeInterval:0.1
                                                           target:self
                                                         selector:@selector(handleCompressTimer:)
                                                         userInfo:nil
                                                          repeats:YES];
}

- (void)stopCompressTimer
{
    if (self.mCompressTimer != nil && [self.mCompressTimer isValid])
    {
        [self.mCompressTimer invalidate];
        self.mCompressTimer = nil;
    }
}

- (void)handleCompressTimer:(NSTimer *)timer
{
    float progress = [XLVideoEidt shared].compressProgress;

    [XLTipsView setText:[NSString stringWithFormat:@"正在压缩:%.0f%%", progress * 100]];
}

- (NSString *)timeStringWithTime:(NSTimeInterval)time;
{
    long totalTime = (long)time;

//    NSLog(@"totalTime = %ld", totalTime);
    return [NSString stringWithFormat:@"%ld:%ld%ld", totalTime / 60, (totalTime % 60) / 10, (totalTime % 60) % 10];
}

- (void)saveToSystemAlbum:(NSURL *)fileUrl
{
    if (fileUrl == nil)
    {
        return;
    }

    ALAssetsLibrary *library = [[ALAssetsLibrary alloc] init];

    [library writeVideoAtPathToSavedPhotosAlbum:fileUrl
                                completionBlock:^(NSURL *assetURL, NSError *error) {

                                    dispatch_async(dispatch_get_main_queue(), ^{

                                        [SVProgressHUD dismiss];

                                        if (error == nil)
                                        {
                                            NSLog(@"保存到系统相册完成");
//                                            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
//                                                                                                message:@"保存到系统相册完成"
//                                                                                               delegate:nil
//                                                                                      cancelButtonTitle:@"好的" otherButtonTitles:nil];
//
//                                            [alertView show];
                                        }
                                        else
                                        {
                                            NSLog(@"保存到系统相册出错 error = %@", error);
                                        }

                                    });

                                }];
}

- (NSString *)tmpVideoPath
{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES)
                          objectAtIndex:0];
    return [filePath stringByAppendingPathComponent:@"tmp.mp4"];
}

- (NSString *)mergeVideoPath
{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES)
                          objectAtIndex:0];
    return [filePath stringByAppendingPathComponent:@"merge.mp4"];
}

#pragma mark - UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    __weak ViewController *weakSelf = self;

    //点击确定
    if (buttonIndex == 1)
    {
        switch (alertView.tag)
        {
            case XLAlertViewTypeCompress:
            {
                //开始压缩
                NSURL *tmpUrl = [NSURL fileURLWithPath:[self tmpVideoPath]];

                //完成之后开始压缩视频
                [XLTipsView showInView:self.view
                           cancelBlock:^{

                               [XLTipsView dismiss];
                               [weakSelf stopCompressTimer];
                               [[XLVideoEidt shared] cancelCompress];

                               UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:nil
                                                                                   message:@"压缩已取消"
                                                                                  delegate:self
                                                                         cancelButtonTitle:@"好的"
                                                                         otherButtonTitles:nil];

                               [alertView show];
                           }];

                [XLTipsView setText:@"正在压缩..."];
                //开始进度计时
                [self startCompressTimer];

                [[XLVideoEidt shared] compressVideo:self.mOutputUrl
                                          outputUrl:tmpUrl
                                      complateBlock:^(NSURL *url) {

                                          //压缩完成或者取消
                                          [XLTipsView dismiss];
                                          //停止进度
                                          [weakSelf stopCompressTimer];


                                          if ([[NSFileManager defaultManager] fileExistsAtPath:[url path]])
                                          {
                                              dispatch_async(dispatch_get_main_queue(), ^{

                                                  long long fileSize = [[XLVideoEidt shared] fileSizeWithUrl:url];
                                                  NSString *message = [NSString stringWithFormat:@"文件存放于:%@, 文件大小为:%@，点击继续进行编辑处理",[weakSelf getLastPath:[url path]], [[XLVideoEidt shared] fileSizeStrWithSize:fileSize]];

                                                  UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"压缩完成"
                                                                                                      message:message
                                                                                                     delegate:weakSelf
                                                                                            cancelButtonTitle:@"取消"
                                                                                            otherButtonTitles:@"继续", nil];
                                                  alertView.tag = XLAlertViewTypeEdit;
                                                  [alertView show];

                                              });
                                          }
                                      }];

            }
                break;
            case XLAlertViewTypeEdit:
            {
                [SVProgressHUD showWithStatus:@"正在插入gif图片..."];

                NSURL *tmpUrl = [NSURL fileURLWithPath:[self tmpVideoPath]];

                //先插入gif图片
                NSString *gifPath = [[NSBundle mainBundle] pathForResource:@"bird" ofType:@"gif"];

                [[XLVideoEidt shared] insertGif:gifPath
                                       videoUrl:tmpUrl
                                       atSecond:3
                                   compateBlock:^(NSURL *gifVideoUrl) {

                                       dispatch_async(dispatch_get_main_queue(), ^{

                                           //再处理视频剪切合成和混入音频
                                           NSURL *mergeUrl = [NSURL fileURLWithPath:[self mergeVideoPath]];

                                           [SVProgressHUD setStatus:@"正在处理视频和音乐..."];
                                           [[XLVideoEidt shared] editVideo:tmpUrl
                                                               gifVideoUrl:gifVideoUrl
                                                                 outputUrl:mergeUrl
                                                             compalteBlock:^(NSURL *finishUrl) {

                                                                 dispatch_async(dispatch_get_main_queue(), ^{

                                                                     [SVProgressHUD setStatus:@"正在保存到系统相册..."];
                                                                     //保存到系统相册
                                                                     [weakSelf saveToSystemAlbum:finishUrl];
                                                                 });
                                                             }];

                                       });

                                   }];


            }
                break;
            default:
                break;
        }
    }
}

- (NSString *)getLastPath:(NSString *)fullPath
{
    //取最后面的两个路径，以免显示过长
    NSString *name = [fullPath lastPathComponent];
    fullPath = [fullPath stringByDeletingLastPathComponent];
    NSString *diretory = [fullPath lastPathComponent];

    return [NSString stringWithFormat:@"/%@/%@", diretory, name];
}

@end
