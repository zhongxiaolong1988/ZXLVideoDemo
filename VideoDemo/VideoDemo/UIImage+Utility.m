//
// Created by peter.shi on 16/5/24.
// Copyright (c) 2016 pinguo. All rights reserved.
//

#import "UIImage+Utility.h"
#import <ImageIO/ImageIO.h>
#import <Accelerate/Accelerate.h>


CGFloat DegreesToRadians(CGFloat degrees)
{return degrees * M_PI / 180;}


@implementation UIImage (Utility)

#pragma mark - 对象实例 -


+ (nullable UIImage *)imageWithPixels:(unsigned char *)pixels width:(CGFloat)width height:(CGFloat)height
{
    CGColorSpaceRef space = CGColorSpaceCreateDeviceRGB();
    // REV @sp 最后一个参数可能有问题
    CGContextRef context2 = CGBitmapContextCreate(pixels, width, height, 8, width * 4,
                                                  space, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGImageRef cgimg = CGBitmapContextCreateImage(context2);
    CGContextRelease(context2);
    CGColorSpaceRelease(space);
    UIImage *imgRet = [[UIImage alloc] initWithCGImage:cgimg];
    CGImageRelease(cgimg);

    return imgRet;
}


+ (nullable UIImage *)imageWithSampleBuffer:(CMSampleBufferRef)sampleBuffer
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


#pragma mark - 像素操作 -


- (unsigned char *)pixles
{
    CGFloat pixWidth, pixHeight;

    pixWidth = CGImageGetWidth(self.CGImage);
    pixHeight = CGImageGetHeight(self.CGImage);

    unsigned char *orgPixel = malloc(pixWidth * pixHeight * 4);

    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * pixWidth;
    NSUInteger bitsPerComponent = 8;

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    CGContextRef context = CGBitmapContextCreate(orgPixel, pixWidth, pixHeight,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGContextDrawImage(context, CGRectMake(0, 0, pixWidth, pixHeight), self.CGImage);
    CGContextRelease(context);
    CGColorSpaceRelease(colorSpace);

    return orgPixel;
}


- (unsigned char *)pixlesGray
{
    unsigned char *orgPixel = [self pixles];

    unsigned char *pIndex = orgPixel;
    size_t iWidth = CGImageGetWidth(self.CGImage);
    size_t iHeight = CGImageGetHeight(self.CGImage);

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


#pragma mark - 图像操作 -


- (nullable UIImage *)scaleWithSize:(CGSize)size
{
    return [self resize:size interpolationQuality:kCGInterpolationHigh];
}


//根据最大的像素进行缩放图片
- (nullable UIImage *)scaleWithMaxPixelCount:(NSInteger)maxPixelCount
{
    if (self.size.width * self.size.height <= maxPixelCount)
    {
        return self;
    }

    CGFloat width = sqrt((self.size.width / self.size.height) * maxPixelCount);
    CGFloat height = sqrt((self.size.height / self.size.width) * maxPixelCount);
    CGSize size = CGSizeMake(width, height);
    UIImage *img = [self scaleWithSize:size];
    return img;
}


- (nullable UIImage *)scaleWithWidth:(CGFloat)width
{
    //缩放图片
    CGFloat w, h;
    CGFloat tw = self.size.width;
    CGFloat th = self.size.height;
    CGFloat rate = tw / th;
    if (self.size.width < self.size.height)
    {
        w = rate * width;
        h = width;
    }
    else
    {
        w = width;
        h = width / rate;
    }
    return [self scaleWithSize:CGSizeMake(w, h)];
}


- (nullable UIImage *)rotateWithAngle:(CGFloat)angle
{
    @autoreleasepool
    {
        // calculate the size of the rotated view's containing box for our drawing space
        // REV @ppg 这里可能被异步调用,然后崩溃, 非线程安全
        UIView *rotatedViewBox = [[UIView alloc]
                                          initWithFrame:CGRectMake(0, 0, self.size.width, self.size.height)];
        CGAffineTransform t = CGAffineTransformMakeRotation(DegreesToRadians(angle));
        rotatedViewBox.transform = t;
        CGSize rotatedSize = rotatedViewBox.frame.size;

        // Create the bitmap context
        UIGraphicsBeginImageContext(rotatedSize);
        CGContextRef bitmap = UIGraphicsGetCurrentContext();

        // Move the origin to the middle of the image so we will rotate and scale around the center.
        CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);

        //   // Rotate the image context
        CGContextRotateCTM(bitmap, DegreesToRadians(angle));

        // Now, draw the rotated/scaled image into the context
        CGContextScaleCTM(bitmap, 1.0, -1.0);
        CGContextDrawImage(bitmap,
                           CGRectMake(-self.size.width / 2,
                                      -self.size.height / 2,
                                      self.size.width,
                                      self.size.height),
                           self.CGImage);

        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
    }
}


#pragma mark - 裁剪 -


- (nullable UIImage *)cropWithBounds:(CGRect)bounds
{
    CGImageRef imageRef = CGImageCreateWithImageInRect(self.CGImage, bounds);
    UIImage *croppedImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    return croppedImage;
}


- (nullable UIImage *)cropWithInsets:(UIEdgeInsets)insets
{
    CGRect rect = CGRectMake(insets.left,
                             insets.top,
                             self.size.width - insets.left - insets.right,
                             self.size.height - insets.top - insets.bottom);
    return [self cropWithBounds:rect];
}


// 剪裁图像
- (nullable UIImage *)cropWithRect:(CGRect)rect
{
    UIImage *retImage = NULL;
    int x1, y1, newW, newH;
    x1 = rect.origin.x;
    y1 = rect.origin.y;
    newW = rect.size.width;
    newH = rect.size.height;

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
    CGImageRef subImageRef = CGImageCreateWithImageInRect(self.CGImage, rcImage);
    CGContextDrawImage(UIGraphicsGetCurrentContext(), CGRectMake(0, 0, newW, newH), subImageRef);

    // 从当前context中创建一个的图片
    retImage = UIGraphicsGetImageFromCurrentImageContext();
    CGImageRelease(subImageRef);
    // 使当前的context出堆栈
    UIGraphicsEndImageContext();


    return retImage;
}


- (nullable UIImage *)cropWithScale:(CGFloat)scale
{
    if (scale == 1.0f)
    {
        return self;
    }
    CGFloat zoomReciprocal = 1.0f / scale;
    CGPoint offsetPoint = CGPointMake(self.size.width * ((1.0f - zoomReciprocal) / 2.0f),
                                      self.size.height * ((1.0f - zoomReciprocal) / 2.0f));
    CGRect croppedRect = CGRectMake(offsetPoint.x,
                                    offsetPoint.y,
                                    self.size.width * zoomReciprocal,
                                    self.size.height * zoomReciprocal);
    CGImageRef croppedImageRef = CGImageCreateWithImageInRect(self.CGImage, croppedRect);
    UIImage *croppedImage = [[UIImage alloc] initWithCGImage:croppedImageRef
                                                       scale:[self scale]
                                                 orientation:[self imageOrientation]];

    CGImageRelease(croppedImageRef);

    return croppedImage;
}


- (nullable UIImage *)cropCycle
{
    UIGraphicsBeginImageContext(self.size);
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetAllowsAntialiasing(context, YES);
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);

    CGRect imageRect = CGRectMake(0, 0, self.size.width, self.size.height);

    CGMutablePathRef path = CGPathCreateMutable();

    CGPathAddEllipseInRect(path, &CGAffineTransformIdentity, imageRect);

    CGContextAddPath(context, path);
    CGContextClip(context);

    CGContextSaveGState(context);
    CGContextTranslateCTM(context, 0, self.size.height);
    CGContextScaleCTM(context, 1.0, -1.0);
    CGContextDrawImage(context,
                       imageRect,
                       self.CGImage);
    CGContextRestoreGState(context);

    UIImage *makedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CGPathRelease(path);

    return makedImage;
}


- (nullable UIImage *)mask:(UIImage *)image
{
    CGImageRef maskRef = image.CGImage;

    CGImageRef temp = CGImageMaskCreate(CGImageGetWidth(maskRef),
                                        CGImageGetHeight(maskRef),
                                        CGImageGetBitsPerComponent(maskRef),
                                        CGImageGetBitsPerPixel(maskRef),
                                        CGImageGetBytesPerRow(maskRef),
                                        CGImageGetDataProvider(maskRef), NULL, false);

    CGImageRef masked = CGImageCreateWithMask(self.CGImage, temp);

    UIImage *result = [UIImage imageWithCGImage:masked];

    CGImageRelease(temp);
    CGImageRelease(masked);

    return result;
}


- (nullable UIImage *)blurry:(CGFloat)radius
{
    CGImageRef img = self.CGImage;

    vImage_Buffer inBuffer, outBuffer;
    void *inDataBuffer, *outDataBuffer;

    CGDataProviderRef inProvider = CGImageGetDataProvider(img);
    CFDataRef inBitmapData = CGDataProviderCopyData(inProvider);

    size_t bufferSize = CGImageGetBytesPerRow(img) * CGImageGetHeight(img);

    inDataBuffer = malloc(bufferSize);
    memcpy(inDataBuffer, (void *)CFDataGetBytePtr(inBitmapData), bufferSize);

    inBuffer.data = inDataBuffer;
    inBuffer.width = CGImageGetWidth(img);
    inBuffer.height = CGImageGetHeight(img);
    inBuffer.rowBytes = CGImageGetBytesPerRow(img);

    outDataBuffer = malloc(bufferSize);

    outBuffer.data = outDataBuffer;
    outBuffer.width = CGImageGetWidth(img);
    outBuffer.height = CGImageGetHeight(img);
    outBuffer.rowBytes = CGImageGetBytesPerRow(img);

    CGFloat inputRadius = radius * self.scale;
    if (inputRadius - 2. < __FLT_EPSILON__)
    {
        inputRadius = 2.;
    }
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
                                             CGImageGetBitmapInfo(self.CGImage));

    CGImageRef imageRef = CGBitmapContextCreateImage(ctx);
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


- (nullable UIImage *)mirror:(BOOL)horizontal vertical:(BOOL)vertical
{
    //如果方向值相对于90度旋转，相对于x轴镜像应该是相对于y轴，反之亦然
    if (([self imageOrientation] == UIImageOrientationLeft)
        || ([self imageOrientation] == UIImageOrientationRight))
    {
        BOOL tmpMirror = horizontal;

        horizontal = vertical;
        vertical = tmpMirror;
    }

    CGImageRef imgRef = self.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1;

    transform = CGAffineTransformIdentity;
    if (horizontal && vertical)
    {
        transform = CGAffineTransformMakeTranslation(width, height);
        transform = CGAffineTransformScale(transform, -1.0, -1.0);
    }
    else if (horizontal)
    {
        transform = CGAffineTransformMakeTranslation(width, 0.0);
        transform = CGAffineTransformScale(transform, -1.0, 1.0);
    }
    else if (vertical)
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
                              orientation:[self imageOrientation]];
    return imageCopy;
}




