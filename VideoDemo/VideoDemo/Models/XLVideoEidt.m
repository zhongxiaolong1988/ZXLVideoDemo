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

#define F_EQUAL(a,b) ((fabs((a) - (b))) < FLT_EPSILON)

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
      gifVideoUrl:(NSURL *)gifVideoUrl
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


    AVMutableCompositionTrack *audioTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeAudio
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];

    CMTime duration = kCMTimeZero;
    AVAsset *asset = [AVAsset assetWithURL:inputUrl];
    float videoSeconds = asset.duration.value * 1.0f / asset.duration.timescale;

    NSError *error = nil;

    //插入从开始到第N秒的时间
    CMTimeRange startRange = CMTimeRangeMake(CMTimeMakeWithSeconds(0, asset.duration.timescale),
                                             CMTimeMakeWithSeconds(videoSeconds, asset.duration.timescale));
    [videoTrack insertTimeRange:startRange
                        ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject
                         atTime:duration
                          error:&error];
    [audioTrack insertTimeRange:startRange
                        ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject
                         atTime:duration
                          error:&error];
    NSLog(@"video size = %f, %f",videoTrack.naturalSize.width, videoTrack.naturalSize.height);

    //在第0秒的位置插入默认音乐
    AVMutableCompositionTrack *newAudioTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeAudio preferredTrackID:kCMPersistentTrackID_Invalid];


    NSString *defaultAudioPath = [[NSBundle mainBundle] pathForResource:@"bg" ofType:@"wav"];
    AVAsset *defaultAudioAsset = [AVAsset assetWithURL:[NSURL fileURLWithPath:defaultAudioPath]];

    [newAudioTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, defaultAudioAsset.duration)
                        ofTrack:[defaultAudioAsset tracksWithMediaType:AVMediaTypeAudio].firstObject
                         atTime:CMTimeMakeWithSeconds(0, asset.duration.timescale)
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

    CATextLayer *overlayLayer = [CATextLayer layer];
