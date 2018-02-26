//
//  CImageHelper.m
//  camera360
//
//  Created by PinGuo on 12-9-28.
//  Copyright (c) 2012年 pinguo.inc. All rights reserved.
//

#import "PGImageUtility.h"
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>

CGFloat DegreesToRadians1(CGFloat degrees);

CGFloat RadiansToDegrees1(CGFloat radians);


CGFloat DegreesToRadians1(CGFloat degrees) {return degrees * M_PI / 180;}


CGFloat RadiansToDegrees1(CGFloat radians) {return radians * 180 / M_PI;}


@implementation PGImageUtility

/*!
 * @function: 获取图片的像素
 *
 * @param: srcImage 图像源
 *
 * @since: v2.9
 */
+ (unsigned char *)ImagePixles:(UIImage *)srcImage
{
    CGFloat pixWidth, pixHeight;

    pixWidth = CGImageGetWidth(srcImage.CGImage);
    pixHeight = CGImageGetHeight(srcImage.CGImage);

    unsigned char *orgPixel = malloc(pixWidth * pixHeight * 4);

    CGImageRef imgRef = [srcImage CGImage];
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * pixWidth;
    NSUInteger bitsPerComponent = 8;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // REV @sp 最后一个参数可能有问题
    CGContextRef context = CGBitmapContextCreate(orgPixel, pixWidth, pixHeight,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, pixWidth, pixHeight), imgRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    return orgPixel;
}


+ (unsigned char *)ImagePixlesGray:(UIImage *)srcImage
{
    CGFloat pixWidth, pixHeight;

    pixWidth = CGImageGetWidth(srcImage.CGImage);
    pixHeight = CGImageGetHeight(srcImage.CGImage);

    unsigned char *orgPixel = malloc(pixWidth * pixHeight * 4);

    CGImageRef imgRef = [srcImage CGImage];
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * pixWidth;
    NSUInteger bitsPerComponent = 8;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // REV @hc 最后一个参数可能有问题
    CGContextRef context = CGBitmapContextCreate(orgPixel, pixWidth, pixHeight,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, pixWidth, pixHeight), imgRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    unsigned char *pIndex = orgPixel;
    int iWidth = pixWidth;
    int iHeight = pixHeight;
    // REV @hc 可以考虑用dispatch_apply并发来做
    for (int i = 0; i < iHeight; ++i)
    {
        for (int j = 0; j < iWidth; ++j)
        {
            unsigned char value = (pIndex[j * 4 + 0] + pIndex[j * 4 + 1] + pIndex[j * 4 + 2]) / 3.0f;
            pIndex[j * 4 + 0] = value;
            pIndex[j * 4 + 1] = value;
            pIndex[j * 4 + 2] = value;
        }
        pIndex += (iWidth * 4);
    }

    return orgPixel;
}


