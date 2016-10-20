//
//  XLVideoRecorder.h
//  VideoDemo
//
//  Created by ZhongXiaoLong on 16/10/19.
//  Copyright © 2016年 zhongxiaolong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 视频录制操作类
 */
@interface XLVideoRecorder : NSObject

//视频预览层
@property (nonatomic, readonly) AVCaptureVideoPreviewLayer *previewLayer;

//开始录制的回调
@property (nonatomic, copy) void (^didStartBlock)();

//录制完成的回调
@property (nonatomic, copy) void (^finishBlock)(NSURL *outputFileURL, NSError *error);

/**
 单例
 */
+ (XLVideoRecorder *)shared;

/**
 开始预览
 */
- (void)startRender;

/**
 停止预览
 */
- (void)stopRender;

/**
 开始录制
 */
- (void)startRecorder;

/**
 是否正在录制
 */
- (BOOL)isRecording;

/**
 停止录制
 */
- (void)stopRecorder;

/**
 录制的视频的输入位置
 */
- (NSString *)outputFilePath;
@end
