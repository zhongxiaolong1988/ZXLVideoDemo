//
//  XLVideoEidt.m
//  VideoDemo
//
//  Created by ZhongXiaoLong on 16/10/20.
//  Copyright © 2016年 zhongxiaolong. All rights reserved.
//

#import "XLVideoEidt.h"

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

//    if ([[NSFileManager defaultManager] fileExistsAtPath:[self clipPath]])
//    {
//        [[NSFileManager defaultManager] removeItemAtPath:[self clipPath]
//                                                   error:nil];
//    }

    AVMutableComposition *mainComposition = [[AVMutableComposition alloc] init];
    AVMutableCompositionTrack *videoTrack = [mainComposition addMutableTrackWithMediaType:AVMediaTypeVideo
                                                                         preferredTrackID:kCMPersistentTrackID_Invalid];
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
                              error:nil];
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
                          error:nil];


    //保存合成的视频
    AVAssetExportSession *exporter = [[AVAssetExportSession alloc] initWithAsset:mainComposition
                                                                      presetName:AVAssetExportPresetMediumQuality];

    exporter.outputURL = outputUrl;
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

//- (NSString *)clipPath
//{
//    NSString *filePath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,
//                                                              NSUserDomainMask, YES)
//                          objectAtIndex:0];
//    return [filePath stringByAppendingPathComponent:@"clipTmp.mp4"];
//}

#pragma mark - 工具方法
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
