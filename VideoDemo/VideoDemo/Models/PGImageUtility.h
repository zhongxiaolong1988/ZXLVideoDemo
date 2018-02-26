//
//  CImageHelper.h
//  camera360
//
//  Created by PinGuo on 12-9-28.
//  Copyright (c) 2012年 pinguo.inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AssetsLibrary/AssetsLibrary.h>
#import <CoreMedia/CoreMedia.h>
#import <UIKit/UIKit.h>


@interface PGImageUtility : NSObject
#pragma mark-
#pragma mark 像素操作
/*!
 *
 * @function: 获取图片的像素
 *
 * @param: srcImage 图像源
 *
 * @since: v2.9
 */
+ (unsigned char *)ImagePixles:(UIImage *)srcImage;


+ (unsigned char *)ImagePixlesGray:(UIImage *)srcImage;

+ (unsigned char *)ImagePixlesR:(UIImage *)srcImage;

/*!
 *
 * @function: 把像素数据转换为图片对象(UIImage *)
 *
 * @param: srcPixels 表示源数据像素
 * @param: pixelWidth 表示源图像的宽度
 * @param: pixelHeight 表示源图像的高度
 *
 * @since: v2.9
 */
+ (UIImage *)pixelsToImage:(unsigned char *)srcPixels
                pixelWidth:(CGFloat)aWidth
               pixelHeight:(CGFloat)aHeight;


#pragma mark-
#pragma mark 图像操作

/*!
 *
 * @function: zoomImage 图像放大操作
 *
 * @param: sourceImage 表示需要放大的源图像
 * @param: width 表示需要放大的宽度
 * @param: height 表示需要放大的高度
 *
 * @since: v2.9
 */
+ (UIImage *)zoomImage:(UIImage *)sourceImage
                 width:(float)width
                height:(float)height;


/*!
 *
 * @function: getScaleImage 根据图片宽度缩放图像
 *
 * @param: org 表示需要缩放的源图像
 * @param: scaleWidth 缩放需要的宽度
 *
 * @since: v2.9
 */
+ (UIImage *)getScaleImage:(UIImage *)org width:(CGFloat)scaleWidth;

/**
*  另一种跟进图片宽度缩放的图片的方法
*
*  @param org        原图
*  @param scaleWidth 缩放的宽度
*  @param scale      图片的scale
*
*  @return 缩放后的图片
*/
+ (UIImage *)getScaleImage:(UIImage *)org width:(CGFloat)scaleWidth imageScale:(CGFloat)scale;

/*!
 *
 * @function: imageRotatedByDegrees 根据角度进行旋转
 *
 * @param: degrees 表示需要旋转的角度
 * @param: srcImage 表示需要旋转的图像
 * @since: v2.9
 */
+ (UIImage *)imageRotatedByDegrees:(CGFloat)degrees srcImage:(UIImage *)srcImage;


/*!
 *
 * @function: croppedImage 剪裁图像
 *
 * @param: bounds 表示需要剪裁的边框矩形.
 *
 * @since: v2.9
 */
+ (UIImage *)croppedImage:(CGRect)bounds srcImage:(UIImage *)srcImage;

/*!
 * @function  根据最大的像素进行缩放图片
 *
 * @param: srcImage 表示源图像
 * @param: maxImagePixcels 表示最大的像素
 *
 * @result : 返回一张处理过的图片
 */
+ (UIImage *)zoomImage:(UIImage *)srcImage withMaxPixels:(NSInteger)maxImagePixels;

/*!
 *@function: 从系统相册获取制作过特效的图
 */
+ (UIImage *)fetechImageWithAssetRepresentation:(ALAssetRepresentation *)representation;


#pragma mark 矫正图片的方向
+ (UIImage *)fixImageOrientation:(UIImageOrientation)imageOrientation withSouceImage:(UIImage *)srcImage;

+ (UIImage *)fixImageOrientation:(UIImage *)srcImage;

/*
 * 通过旋转角度取得图像旋转值
  */
+ (UIImageOrientation)getImageOrientationFromRotateAngle:(NSInteger)rotateAngle;

+ (UIImage *)mirrorImage:(BOOL)mirrorX andMirrorY:(BOOL)mirrorY withSourceImage:(UIImage *)srcImage;

// 剪裁图像
+ (UIImage *)cutImage:(CGRect)cutRect withSourceImage:(UIImage *)srcImage;

// 剪裁图像. cutRectBL -- 剪裁比例,范围 0~1
+ (UIImage *)cutImageFromBL:(CGRect)cutRectBL withSourceImage:(UIImage *)srcImage;


/**
 *  根据NSData 获取到图片的尺寸
 *  @param jpgData 图片源数据
 *  @return 尺寸
 */
+ (CGSize)acquireImageSizeWithJpegData:(NSData *)jpgData;

+ (CGSize)acquireImageSizeWithURL:(NSURL *)aUrl;

+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer;

/**
 *  制作缩略图
 *
 *  @param image 需要转换的图像
 *
 *  @return UIImage nil if failed
 */
+ (UIImage *)getThumbnailImage:(UIImage *)image;

/**
 *  根据比例剪裁图像
 *  @return 返回处理后的图像
 */
+ (UIImage *)croppedImageWithImage:(UIImage *)image zoomScale:(CGFloat)zoom;


/**
 *  裁剪图片
 *
 *  @param image  被裁减的图片
 *  @param insets 裁减掉的各边长度
 *
 *  @return 裁剪后的图片
 */
+ (UIImage *)croppedImage:(UIImage *)image withInsets:(UIEdgeInsets)insets;

/**
 *  图像遮罩
 *
 *  @param image     原始图
 *  @param maskImage 遮罩图
 *
 *  @return 遮罩后图片
 */
+ (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage;


/**
 *  模糊图片
 *
 *  @param image  被模糊的图片
 *  @param radius 模糊半径
 *
 *  @return 模糊后的图片
 */
+ (UIImage *)blurredImage:(UIImage *)image withRadius:(CGFloat)radius;

/**
 *  将方形图片裁剪成圆形
 *
 *  @param image 方形图片
 *
 *  @return 圆形图片
 */
+ (UIImage *)clipImageToCycle:(UIImage *)image;


/**
 将图片质量压缩到具体尺寸下
 */
+ (NSData *)compressThumbImageData:(NSData *)aImageData belowSize:(NSUInteger)aSize;

/*
** 获取图片的exif信息
*/
+ (NSDictionary *)getEXIFFromNSData:(NSData *)data;

@end
