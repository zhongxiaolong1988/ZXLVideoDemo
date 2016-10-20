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

@interface ViewController ()
{

}
@property (nonatomic) UIButton *mRecorderBtn;
@property (nonatomic) UILabel *mTimeLabel;

@property (nonatomic) NSTimer *mVideoTimer;
@property (nonatomic) NSTimeInterval mVideoTime;
@property (nonatomic) NSDate *mStartDate;
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

        //完成之后保存到系统相册
        if (error == nil)
        {
            [weakSelf saveToSystemAlbum:outputUrl];
        }

        [weakSelf stopTimer];
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

                                    if (error == nil)
                                    {
                                        NSLog(@"保存到系统相册完成");
                                    }
                                    else
                                    {
                                        NSLog(@"保存到系统相册出错 error = %@", error);
                                    }

                                }];
}

@end
