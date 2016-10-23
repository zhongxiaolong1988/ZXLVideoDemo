//
//  XLVideoEidt.m
//  VideoDemo
//
//  Created by ZhongXiaoLong on 16/10/20.
//  Copyright © 2016年 zhongxiaolong. All rights reserved.
//

#import "XLVideoEidt.h"
#import <ImageIO/ImageIO.h>
#import <UIKit/UIKit.h>

@interface XLVideoEidt ()
{

}
@property (nonatomic) AVAssetExportSession *mExportSession;
@end

@implementation XLVideoEidt

+ (XLVideoEidt *)shared
{
    static XLVideoEidt *s_videoEdit = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        s_videoEdit = [[XLVideoEidt alloc] init];

    });

    return s_videoEdit;
}

- (float)compressProgress
{
    return self.mExportSession.progress;
}

- (void)compressVideo:(NSURL *)inputUrl outputUrl:(NSURL *)outputUrl complateBlock:(void (^)(NSURL *))complateBlock
{
    AVURLAsset *urlAsset = [[AVURLAsset alloc] initWithURL:inputUrl
                                                   options:nil];

    NSLog(@"开始压缩，压缩前大小 = %lld", [self fileSizeWithUrl:inputUrl]);

    //删除之前的文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:[outputUrl path]
                                             isDirectory:nil])
    {
        [[NSFileManager defaultManager] removeItemAtPath:[outputUrl path]
                                                   error:nil];
    }

    //中质量，压缩成mp4格式
    AVAssetExportSession *exportSession = [[AVAssetExportSession alloc] initWithAsset:urlAsset
                                                                           presetName:AVAssetExportPresetMediumQuality];
    exportSession.outputURL = outputUrl;
    exportSession.outputFileType = AVFileTypeMPEG4;
    [exportSession exportAsynchronouslyWithCompletionHandler:^{

        NSLog(@"压缩完成，压缩后大小 = %lld", [self fileSizeWithUrl:outputUrl]);
        
        if (complateBlock)
        {
            complateBlock(outputUrl);
        }
    }];

    self.mExportSession = exportSession;
}

- (void)cancelCompress
{
    [self.mExportSession cancelExport];
}