+ (unsigned char *)ImagePixlesR:(UIImage *)srcImage
{
    CGFloat pixWidth, pixHeight;

    pixWidth = CGImageGetWidth(srcImage.CGImage);
    pixHeight = CGImageGetHeight(srcImage.CGImage);

    unsigned char *orgPixel = malloc(pixWidth * pixHeight * 4);

    CGImageRef imgRef = [srcImage CGImage];
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * pixWidth;
    NSUInteger bitsPerComponent = 8;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // REV @sp 最后一个参数可能有问题
    CGContextRef context = CGBitmapContextCreate(orgPixel, pixWidth, pixHeight,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, pixWidth, pixHeight), imgRef);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    unsigned char *rPixel = malloc(pixWidth * pixHeight);

    unsigned char *pIndex = orgPixel;
    int iWidth = pixWidth;
    int iHeight = pixHeight;
    int white = 0;
    int black = 0;

    for (int i = 0; i < iHeight; ++i)
    {
        for (int j = 0; j < iWidth; ++j)
        {
            int p = i * iWidth * 4 + j * 4;
            int q = i * iWidth + j;

            rPixel[q] = pIndex[p];

            //            PGLogDebug(@"r = %d, g = %d, b = %d", pIndex[p], pIndex[p + 1], pIndex[p + 2]);

            if (rPixel[q] < 10)
            {
                rPixel[q] = 0;
                black++;
            }
            else if (rPixel[q] > 245)
            {
                rPixel[q] = 255;
                white++;
            }
            else
            {
                rPixel[q] = 100;
            }
        }
    }

    //    PGLogDebug(@"white = %d", white);
    //    PGLogDebug(@"black = %d", black);

    free(orgPixel);

    return rPixel;
}


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
               pixelHeight:(CGFloat)aHeight
{
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    // REV @sp 最后一个参数可能有问题
    CGContextRef context2 = CGBitmapContextCreate(srcPixels, aWidth, aHeight, 8, aWidth * 4,
                                                  space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGImageRef cgimg = CGBitmapContextCreateImage(context2);
    CGContextRelease(context2);
    CGColorSpaceRelease(space);
    UIImage *imgRet = [[UIImage alloc] initWithCGImage:cgimg];
    CGImageRelease(cgimg);

    return imgRet;
}


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
                height:(float)height
{
    CGSize newSize = CGSizeMake(width, height);
    return [PGImageUtility resizedImage:sourceImage newSize:newSize interpolationQuality:kCGInterpolationHigh];
}


/*!
 *
 * @function: getScaleImage 根据图片宽度缩放图像
 *
 * @param: org 表示需要缩放的源图像
 * @param: scaleWidth 缩放需要的宽度
 *
 * @since: v2.9
 */
+ (UIImage *)getScaleImage:(UIImage *)org width:(CGFloat)scaleWidth
{
    UIImage *shareImg = org;
    //缩放图片
    int scale = [[UIScreen mainScreen] scale];
    CGFloat width, height;
    CGFloat tWidth = shareImg.size.width;
    CGFloat tHeight = shareImg.size.height;
    CGFloat rate = tWidth / tHeight;
    if (shareImg.size.width < shareImg.size.height)
    {
        width = rate * scaleWidth * scale;
        height = scaleWidth * scale;
    }
    else
    {
        width = scaleWidth * scale;
        height = scaleWidth / rate * scale;
    }
    UIImage *newImage = [self zoomImage:shareImg width:width height:height];
    return newImage;
}

+ (UIImage *)getScaleImage:(UIImage *)org width:(CGFloat)scaleWidth imageScale:(CGFloat)scale
{
    UIImage *originalImage = org;

    CGFloat width, height;
    CGFloat tWidth = originalImage.size.width;
    CGFloat tHeight = originalImage.size.height;
    CGFloat rate = tWidth / tHeight;

    if (originalImage.size.width < originalImage.size.height)
    {
        width = rate * scaleWidth;
        height = scaleWidth;
    }
    else
    {
        width = scaleWidth;
        height = scaleWidth / rate;
    }

    BOOL drawTransposed;

    switch (originalImage.imageOrientation)
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;

        default:
            drawTransposed = NO;
    }

    CGSize newSize = CGSizeMake(width, height);

    CGRect transposedRect;
    if (drawTransposed)
    {
        transposedRect = CGRectMake(0, 0, newSize.height, newSize.width);
    }
    else
    {
        transposedRect = CGRectMake(0, 0, newSize.width, newSize.height);
    }

    UIGraphicsBeginImageContextWithOptions(newSize, NO, scale);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextConcatCTM(context, CGAffineTransformIdentity);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    CGContextSetShouldAntialias(context, NO);

    [originalImage drawInRect:transposedRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
}


/*!
 *
 * @function: imageRotatedByDegrees 根据角度进行旋转
 *
 * @param: degrees 表示需要旋转的角度
 * @param: srcImage 表示需要旋转的图像
 * @since: v2.9
 */
+ (UIImage *)imageRotatedByDegrees:(CGFloat)degrees srcImage:(UIImage *)srcImage
{
    @autoreleasepool
    {
        // calculate the size of the rotated view's containing box for our drawing space
        // REV @ppg 这里可能被异步调用,然后崩溃, 非线程安全
        UIView *rotatedViewBox = [[UIView alloc]
                                  initWithFrame:CGRectMake(0, 0, srcImage.size.width, srcImage.size.height)];
        CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians1(degrees));
        rotatedViewBox.transform = t;
        CGSize rotatedSize = rotatedViewBox.frame.size;

        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize);
        CGContextRef bitmap = UIGraphicsGetCurrentContext();

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);

        //   // Rotate the image context
        CGContextRotateCTM(bitmap, DegreesToRadians1(degrees));

        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, 1.0, -1.0);
        CGContextDrawImage(bitmap,
                           CGRectMake(-srcImage.size.width / 2,
                                      -srcImage.size.height / 2,
                                      srcImage.size.width,
                                      srcImage.size.height),
                           [srcImage CGImage]);

        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
}


