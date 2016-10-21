//
//  XLVideoEidt.h
//  VideoDemo
//
//  Created by ZhongXiaoLong on 16/10/20.
//  Copyright © 2016年 zhongxiaolong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>

/**
 一些简单的视频处理逻辑
 */
@interface XLVideoEidt : NSObject
{

}

@property (nonatomic, readonly) float compressProgress;

/**
 单例
 */
+ (XLVideoEidt *)shared;

/**
 压缩视频

 @param inputUrl  输入文件url
 @param outputUrl 输出文件url
 @param complateBlock   压缩完成的回调
 */
- (void)compressVideo:(NSURL *)inputUrl
            outputUrl:(NSURL *)outputUrl
        complateBlock:(void(^)(NSURL *))complateBlock;

/**
 取消压缩
 */
- (void)cancelCompress;

/**
 根据需求对视频进行一些编辑操作

 @param inputUrl      输入的文件url
 @param outputUrl     编辑后的输出文件url
 @param complateBlock 编辑完成的回调
 */
- (void)editVideo:(NSURL *)inputUrl
        outputUrl:(NSURL *)outputUrl
    compalteBlock:(void(^)(NSURL *))complateBlock;


#pragma mark - 工具方法
/**
 获取文件大小

 @param fileUrl 文件url

 @return 文件大小
 */
- (long long)fileSizeWithUrl:(NSURL *)fileUrl;

/**
 文件大小显示字符串

 @param fileSize 文件大小

 @return 文件大小显示字符串
 */
- (NSString *)fileSizeStrWithSize:(long long)fileSize;
@end