- (void)editVideo:(NSURL *)inputUrl
        outputUrl:(NSURL *)outputUrl
    compalteBlock:(void (^)(NSURL *))complateBlock
{
    //1.检查文件等初始化操作
    if ([[NSFileManager defaultManager] fileExistsAtPath:[outputUrl path]])
    {
        [[NSFileManager defaultManager] removeItemAtPath:[outputUrl path]
                                                   error:nil];
    }

    if (![[NSFileManager defaultManager] fileExistsAtPath:[inputUrl path]])
    {
        NSLog(@"输入视频不存在");
        return;
    }


    AVMutableComposition *mainComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *videoTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
    //获取当前视频方向
    NSUInteger degress = [self degressFromVideoFileWithURL:inputUrl];

    videoTrack.preferredTransform = CGAffineTransformRotate(CGAffineTransformIdentity, degress * M_PI / 180.0);

    AVMutableCompositionTrack *audioTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];

    CMTime duration = kCMTimeZero;
    AVAsset *asset = [AVAsset assetWithURL:inputUrl];
    float videoSeconds = asset.duration.value * 1.0f / asset.duration.timescale;

    if (videoSeconds < 10)
    {
        NSLog(@"视频长度小于10秒，无法截取");
        return;
    }
    //2.从视频中随机截取10秒的片段
    //获取起始时间
    float startTime = arc4random() % ((long)videoSeconds - 10);
    NSLog(@"随机起始位置为 = %f", startTime);
    //视频插入位置
    static const float kInsertTime = 10;
    //截取视频长度
    static const float kClipTime = 10;

    NSError *error = nil;

    //将原始视频到起始时间的位置插入合成的视频中
    CMTimeRange startRange = CMTimeRangeMake(CMTimeMakeWithSeconds(0, asset.duration.timescale),
                                             CMTimeMakeWithSeconds(kInsertTime, asset.duration.timescale));
    [videoTrack insertTimeRange:startRange
                        ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject
                         atTime:duration
                          error:&error];
    [audioTrack insertTimeRange:startRange
                        ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject
                         atTime:duration
                          error:nil];

    //将截取的10秒片段循环插入3次
    for (int i = 0; i < 3; i++)
    {
        CMTimeRange clipRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, asset.duration.timescale),
                                                CMTimeMakeWithSeconds(kClipTime, asset.duration.timescale));
        CMTime insertTime = CMTimeMakeWithSeconds(kInsertTime + i * kClipTime, asset.duration.timescale);

        [videoTrack insertTimeRange:clipRange
                            ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject
                             atTime:insertTime
                              error:&error];
        [audioTrack insertTimeRange:clipRange
                            ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject
                             atTime:insertTime
                              error:&error];
    }

    //再将之后的视频插入到截取的视频之后
    CMTimeRange endRange = CMTimeRangeMake(CMTimeMakeWithSeconds(kInsertTime, asset.duration.timescale),
                                           CMTimeMakeWithSeconds(videoSeconds - kInsertTime, asset.duration.timescale));

    CMTime endTime = CMTimeMakeWithSeconds(kInsertTime + 3 * kClipTime, asset.duration.timescale);

    [videoTrack insertTimeRange:endRange
                        ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject
                         atTime:endTime
                          error:&error];
    [audioTrack insertTimeRange:endRange
                        ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject
                         atTime:endTime
                          error:&error];

    //在第10秒的位置插入默认音乐
    AVMutableCompositionTrack *newAudioTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];


    NSString *defaultAudioPath = [[NSBundle mainBundle] pathForResource:@"bg" ofType:@"wav"];
    AVAsset *defaultAudioAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:defaultAudioPath]];

    [newAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, defaultAudioAsset.duration)
                        ofTrack:[defaultAudioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject
                         atTime:CMTimeMakeWithSeconds(kInsertTime, asset.duration.timescale)
                          error:&error];

    //设置插入的音频和原始音频混合
    AVMutableAudioMix *audioMix = [[AVMutableAudioMix alloc] init];
    AVMutableAudioMixInputParameters *audioMixPar = [AVMutableAudioMixInputParameters audioMixInputParametersWithTrack:newAudioTrack];
    [audioMixPar setVolumeRampFromStartVolume:1
                                  toEndVolume:1
                                    timeRange:CMTimeRangeMake(CMTimeMakeWithSeconds(0, asset.duration.timescale), defaultAudioAsset.duration)];
    audioMix.inputParameters = @[audioMixPar];

    if (error != nil)
    {
        NSLog(@"插入默认音频失败 error = %@", error);
        return;
    }

    //保存合成的视频
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mainComposition
                                                                      presetName:AVAssetExportPresetMediumQuality];

    exporter.outputURL = outputUrl;
    exporter.audioMix = audioMix;   //设置音频混合器
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.shouldOptimizeForNetworkUse = YES;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        switch (exporter.status) {
            case AVAssetExportSessionStatusWaiting:
                break;
            case AVAssetExportSessionStatusExporting:
                break;
            case AVAssetExportSessionStatusCompleted:
                NSLog(@"合成视频保存完成");

                if (complateBlock)
                {
                    complateBlock(outputUrl);
                }

                break;
            default:
                NSLog(@"合成视频保存失败 %@",[exporter error]);
                break;
        }

    }];
}