/*!
 *
 * @function: croppedImage 剪裁图像
 *
 * @param: bounds 表示需要剪裁的边框矩形.
 *
 * @since: v2.9
 */
+ (UIImage *)croppedImage:(CGRect)bounds srcImage:(UIImage *)srcImage
{
    CGImageRef imageRef = CGImageCreateWithImageInRect([srcImage CGImage], bounds);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
}

+ (UIImage *)croppedImage:(UIImage *)image withInsets:(UIEdgeInsets)insets
{
    CGRect rect = CGRectMake(insets.left,
                             insets.top,
                             image.size.width - insets.left - insets.right,
                             image.size.height - insets.top - insets.bottom);
    return [self croppedImage:rect srcImage:image];
}


/*!
 * @function  根据最大的像素进行缩放图片
 *
 * @param: srcImage 表示源图像
 * @param: maxImagePixcels 表示最大的像素
 *
 * @result : 返回一张处理过的图片
 */
+ (UIImage *)zoomImage:(UIImage *)srcImage withMaxPixels:(NSInteger)maxImagePixels
{
    if (srcImage.size.width * srcImage.size.height <= maxImagePixels)
    {
        return srcImage;
    }

    CGFloat width = sqrt((srcImage.size.width / srcImage.size.height) * maxImagePixels);
    CGFloat height = sqrt((srcImage.size.height / srcImage.size.width) * maxImagePixels);
    CGSize size = CGSizeMake(width, height);
    UIImage *img = [self zoomImage:srcImage width:size.width height:size.height];
    return img;
}


/*!
 *@function: 从系统相册获取制作过特效的图
 */
+ (UIImage *)fetechImageWithAssetRepresentation:(ALAssetRepresentation *)representation
{
    UIImage *resultImage = nil;

    if (![[representation metadata] valueForKey:@"AdjustmentXMP"])
    {
        resultImage = [UIImage imageWithCGImage:representation.fullResolutionImage];
        return resultImage;
    }

    NSString *xmpString = representation.metadata[@"AdjustmentXMP"];
    if (xmpString == nil)
    {
        resultImage = [UIImage imageWithCGImage:representation.fullResolutionImage];
        return resultImage;
    }


    if ([CIFilter respondsToSelector:@selector(filterArrayFromSerializedXMP:inputImageExtent:error:)])
    {
        NSData *xmpData = [xmpString dataUsingEncoding:NSUTF8StringEncoding];
        CIImage *image = [CIImage imageWithCGImage:[representation fullResolutionImage]];

        NSError *error = nil;
        NSArray *filterArray = [CIFilter filterArrayFromSerializedXMP:xmpData
                                                     inputImageExtent:image.extent
                                                                error:&error];
        if (error)
        {
            resultImage = [UIImage imageWithCGImage:representation.fullResolutionImage];
            return resultImage;
        }

        CIContext *context = [CIContext contextWithOptions:nil];

        for (CIFilter *filter in filterArray)
        {
            [filter setValue:image forKey:kCIInputImageKey];
            image = [filter outputImage];
        }

        CGImageRef img = [context createCGImage:image fromRect:[image extent]];
        resultImage = [UIImage imageWithCGImage:img
                                          scale:1.0
                                    orientation:(UIImageOrientation)representation.orientation];
        CGImageRelease(img);
        return resultImage;
    }
    else
    {
        return nil;
    }
}




+ (UIImage *)resizedImage:(UIImage *)originalImage
                  newSize:(CGSize)newSize
     interpolationQuality:(CGInterpolationQuality)quality
{
    BOOL drawTransposed;

    switch (originalImage.imageOrientation)
    {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            drawTransposed = YES;
            break;

        default:
            drawTransposed = NO;
    }

    return [PGImageUtility resizedImage:originalImage
                                newSize:newSize
                              transform:[PGImageUtility transformForOrientation:originalImage
                                                                        newSize:newSize]
                         drawTransposed:drawTransposed
                   interpolationQuality:quality];
}


