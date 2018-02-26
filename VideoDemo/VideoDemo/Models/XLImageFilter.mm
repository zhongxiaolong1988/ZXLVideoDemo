//
//  XLImageFilter.m
//  VideoDemo
//
//  Created by ZhongXiaoLong on 2018/1/15.
//  Copyright © 2018年 zhongxiaolong. All rights reserved.
//

#import "XLImageFilter.h"
#import <opencv2/opencv.hpp>
#import "UIImage+Utility.h"
#import <CoreImage/CoreImage.h>
#import <GPUImage/GPUImage.h>

@implementation XLImageFilter

+ (XLImageFilter *)shared
{
    static XLImageFilter *s_filter = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{

        s_filter = [[XLImageFilter alloc] init];

    });

    return s_filter;
}

- (UIImage *)imageToGray:(UIImage *)orgImage
{
    size_t iWidth = CGImageGetWidth(orgImage.CGImage);
    size_t iHeight = CGImageGetHeight(orgImage.CGImage);

    unsigned char *orgIndex = [self converImageToBit:orgImage];
    unsigned char *pIndex = orgIndex;

    for (int i = 0; i < iHeight; i++)
    {
        for (int j = 0; j < iWidth; j++)
        {
            if (pIndex[j * 4 + 0] > 180)
            {
                continue;
            }

            unsigned char value = (pIndex[j * 4 + 0] + pIndex[j * 4 + 1] + pIndex[j * 4 + 2]) / 3.0f;
            pIndex[j * 4 + 0] = value;
            pIndex[j * 4 + 1] = value;
            pIndex[j * 4 + 2] = value;
        }
        pIndex += (iWidth * 4);
    }

    UIImage *grayImage = [self imageWithPixels:orgIndex
                                         width:iWidth
                                        height:iHeight];

    return grayImage;
}

- (UIImage *)doubleImage:(UIImage *)firstImage secondImage:(UIImage *)secondImage
{
    //这里简单处理默认两张图是一样大的
    size_t iWidth = CGImageGetWidth(firstImage.CGImage);
    size_t iHeight = CGImageGetHeight(firstImage.CGImage);

    unsigned char *firstImagePixel = [self converImageToBit:firstImage];
    unsigned char *secondImagePixel = [self converImageToBit:secondImage];

    unsigned char *pFirstIndex = firstImagePixel;
    unsigned char *pSecondIndex = secondImagePixel;

    float alpha = 0.5;

    for (int i = 0; i < iHeight; i++)
    {
        for (int j = 0; j < iWidth; j++)
        {
            pFirstIndex[j * 4 + 0] = pFirstIndex[j * 4 + 0] * alpha + pSecondIndex[j * 4 + 0] * (1 - alpha);
            pFirstIndex[j * 4 + 1] = pFirstIndex[j * 4 + 1] * alpha + pSecondIndex[j * 4 + 1] * (1 - alpha);
            pFirstIndex[j * 4 + 2] = pFirstIndex[j * 4 + 2] * alpha + pSecondIndex[j * 4 + 2] * (1 - alpha);
        }
        pFirstIndex += (iWidth * 4);
        pSecondIndex += (iWidth * 4);
    }

    UIImage *doubleImage = [self imageWithPixels:firstImagePixel
                                           width:iWidth
                                          height:iHeight];

    return doubleImage;
}

- (UIImage *)gaussImage:(UIImage *)orgImage
{
    CGFloat blur = 10;

    CIContext *context = [CIContext contextWithOptions:nil];
    CIImage *inputImage= [CIImage imageWithCGImage:orgImage.CGImage];
    //设置filter
    CIFilter *filter = [CIFilter filterWithName:@"CIGaussianBlur"];
    [filter setValue:inputImage forKey:kCIInputImageKey]; [filter setValue:@(blur) forKey: @"inputRadius"];
    //模糊图片
    CIImage *result = [filter valueForKey:kCIOutputImageKey];
    CGImageRef outImage = [context createCGImage:result fromRect:[result extent]];
    UIImage *blurImage = [UIImage imageWithCGImage:outImage];
    CGImageRelease(outImage);
    return blurImage;
}

