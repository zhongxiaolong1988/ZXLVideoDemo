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