+ (UIImage *)resizedImage:(UIImage *)originalImage
                  newSize:(CGSize)newSize
                transform:(CGAffineTransform)transform
           drawTransposed:(BOOL)transpose
     interpolationQuality:(CGInterpolationQuality)quality
{
#if TARGET_IPHONE_SIMULATOR
    // 模拟器中CGBitmapContextCreate()返回nil，使用替代方法
    CGRect transposedRect;
    if (transpose)
    {
        transposedRect = CGRectMake(0, 0, newSize.height, newSize.width);
    }
    else
    {
        transposedRect = CGRectMake(0, 0, newSize.width, newSize.height);
    }

    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextConcatCTM(context, transform);
    CGContextSetInterpolationQuality(context, quality);
    CGContextSetShouldAntialias(context, NO);

    [originalImage drawInRect:transposedRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
#else
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, newSize.width, newSize.height));
    CGRect transposedRect;
    if (transpose)
    {
        transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    }
    else
    {
        transposedRect = CGRectMake(0, 0, newRect.size.width, newRect.size.height);
    }
    CGImageRef imageRef = originalImage.CGImage;

    // Build a context that's the same dimensions as the new size
    CGContextRef bitmap = CGBitmapContextCreate(NULL,
                                                newRect.size.width,
                                                newRect.size.height,
                                                CGImageGetBitsPerComponent(imageRef),
                                                0,
                                                CGImageGetColorSpace(imageRef),
                                                CGImageGetBitmapInfo(imageRef));

    // Rotate and/or flip the image if required by its orientation
    CGContextConcatCTM(bitmap, transform);

    // Set the quality level to use when rescaling
    CGContextSetInterpolationQuality(bitmap, quality);

    CGContextSetAllowsAntialiasing(bitmap, FALSE);
    CGContextSetShouldAntialias(bitmap, NO);
    //CGContextSetFlatness(bitmap, 0);

    // Draw into the context; this scales the image
    //CGContextDrawTiledImage(bitmap, transposedRect, imageRef);
    CGContextDrawImage(bitmap, transposedRect, imageRef);

    // Get the resized image from the context and a UIImage
    CGImageRef newImageRef = CGBitmapContextCreateImage(bitmap);
    UIImage *newImage = [UIImage imageWithCGImage:newImageRef];

    // Clean up
    // REV @sp bitmap出现NULL
    if (bitmap == NULL)
    {
        // temp log
        //        PGAssert(originalImage != nil, @"Error");
        //        PGAssert(imageRef != NULL, @"Error");
        //        PGAssert(newImage != nil, @"Error");
    }
    CGContextRelease(bitmap);
    CGImageRelease(newImageRef);

    return newImage;
#endif
}


// Returns an affine transform that takes into account the image orientation when drawing a scaled image
+ (CGAffineTransform)transformForOrientation:(UIImage *)originalImage
                                     newSize:(CGSize)newSize
{
    CGAffineTransform transform = CGAffineTransformIdentity;

    int iOrien = originalImage.imageOrientation;
    switch (iOrien)
    {
            // REV @sp default and UIImageOrientationUpMirrored not handle
        case UIImageOrientationUp:
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationDown:
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI);
            break;
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, newSize.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, newSize.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
    }

    switch (iOrien)
    {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, newSize.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, newSize.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            // REV @sp other orientation not handle
    }

    return transform;
}