- (unsigned char *)converImageToBit:(UIImage *)orgImage
{
    CGFloat pixWidth, pixHeight;

    pixWidth = CGImageGetWidth(orgImage.CGImage);
    pixHeight = CGImageGetHeight(orgImage.CGImage);

    unsigned char *orgPixel = (unsigned char *)malloc(pixWidth * pixHeight * 4);

    CGImageRef imgRef = [orgImage CGImage];
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * pixWidth;
    NSUInteger bitsPerComponent = 8;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(orgPixel,
                                                 pixWidth,
                                                 pixHeight,
                                                 bitsPerComponent,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGImageByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, pixWidth, pixHeight), imgRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    return orgPixel;
}

- (nullable UIImage *)imageWithPixels:(unsigned char *)pixels width:(CGFloat)width height:(CGFloat)height
{
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    CGContextRef context2 = CGBitmapContextCreate(pixels,
                                                  width,
                                                  height,
                                                  8,
                                                  width * 4,
                                                  space,
                                                  kCGImageAlphaPremultipliedLast | kCGImageByteOrder32Big);
    CGImageRef cgimg = CGBitmapContextCreateImage(context2);
    CGContextRelease(context2);
    CGColorSpaceRelease(space);
    UIImage *imgRet = [[UIImage alloc] initWithCGImage:cgimg];
    CGImageRelease(cgimg);

    return imgRet;
}

- (UIImage *)findContoursImage:(UIImage *)orgImage
{
    //将UIImage转换成cv::Mat
    cv::Mat orgMat = [self matFromUIImage:orgImage];

    //将图像进行灰度处理
    cv::Mat grayMat;
    cv::cvtColor(orgMat, grayMat, CV_RGBA2GRAY);

    //获取图像轮廓
    cv::Mat blurMat;
    cv::blur(grayMat, blurMat, cv::Size(3, 3));
    cv::Mat cannyMat;
    cv::Canny(grayMat, cannyMat, 60, 255);

    //获取轮廓点
    std::vector<std::vector<cv::Point>> contours;
    cv::findContours(cannyMat, contours, CV_RETR_EXTERNAL, CV_CHAIN_APPROX_NONE);

    //将轮廓点绘制到原图
    orgMat.setTo(cv::Scalar(100, 255, 0), cannyMat);

    //将cv::Mat转换成UIImage
    UIImage *retImage = [self imageFromMat:orgMat];

    return retImage;
}

- (cv::Mat)matFromUIImage:(UIImage *)image
{
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);

    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;

    cv::Mat mat = cv::Mat(rows, cols, CV_8UC4);
    CGContextRef context = CGBitmapContextCreate(mat.data,
                                                 cols,
                                                 rows,
                                                 8,
                                                 mat.step[0],
                                                 colorSpace,
                                                 kCGImageAlphaPremultipliedLast |
                                                 kCGBitmapByteOrderDefault);

    CGContextDrawImage(context, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(context);

    return mat;
}

- (UIImage *)imageFromMat:(cv::Mat)mat
{
    NSData *imageData = [[NSData alloc] initWithBytes:mat.data
                                               length:mat.elemSize() * mat.total()];
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)imageData);

    CGImageRef cgImage = CGImageCreate(mat.cols,
                                       mat.rows,
                                       8,
                                       8 * mat.elemSize(),
                                       mat.step[0],
                                       colorSpace,
                                       kCGImageAlphaPremultipliedLast | kCGBitmapByteOrderDefault,
                                       provider,
                                       NULL,
                                       false,
                                       kCGRenderingIntentDefault);

    UIImage *retImage = [UIImage imageWithCGImage:cgImage];
    CGImageRelease(cgImage);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return retImage;
}

- (UIImage *)filterImage:(UIImage *)orgImage
{
//    GPUImageBrightnessFilter *filter = [[GPUImageBrightnessFilter alloc] init];
//    filter.brightness = 0.5;
//    GPUImageGlassSphereFilter *filter = [[GPUImageGlassSphereFilter alloc] init];

    GPUImageSketchFilter *filter = [[GPUImageSketchFilter alloc] init];

    [filter forceProcessingAtSize:orgImage.size];
    GPUImagePicture *pic = [[GPUImagePicture alloc] initWithImage:orgImage];

    [pic addTarget:filter];
    [pic processImage];
    [filter useNextFrameForImageCapture];
    UIImage *retImage = [filter imageFromCurrentFramebuffer];

    return retImage;
}

@end