- (void)insertGif:(NSString *)gifPath
         videoUrl:(NSURL *)videoUrl
         atSecond:(float)insertTime
     compateBlock:(void (^)(NSURL *))complateBlock
{
    //这句非常重要！
    unlink([[videoUrl path] UTF8String]);

    CGSize size = CGSizeMake(720, 1280);
    NSError *error = nil;
    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:videoUrl
                                                           fileType:AVFileTypeMPEG4
                                                              error:&error];
    if (error != nil)
    {
        NSLog(@"加载视频失败 error = %@", error);
        return;
    }

    NSAssert(videoWriter, @"videoWriter 初始化失败");
    NSDictionary *videoSettings = [NSDictionary dictionaryWithObjectsAndKeys:
                                   AVVideoCodecH264, AVVideoCodecKey,
                                   [NSNumber numberWithInt:size.width], AVVideoWidthKey,
                                   [NSNumber numberWithInt:size.height], AVVideoHeightKey,
                                   nil];

    AVAssetWriterInput* videoWriterInput = [AVAssetWriterInput assetWriterInputWithMediaType:AVMediaTypeVideo
                                                                              outputSettings:videoSettings];

    NSDictionary *sourcePixelBufferAttributesDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
                                                           [NSNumber numberWithInt:kCVPixelFormatType_32ARGB], kCVPixelBufferPixelFormatTypeKey, nil];


    AVAssetWriterInputPixelBufferAdaptor *adaptor = [AVAssetWriterInputPixelBufferAdaptor
                                                     assetWriterInputPixelBufferAdaptorWithAssetWriterInput:videoWriterInput
                                                     sourcePixelBufferAttributes:sourcePixelBufferAttributesDictionary];
    NSParameterAssert(videoWriterInput);
    NSParameterAssert([videoWriter canAddInput:videoWriterInput]);
    [videoWriter addInput:videoWriterInput];

    //开始写入:
    [videoWriter startWriting];
    [videoWriter startSessionAtSourceTime:kCMTimeZero];

    dispatch_queue_t    dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);
    __block  int        frame = 0;

    //读取gif的每一帧和每一帧的持续时间
    NSData *gifData = [NSData dataWithContentsOfFile:gifPath];
    CGImageSourceRef src = CGImageSourceCreateWithData((CFDataRef)gifData, NULL);
    size_t frameCount = CGImageSourceGetCount(src);

    [videoWriterInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{

        while ([videoWriterInput isReadyForMoreMediaData])
        {
            if(++frame >= frameCount)
            {
                [videoWriterInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{

                    if (complateBlock)
                    {
                        complateBlock(videoUrl);
                    }

                }];
                break;
            }

            CGImageRef cgImage = CGImageSourceCreateImageAtIndex(src, frame, NULL);

            CVPixelBufferRef buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:cgImage size:size];
            if (buffer)
            {
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMake(frame, 20)])
                    NSLog(@"FAIL");
                else
                    NSLog(@"Success:%d", frame);
                CFRelease(buffer);
            }
        }
    }];

}

- (CVPixelBufferRef )pixelBufferFromCGImage:(CGImageRef)image size:(CGSize)size
{
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGImageCompatibilityKey,
                             [NSNumber numberWithBool:YES], kCVPixelBufferCGBitmapContextCompatibilityKey, nil];
    CVPixelBufferRef pxbuffer = NULL;
    CVReturn status = CVPixelBufferCreate(kCFAllocatorDefault, size.width, size.height, kCVPixelFormatType_32ARGB, (__bridge CFDictionaryRef) options, &pxbuffer);
    // CVReturn status = CVPixelBufferPoolCreatePixelBuffer(NULL, adaptor.pixelBufferPool, &pxbuffer);

    NSParameterAssert(status == kCVReturnSuccess && pxbuffer != NULL);

    CVPixelBufferLockBaseAddress(pxbuffer, 0);
    void *pxdata = CVPixelBufferGetBaseAddress(pxbuffer);
    NSParameterAssert(pxdata != NULL);

    CGColorSpaceRef rgbColorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(pxdata, size.width, size.height, 8, 4*size.width, rgbColorSpace, kCGImageAlphaPremultipliedFirst);
    NSParameterAssert(context);

    CGContextDrawImage(context, CGRectMake(0, 0, CGImageGetWidth(image), CGImageGetHeight(image)), image);

    CGColorSpaceRelease(rgbColorSpace);
    CGContextRelease(context);

    CVPixelBufferUnlockBaseAddress(pxbuffer, 0);
    
    return pxbuffer;
}

#pragma mark - 工具方法
- (NSUInteger)degressFromVideoFileWithURL:(NSURL *)url
{
    NSUInteger degress = 0;

    AVAsset *asset = [AVAsset assetWithURL:url];
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;

        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        }else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        }else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        }else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }

    return degress;
}

- (long long)fileSizeWithUrl:(NSURL *)fileUrl
{
    NSString *filePath = [fileUrl path];

    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath
                                             isDirectory:nil])
    {
        NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:filePath
                                                                               error:nil];

        if (attrs != nil)
        {
            return attrs.fileSize;
        }
    }

    return 0;
}

- (NSString *)fileSizeStrWithSize:(long long)fileSize
{
    if (fileSize > 1000 * 1000)
    {
        return [NSString stringWithFormat:@"%.1fM", (float)fileSize / 1000.0 / 1000.0];
    }
    else if (fileSize > 1000)
    {
        return [NSString stringWithFormat:@"%.1fK", (float)fileSize / 1000.0];
    }
    else
    {
        return [NSString stringWithFormat:@"%lldB", fileSize];
    }
}

@end