+ (UIImage *)fixImageOrientation:(UIImageOrientation)imageOrientation withSouceImage:(UIImage *)srcImage
{
    CGImageRef imgRef = srcImage.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1;
    CGFloat boundHeight;
    UIImageOrientation orient = imageOrientation;
    switch (orient)
    {
        case UIImageOrientationUp: //EXIF = 1
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationUpMirrored: //EXIF = 2
            transform = CGAffineTransformMakeTranslation(width, 0.0);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            break;
        case UIImageOrientationDown: //EXIF = 3
            transform = CGAffineTransformMakeTranslation(width, height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
        case UIImageOrientationDownMirrored: //EXIF = 4
            transform = CGAffineTransformMakeTranslation(0.0, height);
            transform = CGAffineTransformScale(transform, 1.0, -1.0);
            break;
        case UIImageOrientationLeftMirrored: //EXIF = 5
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, width);
            transform = CGAffineTransformScale(transform, -1.0, 1.0);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationLeft: //EXIF = 6
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(0.0, width);
            transform = CGAffineTransformRotate(transform, 3.0 * M_PI / 2.0);
            break;
        case UIImageOrientationRightMirrored: //EXIF = 7
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeScale(-1.0, 1.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        case UIImageOrientationRight: //EXIF = 8
            boundHeight = bounds.size.height;
            bounds.size.height = bounds.size.width;
            bounds.size.width = boundHeight;
            transform = CGAffineTransformMakeTranslation(height, 0.0);
            transform = CGAffineTransformRotate(transform, M_PI / 2.0);
            break;
        default:
            //            PGAssert(NO, @"@Invalid image orientation");
            break;
    }
    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    if (orient == UIImageOrientationRight || orient == UIImageOrientationLeft)
    {
        CGContextScaleCTM(context, -scaleRatio, scaleRatio);
        CGContextTranslateCTM(context, -height, 0);
    }
    else
    {
        CGContextScaleCTM(context, scaleRatio, -scaleRatio);
        CGContextTranslateCTM(context, 0, -height);
    }
    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return imageCopy;
}


+ (UIImage *)fixImageOrientation:(UIImage *)srcImage
{
    return [self fixImageOrientation:srcImage.imageOrientation withSouceImage:srcImage];
}


// 通过旋转角度取得图像旋转值
+ (UIImageOrientation)getImageOrientationFromRotateAngle:(NSInteger)rotateAngle
{
    UIImageOrientation orient = UIImageOrientationUp;
    switch (rotateAngle)
    {
        case 0:
            orient = UIImageOrientationUp;           // default orientation
            break;
        case 180:
            orient = UIImageOrientationDown;          // 180 deg rotation
            break;
        case 270:
            orient = UIImageOrientationLeft;         // 90 deg CCW
            break;
        case 90:
            orient = UIImageOrientationRight;         // 90 deg CW
            break;
        default:
            //            PGAssert(NO, @"Error");
            orient = UIImageOrientationUp;
    }
    return orient;
}


// 图像镜像
+ (UIImage *)mirrorImage:(BOOL)mirrorX andMirrorY:(BOOL)mirrorY withSourceImage:(UIImage *)srcImage
{
    //如果方向值相对于90度旋转，相对于x轴镜像应该是相对于y轴，反之亦然

    if (([srcImage imageOrientation] == UIImageOrientationLeft)
        || ([srcImage imageOrientation] == UIImageOrientationRight))
    {
        BOOL tmpMirror = mirrorX;

        mirrorX = mirrorY;
        mirrorY = tmpMirror;
    }

    CGImageRef imgRef = srcImage.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1;

    transform = CGAffineTransformIdentity;
    if (mirrorX && mirrorY)
    {
        transform = CGAffineTransformMakeTranslation(width, height);
        transform = CGAffineTransformScale(transform, -1.0, -1.0);
    }
    else if (mirrorX)
    {
        transform = CGAffineTransformMakeTranslation(width, 0.0);
        transform = CGAffineTransformScale(transform, -1.0, 1.0);
    }
    else if (mirrorY)
    {
        transform = CGAffineTransformMakeTranslation(0.0, height);
        transform = CGAffineTransformScale(transform, 1.0, -1.0);
    }

    UIGraphicsBeginImageContext(bounds.size);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextScaleCTM(context, scaleRatio, -scaleRatio);
    CGContextTranslateCTM(context, 0, -height);

    CGContextConcatCTM(context, transform);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, width, height), imgRef);
    UIImage *imageCopy = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    imageCopy = [UIImage imageWithCGImage:[imageCopy CGImage]
                                    scale:1.0
                              orientation:[srcImage imageOrientation]];
    return imageCopy;
}