- (nullable UIImage *)thumbnail
{
    NSInteger const THUMBNAIL_IMAGE_SIZE = 100;
    
    if (nil == self)
    {
        return nil;
    }

    //缩放效果图
    int scale = [[UIScreen mainScreen] scale];
    float thumnailSize = THUMBNAIL_IMAGE_SIZE * scale;

    //缩放小图
    UIImage *tempImage = nil;
    CGRect tempRect = CGRectZero;

    if (self.size.width > self.size.height)
    {
        tempImage = [self scaleWithSize:CGSizeMake(thumnailSize * (self.size.width / self.size.height), thumnailSize)];
        tempRect = CGRectMake(tempImage.size.width / 2 - (thumnailSize / 2), 0, thumnailSize, thumnailSize);
    }
    else
    {
        tempImage = [self scaleWithSize:CGSizeMake(thumnailSize, thumnailSize * (self.size.height / self.size.width))];
        tempRect = CGRectMake(0, tempImage.size.height / 2 - thumnailSize / 2, thumnailSize, thumnailSize);
    }

    return [tempImage cropWithRect:tempRect];
}


#pragma mark 矫正图片的方向


- (nullable UIImage *)transformByOrientation
{
    CGImageRef imgRef = self.CGImage;
    CGFloat width = CGImageGetWidth(imgRef);
    CGFloat height = CGImageGetHeight(imgRef);
    CGAffineTransform transform = CGAffineTransformIdentity;
    CGRect bounds = CGRectMake(0, 0, width, height);
    CGFloat scaleRatio = 1;
    CGFloat boundHeight;
    UIImageOrientation orient = self.imageOrientation;
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


// 通过旋转角度取得图像旋转值
- (UIImageOrientation)convertAngleToOrientation:(NSInteger)angle
{
    UIImageOrientation orientation = UIImageOrientationUp;
    switch (angle)
    {
        case 0:
            orientation = UIImageOrientationUp;           // default orientation
            break;
        case 180:
            orientation = UIImageOrientationDown;          // 180 deg rotation
            break;
        case 270:
            orientation = UIImageOrientationLeft;         // 90 deg CCW
            break;
        case 90:
            orientation = UIImageOrientationRight;         // 90 deg CW
            break;
        default:
            orientation = UIImageOrientationUp;
    }
    return orientation;
}


#pragma mark - 工具 -


+ (nullable NSData *)compressWithData:(NSData *)imageData maxBytesCount:(NSUInteger)maxBytesCount
{
    if (imageData.length <= maxBytesCount)
    {
        return imageData;
    }

    float defaultSacle = 0.7;

    NSData *compressedData = nil;

    do
    {
        UIImage *orgPreviewImage = [[UIImage alloc] initWithData:imageData];
        compressedData = UIImageJPEGRepresentation(orgPreviewImage, defaultSacle);

        //压缩之后仍然大于阀值，缩小图片质量
        if (compressedData.length > maxBytesCount)
        {
            orgPreviewImage = [[UIImage alloc] initWithData:compressedData];
            orgPreviewImage = [orgPreviewImage scaleWithWidth:orgPreviewImage.size.width * defaultSacle];
            imageData = UIImageJPEGRepresentation(orgPreviewImage, 1.0);
        }
    } while (compressedData.length > maxBytesCount);

    return compressedData;
}


+ (CGSize)sizeWithImageData:(NSData *)jpgData
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


+ (CGSize)sizeWithImageURL:(NSURL *)url
{
    CGSize mySize = CGSizeMake(0, 0);
    CGImageSourceRef myImageSource = CGImageSourceCreateWithURL((__bridge CFURLRef)(url), NULL);
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


+ (NSDictionary *)exifWithData:(NSData *)data
{
    CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)data, NULL);
    CFDictionaryRef metadataDictRef = CGImageSourceCopyPropertiesAtIndex(source, 0, NULL);
    NSDictionary *metadata = CFBridgingRelease(metadataDictRef);
    CFRelease(source);
    return metadata;
}