//    overlayLayer.backgroundColor = [UIColor colorWithRed:0.3 green:0 blue:0 alpha:0.3].CGColor;
    CGFloat textWidth = 0.8;
    CGFloat textHeight = 0.2;
    overlayLayer.frame = CGRectMake((videoTrack.naturalSize.height * (1 - textWidth)) / 2,
                                    0,
                                    textWidth * videoTrack.naturalSize.height,
                                    textHeight * videoTrack.naturalSize.width);
    NSLog(@"video width height = %f, %f", videoTrack.naturalSize.width, videoTrack.naturalSize.height);
    CGFloat contentScale = videoTrack.naturalSize.height / [UIScreen mainScreen].bounds.size.width;
    NSLog(@"contentScale = %f", contentScale);
    overlayLayer.contentsScale = contentScale;
    NSAttributedString *testText = [[NSAttributedString alloc] initWithString:@"歌词视频歌词视频歌词视频" attributes:@{NSFontAttributeName:[UIFont boldSystemFontOfSize:24 * contentScale], NSForegroundColorAttributeName:[UIColor orangeColor]}];
    overlayLayer.string = testText;
    overlayLayer.alignmentMode = kCAAlignmentCenter;

    CAKeyframeAnimation *alphaAnimation = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];

    alphaAnimation.values = @[@(0.0),@(1), @(0.0)];
    alphaAnimation.keyTimes = @[@(0), @(0.5), @(1)];
    alphaAnimation.duration = 4.5;
    alphaAnimation.repeatCount = 5;
    alphaAnimation.beginTime = 0.01;
    [overlayLayer addAnimation:alphaAnimation forKey:@"alpha"];

    CALayer *videoLayer = [CALayer layer];
    videoLayer.frame = CGRectMake(0, 0, videoTrack.naturalSize.height, videoTrack.naturalSize.width);

    CALayer *parentLayer = [CALayer layer];
    parentLayer.frame = CGRectMake(0, 0, videoTrack.naturalSize.height, videoTrack.naturalSize.width);
    [parentLayer addSublayer:videoLayer];
    [parentLayer addSublayer:overlayLayer];

    //视频方向问题
    AVMutableVideoCompositionInstruction *mainInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];

    CMTime totalTime = CMTimeMakeWithSeconds((float)asset.duration.value / (float)asset.duration.timescale + 30,
                                             asset.duration.timescale);

    //直接用一段视频
    AVAssetTrack *videoAssetTrack = [[asset tracksWithMediaType:AVMediaTypeVideo] objectAtIndex:0];

    AVMutableVideoCompositionLayerInstruction *firstLayerIns = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
    [firstLayerIns setTransform:videoAssetTrack.preferredTransform
                         atTime:CMTimeMakeWithSeconds(0, mainComposition.duration.timescale)];
    [firstLayerIns setOpacity:0.0 atTime:totalTime];

    mainInstruction.layerInstructions = [NSArray arrayWithObjects:firstLayerIns, nil];
    mainInstruction.timeRange = CMTimeRangeMake(kCMTimeZero,
                                                mainComposition.duration);

    AVMutableVideoComposition *mainCompositionInst = [AVMutableVideoComposition videoComposition];

    mainCompositionInst.renderScale = 1.0;
    mainCompositionInst.renderSize = CGSizeMake(videoTrack.naturalSize.height, videoTrack.naturalSize.width);
    mainCompositionInst.instructions = [NSArray arrayWithObject:mainInstruction];
    mainCompositionInst.frameDuration = CMTimeMake(1, 30);
    mainCompositionInst.animationTool = [AVVideoCompositionCoreAnimationTool videoCompositionCoreAnimationToolWithPostProcessingAsVideoLayer:videoLayer
                                                                                                                                     inLayer:parentLayer];

    //保存合成的视频
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mainComposition
                                                                      presetName:AVAssetExportPresetHighestQuality];
    exporter.outputURL = outputUrl;
    exporter.audioMix = audioMix;   //设置音频混合器
    exporter.outputFileType = AVFileTypeMPEG4;
    exporter.videoComposition = mainCompositionInst;
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

    //    //将截取的10秒片段循环插入3次
    //    for (int i = 0; i < 3; i++)
    //    {
    //        CMTimeRange clipRange = CMTimeRangeMake(CMTimeMakeWithSeconds(startTime, asset.duration.timescale),
    //                                                CMTimeMakeWithSeconds(kClipTime, asset.duration.timescale));
    //        CMTime insertTime = CMTimeMakeWithSeconds(kInsertTime + i * kClipTime, asset.duration.timescale);
    //
    //        [videoTrack insertTimeRange:clipRange
    //                            ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject
    //                             atTime:insertTime
    //                              error:&error];
    //        [audioTrack insertTimeRange:clipRange
    //                            ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject
    //                             atTime:insertTime
    //                              error:&error];
    //    }

        //再将之后的视频插入到截取的视频之后
    //    CMTimeRange endRange = CMTimeRangeMake(CMTimeMakeWithSeconds(kInsertTime, asset.duration.timescale),
    //                                           CMTimeMakeWithSeconds(videoSeconds - kInsertTime, asset.duration.timescale));
    //
    //    CMTime endTime = CMTimeMakeWithSeconds(kInsertTime + 3 * kClipTime, asset.duration.timescale);
    //
    //    [videoTrack insertTimeRange:endRange
    //                        ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject
    //                         atTime:endTime
    //                          error:&error];
    //    [audioTrack insertTimeRange:endRange
    //                        ofTrack:[asset tracksWithMediaType:AVMediaTypeAudio].firstObject
    //                         atTime:endTime
    //                          error:&error];
}