// 剪裁图像
+ (UIImage *)cutImage:(CGRect)cutRect withSourceImage:(UIImage *)srcImage
{
    UIImage *retImage = NULL;
    int x1, y1, newW, newH;
    x1 = cutRect.origin.x;
    y1 = cutRect.origin.y;
    newW = cutRect.size.width;
    newH = cutRect.size.height;

    //生成图像并画图
    //创建一个bitmap的context
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(newW, newH), NO, 1.0);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextScaleCTM(UIGraphicsGetCurrentContext(), 1.0, 1.0);

    //设置图像质量
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetShouldAntialias(context, YES);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    //画图
    CGContextTranslateCTM(context, 0, newH);  //画布的高度
    CGContextScaleCTM(context, 1.0, -1.0);

    CGRect rcImage = CGRectMake(x1, y1, newW, newH);
    CGImageRef subImageRef = CGImageCreateWithImageInRect(srcImage.CGImage, rcImage);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, newW, newH), subImageRef);

    // 从当前context中创建一个的图片
    retImage = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRelease(subImageRef);
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();


    return retImage;
}


// 剪裁图像. cutRectBL -- 剪裁比例,范围 0~1
+ (UIImage *)cutImageFromBL:(CGRect)cutRectBL withSourceImage:(UIImage *)srcImage
{
    UIImage *retImage = NULL;
    int x1, y1, w, h, newW, newH;
    w = srcImage.size.width;
    h = srcImage.size.height;
    newW = w * cutRectBL.size.width;
    newH = h * cutRectBL.size.height;

    x1 = cutRectBL.origin.x * w;
    y1 = cutRectBL.origin.y * h;

    CGRect cutRect = CGRectMake(x1, y1, newW, newH);
    retImage = [self cutImage:cutRect withSourceImage:srcImage];
    return retImage;
}


+ (CGSize)acquireImageSizeWithJpegData:(NSData *)jpgData
{
    CGSize mySize = CGSizeMake(0, 0);
    CGImageSourceRef myImageSource = CGImageSourceCreateWithData((__bridge CFDataRef)jpgData, NULL);
    CFDictionaryRef imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(myImageSource, 0, NULL);
    if (imagePropertiesDictionary)
    {
        int w, h;
        CFNumberRef imageWidth = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary,
                                                                   kCGImagePropertyPixelWidth);
        CFNumberGetValue(imageWidth, kCFNumberIntType, &w);

        CFNumberRef imageHeight = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary,
                                                                    kCGImagePropertyPixelHeight);
        CFNumberGetValue(imageHeight, kCFNumberIntType, &h);

        mySize = CGSizeMake(w, h);

        CFRelease(imagePropertiesDictionary);
    }
    CFRelease(myImageSource);

    return mySize;
}


+ (CGSize)acquireImageSizeWithURL:(NSURL *)aUrl
{
    CGSize mySize = CGSizeMake(0, 0);
    CGImageSourceRef myImageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)(aUrl), NULL);
    if (!myImageSource)
    {
        return mySize;
    }
    CFDictionaryRef imagePropertiesDictionary = CGImageSourceCopyPropertiesAtIndex(myImageSource, 0, NULL);
    if (imagePropertiesDictionary)
    {
        int w, h;
        CFNumberRef imageWidth = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary,
                                                                   kCGImagePropertyPixelWidth);
        CFNumberGetValue(imageWidth, kCFNumberIntType, &w);

        CFNumberRef imageHeight = (CFNumberRef)CFDictionaryGetValue(imagePropertiesDictionary,
                                                                    kCGImagePropertyPixelHeight);
        CFNumberGetValue(imageHeight, kCFNumberIntType, &h);

        mySize = CGSizeMake(w, h);

        if (imagePropertiesDictionary)
        {
            CFRelease(imagePropertiesDictionary);
        }
    }

    if (myImageSource)
    {
        CFRelease(myImageSource);
    }

    return mySize;
}