#pragma mark - private function -


- (nullable UIImage *) resize:(CGSize)size
interpolationQuality:(CGInterpolationQuality)quality
{
    BOOL drawTransposed;

    switch (self.imageOrientation)
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

    return [self resized:size
               transform:[self transformForOrientation:size]
          drawTransposed:drawTransposed
    interpolationQuality:quality];
}


- (nullable UIImage *)resized:(CGSize)size
           transform:(CGAffineTransform)transform
      drawTransposed:(BOOL)transpose
interpolationQuality:(CGInterpolationQuality)quality
{
#if TARGET_IPHONE_SIMULATOR
    // 模拟器中CGBitmapContextCreate()返回nil，使用替代方法
    CGRect transposedRect;
    if (transpose)
    {
        transposedRect = CGRectMake(0, 0, size.height, size.width);
    }
    else
    {
        transposedRect = CGRectMake(0, 0, size.width, size.height);
    }

    UIGraphicsBeginImageContextWithOptions(size, NO, 0);
    CGContextRef context = UIGraphicsGetCurrentContext();

    CGContextConcatCTM(context, transform);
    CGContextSetInterpolationQuality(context, quality);
    CGContextSetShouldAntialias(context, NO);

    [self drawInRect:transposedRect];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return newImage;
#else
    CGRect newRect = CGRectIntegral(CGRectMake(0, 0, size.width, size.height));
    CGRect transposedRect;
    if (transpose)
    {
        transposedRect = CGRectMake(0, 0, newRect.size.height, newRect.size.width);
    }
    else
    {
        transposedRect = CGRectMake(0, 0, newRect.size.width, newRect.size.height);
    }
    CGImageRef imageRef = self.CGImage;

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
- (CGAffineTransform)transformForOrientation:(CGSize)size
{
    CGAffineTransform transform = CGAffineTransformIdentity;

    int iOrien = self.imageOrientation;
    switch (iOrien)
    {
        // REV @sp default and UIImageOrientationUpMirrored not handle
        case UIImageOrientationUp:
            transform = CGAffineTransformIdentity;
            break;
        case UIImageOrientationDown:
            transform = CGAffineTransformTranslate(transform, size.width, size.height);
            transform = CGAffineTransformRotate(transform, -M_PI);
            break;
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, size.width, size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;

        case UIImageOrientationLeft:           // EXIF = 6
        case UIImageOrientationLeftMirrored:   // EXIF = 5
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;

        case UIImageOrientationRight:          // EXIF = 8
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, 0, size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
    }

    switch (iOrien)
    {
        case UIImageOrientationUpMirrored:     // EXIF = 2
        case UIImageOrientationDownMirrored:   // EXIF = 4
            transform = CGAffineTransformTranslate(transform, size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;

        case UIImageOrientationLeftMirrored:   // EXIF = 5
        case UIImageOrientationRightMirrored:  // EXIF = 7
            transform = CGAffineTransformTranslate(transform, size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            // REV @sp other orientation not handle
    }

    return transform;
}

@end