- (void)rotateVideo:(NSURL *)inputUrl angle:(CGFloat)angle compalteBlock:(void (^)(NSURL *))complateBlock
{
    //1.检查文件等初始化操作
    if ([[NSFileManager defaultManager] fileExistsAtPath:[self rotateVideoFilePath]])
    {
        [[NSFileManager defaultManager] removeItemAtPath:[self rotateVideoFilePath]
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
//    NSUInteger degress = [self degressFromVideoFileWithURL:inputUrl];

    videoTrack.preferredTransform = CGAffineTransformRotate(CGAffineTransformIdentity, angle * M_PI / 180.0);


    AVAsset *asset = [AVAsset assetWithURL:inputUrl];

    [videoTrack insertTimeRange:CMTimeRangeMake(kCMTimeZero, asset.duration)
                        ofTrack:[asset tracksWithMediaType:AVMediaTypeVideo].firstObject
                         atTime:kCMTimeZero
                          error:nil];

    //保存合成的视频
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mainComposition
                                                                      presetName:AVAssetExportPresetMediumQuality];

    exporter.outputURL = [NSURL fileURLWithPath:[self rotateVideoFilePath]];
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
                    complateBlock(exporter.outputURL);
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
    NSURL *gifVideoUrl = [NSURL fileURLWithPath:[self gifVideoFilePath]];

    //这句非常重要！
    unlink([[gifVideoUrl path] UTF8String]);

    //读取gif的每一帧和每一帧的持续时间
    NSData *gifData = [NSData dataWithContentsOfFile:gifPath];
    CGImageSourceRef src = CGImageSourceCreateWithData((CFDataRef)gifData, NULL);
    size_t frameCount = CGImageSourceGetCount(src);

    NSDictionary *gifProperty = [NSDictionary dictionaryWithObject:@{@0:(NSString *)kCGImagePropertyGIFLoopCount}
                                                            forKey:(NSString *)kCGImagePropertyGIFDictionary];
    //取每张图片的图片属性,是一个字典
    NSDictionary *dict = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(src, 0, (CFDictionaryRef)gifProperty));
//    float width = [[dict valueForKey:(NSString *)kCGImagePropertyPixelWidth] floatValue];
//    float height = [[dict valueForKey:(NSString *)kCGImagePropertyPixelHeight] floatValue];

    //每帧的时间数组
    NSMutableArray *timeArray = [NSMutableArray new];
    float totalTime = 0;

    for (int i = 0; i < frameCount; i++)
    {
        //添加每一帧时间
        NSDictionary *tmp = [dict valueForKey:(NSString *)kCGImagePropertyGIFDictionary];
        [timeArray addObject:[tmp valueForKey:(NSString *)kCGImagePropertyGIFDelayTime]];

        totalTime += [timeArray[i] floatValue];
    }

    //创建视频帧生成器
    AVURLAsset *asset = [[AVURLAsset alloc] initWithURL:videoUrl options:nil];
    AVAssetImageGenerator *gen = [[AVAssetImageGenerator alloc] initWithAsset:asset];

    NSLog(@"video time = %lld, %d", asset.duration.value, asset.duration.timescale);
    gen.requestedTimeToleranceAfter = kCMTimeZero;
    gen.requestedTimeToleranceBefore = kCMTimeZero;

    UIImage *firstFrame = [self getVideoPreViewImageAtTime:kCMTimeZero
                                                  assetGen:gen];

    //输出视频高宽
    CGSize size = firstFrame.size;
    NSError *error = nil;

    AVAssetWriter *videoWriter = [[AVAssetWriter alloc] initWithURL:gifVideoUrl
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

    dispatch_queue_t dispatchQueue = dispatch_queue_create("mediaInputQueue", NULL);

    __block float curTime = insertTime; //起始位置
    __block float nextGifTime = insertTime + [[timeArray firstObject] floatValue];
    __block int gifFrame = 0;

    [videoWriterInput requestMediaDataWhenReadyOnQueue:dispatchQueue usingBlock:^{

        while ([videoWriterInput isReadyForMoreMediaData])
        {
            if(curTime >= totalTime + insertTime)
            {
                [videoWriterInput markAsFinished];
                [videoWriter finishWritingWithCompletionHandler:^{

                    if (complateBlock)
                    {
                        complateBlock(gifVideoUrl);
                    }

                }];
                break;
            }

            CVPixelBufferRef buffer;

            if (ABS(curTime - nextGifTime) < 0.01)
            {
                NSLog(@"写入合成帧 %d", gifFrame);
                //写入合成帧
                CGImageRef cgImage = CGImageSourceCreateImageAtIndex(src, gifFrame, NULL);

                //用gif帧的图片和视频帧的图像合成一张新的图
                UIImage *frameImage = [self getVideoPreViewImageAtTime:CMTimeMakeWithSeconds(curTime, asset.duration.timescale)
                                                              assetGen:gen];

                UIImage *makedImage = [self createNewImageWithVideoFrame:frameImage
                                                                gifImage:cgImage];

                buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:makedImage.CGImage
                                                                   size:size];

                gifFrame++;
                if (gifFrame >= 0 && gifFrame < timeArray.count)
                {
                    nextGifTime += [timeArray[gifFrame] floatValue];
                }
            }
            else
            {
                //写入原视频帧
                UIImage *frameImage = [self getVideoPreViewImageAtTime:CMTimeMakeWithSeconds(curTime, asset.duration.timescale)
                                                              assetGen:gen];

                buffer = (CVPixelBufferRef)[self pixelBufferFromCGImage:frameImage.CGImage
                                                                   size:size];
            }

            if (buffer)
            {
//                NSLog(@"curTime = %f", curTime);
                if(![adaptor appendPixelBuffer:buffer withPresentationTime:CMTimeMakeWithSeconds(curTime - insertTime,
                                                                                                 asset.duration.timescale)])
                {
                    NSLog(@"FAIL");
                }
                else
                {
//                    NSLog(@"Success:%d", gifFrame);
                }

                CFRelease(buffer);
            }

            curTime += (1.0 / 60);
        }
    }];
}