+ (UIImage *)imageFromSampleBuffer:(CMSampleBufferRef)sampleBuffer
{
    // Get a CMSampleBuffer's Core Video image buffer for the media data
    CVImageBufferRef imageBuffer = CMSampleBufferGetImageBuffer(sampleBuffer);
    // Lock the base address of the pixel buffer
    CVPixelBufferLockBaseAddress(imageBuffer, 0);

    // Get the number of bytes per row for the pixel buffer
    void *baseAddress = CVPixelBufferGetBaseAddress(imageBuffer);

    // Get the number of bytes per row for the pixel buffer
    size_t bytesPerRow = CVPixelBufferGetBytesPerRow(imageBuffer);
    // Get the pixel buffer width and height
    size_t width = CVPixelBufferGetWidth(imageBuffer);
    size_t height = CVPixelBufferGetHeight(imageBuffer);

    // Create a device-dependent RGB color space
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    // Create a bitmap graphics context with the sample buffer data
    CGContextRef context = CGBitmapContextCreate(baseAddress,
                                                 width,
                                                 height,
                                                 8,
                                                 bytesPerRow,
                                                 colorSpace,
                                                 kCGBitmapByteOrder32Little | kCGImageAlphaPremultipliedFirst);
    // Create a Quartz image from the pixel data in the bitmap graphics context
    CGImageRef quartzImage = CGBitmapContextCreateImage(context);
    // Unlock the pixel buffer
    CVPixelBufferUnlockBaseAddress(imageBuffer, 0);


    // Free up the context and color space
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    // Create an image object from the Quartz image
    UIImage *image = [UIImage imageWithCGImage:quartzImage];

    // Release the Quartz image
    CGImageRelease(quartzImage);

    return (image);
}


#pragma mark 获取缩略图

static NSInteger const EFFECT_THUMBNAIL_IMAGE_SIZE = 100;


+ (UIImage *)getThumbnailImage:(UIImage *)image
{
    if (nil == image)
    {
        return nil;
    }

    //缩放效果图
    int scale = [[UIScreen mainScreen] scale];
    float thumnailSize = EFFECT_THUMBNAIL_IMAGE_SIZE * scale;

    //缩放小图
    UIImage *tempImage = nil;
    CGRect tempRect = CGRectZero;

    if (image.size.width > image.size.height)
    {
        tempImage = [PGImageUtility zoomImage:image
                                        width:thumnailSize * (image.size.width / image.size.height)
                                       height:thumnailSize];
        tempRect = CGRectMake(tempImage.size.width / 2 - (thumnailSize / 2), 0, thumnailSize, thumnailSize);
    }
    else
    {
        tempImage = [PGImageUtility zoomImage:image
                                        width:thumnailSize
                                       height:thumnailSize * (image.size.height / image.size.width)];
        tempRect = CGRectMake(0, tempImage.size.height / 2 - thumnailSize / 2, thumnailSize, thumnailSize);
    }

    return [PGImageUtility croppedImage:tempRect srcImage:tempImage];
}


+ (UIImage *)croppedImageWithImage:(UIImage *)image zoomScale:(CGFloat)zoomScale
{
    if(zoomScale == 1.0f)
    {
        return image;
    }
    CGFloat zoomReciprocal = 1.0f / zoomScale;
    CGPoint offsetPoint = CGPointMake(image.size.width * ((1.0f - zoomReciprocal) / 2.0f),
                                      image.size.height * ((1.0f - zoomReciprocal) / 2.0f));
    CGRect croppedRect = CGRectMake(offsetPoint.x,
                                    offsetPoint.y,
                                    image.size.width * zoomReciprocal,
                                    image.size.height * zoomReciprocal);
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect([image CGImage], croppedRect);
    UIImage *croppedImage = [[UIImage alloc] initWithCGImage:croppedImageRef
                                                       scale:[image scale]
                                                 orientation:[image imageOrientation]];

    CGImageRelease(croppedImageRef);

    return croppedImage;
}


+ (UIImage *)maskImage:(UIImage *)image withMask:(UIImage *)maskImage
{
    CGImageRef maskRef = maskImage.CGImage;

    CGImageRef mask = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);

    CGImageRef masked = CGImageCreateWithMask([image CGImage], mask);

    UIImage *result = [UIImage imageWithCGImage:masked];

    CGImageRelease(mask);
    // REV @sp masked 出现NULL
    CGImageRelease(masked);

    return result;
}


