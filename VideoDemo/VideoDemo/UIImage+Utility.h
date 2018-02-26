//
// Created by peter.shi on 16/5/24.
// Copyright (c) 2016 pinguo. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreMedia/CoreMedia.h>

NS_ASSUME_NONNULL_BEGIN
/**
 * 图像增强功能扩展
 */
@interface UIImage (Utility)

#pragma mark - 对象实例 -

/**
 *  由像素数据生成图像
 *
 *  @param pixels 像素数据
 *  @param width  宽度
 *  @param height 高度
 *
 *  @return 图像实例
 */
+ (nullable UIImage *)imageWithPixels:(unsigned char *)pixels width:(CGFloat)width height:(CGFloat)height;

/**
 *  由采样数据生成图像
 *
 *  @param sampleBuffer 采样数据
 *
 *  @return 图像实例
 */
+ (nullable UIImage *)imageWithSampleBuffer:(CMSampleBufferRef)sampleBuffer;

#pragma mark - 像素 -

/**
 *  获取图像像素数据
 *
 *  @return 像素数据Buffer
 */
- (unsigned char *)pixles;

/**
 *  获取图像灰度像素数据
 *
 *  @return 像素数据Buffer
 */
- (unsigned char *)pixlesGray;

#pragma mark - 缩放 -

/**
 *  根据大小缩放
 *
 *  @param size 大小
 *
 *  @return 图像实例
 */
- (nullable UIImage *)scaleWithSize:(CGSize)size;

/**
 *  根据最大像素缩放
 *
 *  @param maxPixelCount 最大像素数
 *
 *  @return 图像实例
 */
- (nullable UIImage *)scaleWithMaxPixelCount:(NSInteger)maxPixelCount;

/**
 *  缩放(默认屏幕缩放因子)
 *
 *  @param width 宽度
 *
 *  @return 图像实例
 */
- (nullable UIImage *)scaleWithWidth:(CGFloat)width;

#pragma mark - 旋转 -

/**
 *  根据角度旋转
 *
 *  @param angle 角度
 *
 *  @return 图像实例
 */
- (nullable UIImage *)rotateWithAngle:(CGFloat)angle;

#pragma mark - 裁剪 -

/**
 *  根据区域裁剪
 *
 *  @param bounds 区域
 *
 *  @return 图像实例
 */
- (nullable UIImage *)cropWithBounds:(CGRect)bounds;

/**
 *  根据裁减掉的各边长度
 *
 *  @param insets insets
 *
 *  @return 图像实例
 */
- (nullable UIImage *)cropWithInsets:(UIEdgeInsets)insets;

/**
 *  根据区域裁剪
 *
 *  @param rect 区域
 *
 *  @return 图像实例
 */
- (nullable UIImage *)cropWithRect:(CGRect)rect;


/**
 *  根据缩放比例裁剪
 *
 *  @param scale 裁剪比例
 *
 *  @return 图像实例
 */
- (nullable UIImage *)cropWithScale:(CGFloat)scale;

/**
 *  将正方形裁剪成圆形
 *
 *  @return 图像实例
 */
- (nullable UIImage *)cropCycle;

#pragma mark - 遮罩 -
/**
 *  根据遮罩图进行遮罩
 *
 *  @param image 遮罩图
 *
 *  @return 图像实例
 */
- (nullable UIImage *)mask:(UIImage *)image;

#pragma mark - 模糊虚化 -
/**
 *  模糊虚化图片
 *
 *  @param radius 模糊程度
 *
 *  @return 图像实例
 */
- (nullable UIImage *)blurry:(CGFloat)radius;

#pragma mark - 镜像 -
/**
 *  镜像
 *
 *  @param horizontal 是否水平镜像
 *  @param vertical 是否垂直镜像
 *
 *  @return 图像实例
 */
- (nullable UIImage *)mirror:(BOOL)horizontal vertical:(BOOL)vertical;

#pragma mark - 缩略图 -
/**
 *  获取缩略图
 *
 *  @return 图像实例
 */
- (nullable UIImage *)thumbnail;

#pragma mark 方向

/**
 *  将图像旋转到正确的方向
 *
 *  @return 图像实例
 */
- (nullable UIImage *)transformByOrientation;

/**
 *  角度转化成方向值
 *
 *  @param angle 角度
 *
 *  @return 图像实例
 */
- (UIImageOrientation)convertAngleToOrientation:(NSInteger)angle;

#pragma mark - 工具 -

/**
 *  将图片质量压缩到字节数下
 *
 *  @param imageData 图像数据
 *  @param maxBytesCount 最大字节数
 *
 *  @return 图像数据
 */
+ (nullable NSData *)compressWithData:(NSData *)imageData maxBytesCount:(NSUInteger)maxBytesCount;

/**
 *  根据数据获取图片尺寸大小
 *
 *  @param jpgData 图像数据
 *
 *  @return 尺寸大小
 */
+ (CGSize)sizeWithImageData:(NSData *)jpgData;

/**
 *  根据图片链接获取图片尺寸大小
 *
 *  @param url 图片链接
 *
 *  @return 尺寸大小
 */
+ (CGSize)sizeWithImageURL:(NSURL *)url;


/**
 *  获取图片exif信息
 *
 *  @param data 图像数据
 *
 *  @return exif信息
 */
+ (NSDictionary *)exifWithData:(NSData *)data;

@end

NS_ASSUME_NONNULL_END