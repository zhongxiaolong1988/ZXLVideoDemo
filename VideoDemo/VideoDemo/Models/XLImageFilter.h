//
//  XLImageFilter.h
//  VideoDemo
//
//  Created by ZhongXiaoLong on 2018/1/15.
//  Copyright © 2018年 zhongxiaolong. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface XLImageFilter : NSObject

+ (XLImageFilter *)shared;

/**
 图像转灰度

 @param orgImage 原始图像
 @return 灰度图
 */
- (UIImage *)imageToGray:(UIImage *)orgImage;

/**
 双重曝光效果

 @param firstImage 第一张图
 @param secondImage 第二张图
 @return 效果图
 */
- (UIImage *)doubleImage:(UIImage *)firstImage
             secondImage:(UIImage *)secondImage;


/**
 高斯模糊

 @param orgImage 原图
 @return 效果图
 */
- (UIImage *)gaussImage:(UIImage *)orgImage;

/**
 获取图像轮廓

 @param orgImage 原始图片
 @return 处理后的图片
 */
- (UIImage *)findContoursImage:(UIImage *)orgImage;

@end