+ (UIImage *)blurredImage:(UIImage *)image withRadius:(CGFloat)radius
{
    CGImageRef img = image.CGImage;

    vImage_Buffer inBuffer, outBuffer;
    void *inDataBuffer, *outDataBuffer;

    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);

    size_t bufferSize = CGImageGetBytesPerRow(img) * CGImageGetHeight(img);

    inDataBuffer = malloc(bufferSize);
    memcpy(inDataBuffer, (void*)CFDataGetBytePtr(inBitmapData), bufferSize);

    inBuffer.data = inDataBuffer;
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);

    outDataBuffer = malloc(bufferSize);

    outBuffer.data = outDataBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);

    CGFloat inputRadius = radius * image.scale;
    if (inputRadius - 2. < __FLT_EPSILON__)
        inputRadius = 2.;
    uint32_t blurRadius = floor((inputRadius * 3. * sqrt(2 * M_PI) / 4 + 0.5) / 2);

    blurRadius |= 1; // force radius to be odd so that the three box-blur methodology works.

    NSInteger tempBufferSize = vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, NULL, 0, 0,
        blurRadius, blurRadius, NULL, kvImageGetTempBufferSize | kvImageEdgeExtend);
    void *tempBuffer = malloc(tempBufferSize);

    vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, tempBuffer, 0, 0,
        blurRadius, blurRadius, NULL, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&outBuffer, &inBuffer, tempBuffer, 0, 0,
        blurRadius, blurRadius, NULL, kvImageEdgeExtend);
    vImageBoxConvolve_ARGB8888(&inBuffer, &outBuffer, tempBuffer, 0, 0,
        blurRadius, blurRadius, NULL, kvImageEdgeExtend);

    free(tempBuffer);

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef ctx = CGBitmapContextCreate(outBuffer.data,
        outBuffer.width,
        outBuffer.height,
        8,
        outBuffer.rowBytes,
        colorSpace,
        CGImageGetBitmapInfo(image.CGImage));

    CGImageRef imageRef = CGBitmapContextCreateImage (ctx);
    UIImage *returnImage = [UIImage imageWithCGImage:imageRef];

    //clean up
    CGContextRelease(ctx);
    CGColorSpaceRelease(colorSpace);

    free(inDataBuffer);
    free(outDataBuffer);
    CFRelease(inBitmapData);

    CGImageRelease(imageRef);

    return returnImage;
}

/**
 *  将方形图片裁剪成圆形
 *
 *  @param image 方形图片
 *
 *  @return 圆形图片
 */
+ (UIImage *)clipImageToCycle:(UIImage *)image
{
    UIGraphicsBeginImageContext(image.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    CGRect imageRect = CGRectMake(0, 0, image.size.width, image.size.height);

    CGMutablePathRef path = CGPathCreateMutable();

    CGPathAddEllipseInRect(path, &CGAffineTransformIdentity, imageRect);

    CGContextAddPath(context, path);
    CGContextClip(context);

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, image.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context,
                       imageRect,
                       image.CGImage);
    CGContextRestoreGState(context);

    UIImage *makedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGPathRelease(path);

    return makedImage;
}

+ (NSData *)compressThumbImageData:(NSData *)aImageData belowSize:(NSUInteger)aSize
{
    if (aImageData.length <= aSize)
    {
        return aImageData;
    }

    float defaultSacle = 0.7;

    NSData *compressedData = nil;

    do
    {
        UIImage *orgPreviewImage = [[UIImage alloc] initWithData:aImageData];
        compressedData = UIImageJPEGRepresentation(orgPreviewImage, defaultSacle);

        //压缩之后仍然大于阀值，缩小图片质量
        if (compressedData.length > aSize)
        {
            orgPreviewImage = [[UIImage alloc] initWithData:compressedData];
            orgPreviewImage = [PGImageUtility getScaleImage:orgPreviewImage
                                                      width:orgPreviewImage.size.width * defaultSacle
                                                 imageScale:1];
            aImageData = UIImageJPEGRepresentation(orgPreviewImage, 1.0);
        }

    } while (compressedData.length > aSize);

    return compressedData;
}



+ (NSDictionary *)getEXIFFromNSData:(NSData *)data
{
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    CFDictionaryRef metadataDictRef = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    NSDictionary *metadata = CFBridgingRelease(metadataDictRef);
    CFRelease(source);
    return metadata;
}

@end

