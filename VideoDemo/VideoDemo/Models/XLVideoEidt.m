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
#import <AVFoundation/AVFoundation.h>

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
    //删除之前的文件
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self outputFilePath]
                                             isDirectory:nil])
    {
        [[NSFileManager defaultManager] removeItemAtPath:[self outputFilePath]
                                                   error:nil];
    }

    // 1 - Early exit if there's no video file selected
    AVAsset *videoAsset = [AVAsset assetWithURL:videoUrl];

    // 2 - Create AVMutableComposition object. This object will hold your AVMutableCompositionTrack instances.
    AVMutableComposition *mixComposition = [[AVMutableComposition alloc] init];

    // 3 - Video track
    AVMutableCompositionTrack *videoTrack = [mixComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                        preferredTrackID:kCMPersistentTrackID_Invalid];
    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, videoAsset.duration)
                        ofTrack:[[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0]
                         atTime:kCMTimeZero error:nil];

    // 3.1 - Create AVMutableVideoCompositionInstruction
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, videoAsset.duration);
//    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(5, videoAsset.duration.timescale));

    // 3.2 - Create an AVMutableVideoCompositionLayerInstruction for the video track and fix the orientation.
    AVMutableVideoCompositionLayerInstruction *videolayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    AVAssetTrack *videoAssetTrack = [[videoAsset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];
    UIImageOrientation videoAssetOrientation_  = UIImageOrientationUp;
    BOOL isVideoAssetPortrait_  = NO;
    CGAffineTransform videoTransform = videoAssetTrack.preferredTransform;
    if (videoTransform.a == 0 && videoTransform.b == 1.0 && videoTransform.c == -1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ = UIImageOrientationRight;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 0 && videoTransform.b == -1.0 && videoTransform.c == 1.0 && videoTransform.d == 0) {
        videoAssetOrientation_ =  UIImageOrientationLeft;
        isVideoAssetPortrait_ = YES;
    }
    if (videoTransform.a == 1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == 1.0) {
        videoAssetOrientation_ =  UIImageOrientationUp;
    }
    if (videoTransform.a == -1.0 && videoTransform.b == 0 && videoTransform.c == 0 && videoTransform.d == -1.0) {
        videoAssetOrientation_ = UIImageOrientationDown;
    }
    [videolayerInstruction setTransform:videoAssetTrack.preferredTransform atTime:kCMTimeZero];
    [videolayerInstruction setOpacity:0.0 atTime:videoAsset.duration];

    // 3.3 - Add instructions
    mainInstruction.layerInstructions = [NSArray arrayWithObjects:videolayerInstruction,nil];

    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];

    CGSize naturalSize;
    if(isVideoAssetPortrait_){
        naturalSize = CGSizeMake(videoAssetTrack.naturalSize.height, videoAssetTrack.naturalSize.width);
    } else {
        naturalSize = videoAssetTrack.naturalSize;
    }

    float renderWidth, renderHeight;
    renderWidth = naturalSize.width;
    renderHeight = naturalSize.height;
    mainCompositionInst.renderSize = CGSizeMake(renderWidth, renderHeight);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);

    [self applyVideoEffectsToComposition:mainCompositionInst size:naturalSize gifPath:gifPath];

    // 4 - Get path
    NSURL *url = [NSURL fileURLWithPath:[self outputFilePath]];

    // 5 - Create exporter
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mixComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL=url;
    exporter.outputFileType = AVFileTypeQuickTimeMovie;
    exporter.shouldOptimizeForNetworkUse = YES;
    exporter.videoComposition = mainCompositionInst;
    [exporter exportAsynchronouslyWithCompletionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{

            switch (exporter.status) {
                case AVAssetExportSessionStatusWaiting:
                    break;
                case AVAssetExportSessionStatusExporting:
                    break;
                case AVAssetExportSessionStatusCompleted:
                    NSLog(@"合成视频保存完成");

                    if (complateBlock)
                    {
                        complateBlock(exporter.outputURL);
                    }

                    break;
                default:
                    NSLog(@"合成视频保存失败 %@",[exporter error]);
                    break;
            }
        });
    }];
}

- (void)applyVideoEffectsToComposition:(AVMutableVideoComposition *)composition
                                  size:(CGSize)size
                               gifPath:(NSString *)gifPath
{
    //读取gif的每一帧和每一帧的持续时间
    NSData *gifData = [NSData dataWithContentsOfFile:gifPath];
    CGImageSourceRef src = CGImageSourceCreateWithData((CFDataRef)gifData, NULL);
    size_t frameCount = CGImageSourceGetCount(src);

    CGImageRef cgImage = CGImageSourceCreateImageAtIndex(src, 0, NULL);
    float imageWidth = CGImageGetWidth(cgImage);
    float imageHeight = CGImageGetHeight(cgImage);

    // 1 - set up the overlay
    CALayer *overlayLayer = [CALayer layer];

    overlayLayer.backgroundColor = [UIColor clearColor].CGColor;
    [overlayLayer setContents:(__bridge id)cgImage];
//    overlayLayer.frame = CGRectMake(0, 0, size.width, size.height);
    overlayLayer.frame = CGRectMake(0, 0, imageWidth / 5, imageHeight / 5);
    [overlayLayer setMasksToBounds:YES];

    // 2 - set up the parent layer
    CALayer *parentLayer = [CALayer layer];
    CALayer *videoLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, size.width, size.height);
    videoLayer.frame = CGRectMake(0, 0, size.width, size.height);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];

    // 3 - apply magic
    composition.animationTool = [AVVideoCompositionCoreAnimationTool
                                 videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer inLayer:parentLayer];
    
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

- (NSString *)outputFilePath
{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES)
                          objectAtIndex:0];
    return [filePath stringByAppendingPathComponent:@"finish.mp4"];
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