- (UIImage *)getVideoPreViewImageAtTime:(CMTime)time
                               assetGen:(AVAssetImageGenerator *)gen
{
    gen.appliesPreferredTrackTransform = YES;
    NSError *error = nil;
    CMTime actualTime;
    CGImageRef image = [gen copyCGImageAtTime:time actualTime:&actualTime error:&error];
    UIImage *img = [[UIImage alloc] initWithCGImage:image];
    CGImageRelease(image);

    return img;
}

//通过视频预览帧和gif动画帧合成一张图片
- (UIImage *)createNewImageWithVideoFrame:(UIImage *)frameImage
                                 gifImage:(CGImageRef)gifImage
{
    UIGraphicsBeginImageContext(frameImage.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    //旋转坐标系
    CGContextTranslateCTM(context, 0, frameImage.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);

    //渲染视频帧
    CGContextDrawImage(context,
                       CGRectMake(0, 0, frameImage.size.width, frameImage.size.height),
                       frameImage.CGImage);

    //渲染gif图像帧到视频帧中心，并且看情况缩放
    float gifWidth = CGImageGetWidth(gifImage);
    float gifHeight = CGImageGetHeight(gifImage);
    CGSize gifSize = CGSizeMake(gifWidth, gifHeight);

    if (gifWidth > frameImage.size.width)
    {
        //缩放到宽边和视频帧相同
        gifSize = CGSizeMake(frameImage.size.width,
                             frameImage.size.width * gifHeight / gifWidth);
    }

    CGContextDrawImage(context,
                       CGRectMake((frameImage.size.width - gifSize.width) / 2,
                                  (frameImage.size.height - gifSize.height) / 2,
                                  gifSize.width,
                                  gifSize.height),
                       gifImage);

    UIImage *makedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return makedImage;
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

- (NSString *)gifVideoFilePath
{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES)
                          objectAtIndex:0];
    return [filePath stringByAppendingPathComponent:@"gif.mp4"];
}

- (NSString *)rotateVideoFilePath
{
    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
                                                              NSUserDomainMask, YES)
                          objectAtIndex:0];
    return [filePath stringByAppendingPathComponent:@"rotate.mp4"];
}

#pragma mark - 工具方法
- (float)getGifTotalTimeWithPath:(NSString *)gifPath
{
    //读取gif的每一帧和每一帧的持续时间
    NSData *gifData = [NSData dataWithContentsOfFile:gifPath];
    CGImageSourceRef src = CGImageSourceCreateWithData((CFDataRef)gifData, NULL);
    size_t frameCount = CGImageSourceGetCount(src);

    NSDictionary *gifProperty = [NSDictionary dictionaryWithObject:@{@0:(NSString *)kCGImagePropertyGIFLoopCount}
                                                            forKey:(NSString *)kCGImagePropertyGIFDictionary];
    //取每张图片的图片属性,是一个字典
    NSDictionary *dict = CFBridgingRelease(CGImageSourceCopyPropertiesAtIndex(src, 0, (CFDictionaryRef)gifProperty));

    //每帧的时间数组
    NSMutableArray *timeArray = [NSMutableArray new];
    float totalTime = 0;

    for (int i = 0; i < frameCount; i++)
    {
        //添加每一帧时间
        NSDictionary *tmp = [dict valueForKey:(NSString *)kCGImagePropertyGIFDictionary];
        [timeArray addObject:[tmp valueForKey:(NSString *)kCGImagePropertyGIFDelayTime]];

        totalTime += [timeArray[i] floatValue];
    }

    return totalTime;
}

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
