//
//  ImageHelper.m
//  Megabite
//
//  Created by Aaron on 01/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import "ImageHelper.h"
#import "UIImage+AverageColor.h"
#import "UIImage+Trim.h"

@implementation ImageHelper

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat {
    NSData *data = [NSData dataWithBytes:cvMat.data length:cvMat.elemSize()*cvMat.total()];
    CGColorSpaceRef colorSpace;
    
    if (cvMat.elemSize() == 1) {
        colorSpace = CGColorSpaceCreateDeviceGray();
    } else {
        colorSpace = CGColorSpaceCreateDeviceRGB();
    }
    
    CGDataProviderRef provider = CGDataProviderCreateWithCFData((__bridge CFDataRef)data);
    
    // Creating CGImage from cv::Mat
    CGImageRef imageRef = CGImageCreate(cvMat.cols,                                 //width
                                        cvMat.rows,                                 //height
                                        8,                                          //bits per component
                                        8 * cvMat.elemSize(),                       //bits per pixel
                                        cvMat.step[0],                              //bytesPerRow
                                        colorSpace,                                 //colorspace
                                        kCGImageAlphaNone|kCGBitmapByteOrderDefault,// bitmap info
                                        provider,                                   //CGDataProviderRef
                                        NULL,                                       //decode
                                        false,                                      //should interpolate
                                        kCGRenderingIntentDefault                   //intent
                                        );
    
    
    // Getting UIImage from CGImage
    UIImage *finalImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);
    
    return finalImage;
}

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image {
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGFloat cols = image.size.width;
    CGFloat rows = image.size.height;
    
    cv::Mat cvMat(rows, cols, CV_8UC4); // 8 bits per component, 4 channels (color channels + alpha)
    
    CGContextRef contextRef = CGBitmapContextCreate(cvMat.data,                 // Pointer to  data
                                                    cols,                       // Width of bitmap
                                                    rows,                       // Height of bitmap
                                                    8,                          // Bits per component
                                                    cvMat.step[0],              // Bytes per row
                                                    colorSpace,                 // Colorspace
                                                    kCGImageAlphaNoneSkipLast |
                                                    kCGBitmapByteOrderDefault); // Bitmap info flags
    
    CGContextDrawImage(contextRef, CGRectMake(0, 0, cols, rows), image.CGImage);
    CGContextRelease(contextRef);
    
    return cvMat;
}

+ (cv::Mat)highlightContoursInImage:(std::vector<std::vector<cv::Point>>)contours image:(cv::Mat)image {
    for ( int i = 0; i< contours.size(); i++ ) {
        cv::drawContours(image, contours, i, cv::Scalar(255,0,0), 10, 8, std::vector<cv::Vec4i>(), 0, cv::Point());
        std::vector<cv::Point> currentSquare = contours[i];
    }
    
    return image;
}

+ (cv::vector<cv::Mat>)cutContoursFromImage:(std::vector<std::vector<cv::Point>>)contours image:(cv::Mat)image {
    cv::vector<cv::Mat> subregions;
    
    for (int i = 0; i < contours.size(); i++)
    {
        // Get bounding box for contour
        //cv::Rect roi = cv::boundingRect(contours[i]); // This is a OpenCV function
        
        // Create a mask for each contour to mask out that region from image.
        cv::Mat mask = cv::Mat::zeros(image.size(), CV_8UC1);
        drawContours(mask, contours, i, cv::Scalar(255), CV_FILLED); // This is a OpenCV function
        
        // At this point, mask has value of 255 for pixels within the contour and value of 0 for those not in contour.
        
        // Extract region using mask for region
        cv::Mat contourRegion;
        cv::Mat imageROI;
        image.copyTo(imageROI, mask); // 'image' is the image you used to compute the contours.
        contourRegion = imageROI;//(roi);
        // Mat maskROI = mask(roi); // Save this if you want a mask for pixels within the contour in contourRegion.
        
        // Store contourRegion. contourRegion is a rectangular image the size of the bounding rect for the contour
        // BUT only pixels within the contour is visible. All other pixels are set to (0,0,0).
        subregions.push_back(contourRegion);
    }
    
    return subregions;
}

+ (UIImage*)roundedRectImageFromImage:(UIImage *)image size:(CGSize)imageSize withCornerRadius:(float)cornerRadius {
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, image.scale);
    CGRect bounds=(CGRect){CGPointZero,imageSize};
    [[UIBezierPath bezierPathWithRoundedRect:bounds
                                cornerRadius:cornerRadius] addClip];
    [image drawInRect:bounds];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImage;
}

+ (UIImage*)imageBoundingBox:(UIImage*)image maxNumPolygonRotations:(int)maxNumPolygonRotations {
    int boundingBoxRotation = 0;
    int smallestSurfaceArea = image.size.height * image.size.width;
    
    int maximumNumRotationsInDegrees = 180;
    
    for (int i = 0; i < maxNumPolygonRotations; i++) {
        int degrees = i * (maximumNumRotationsInDegrees/maxNumPolygonRotations);
        // Rotate the image
        UIImage *tempImage = [self imageRotatedByDegrees:degrees image:image];
        
        // Trim to smallest box
        tempImage = [tempImage imageByTrimmingTransparentPixels];
        int currentSurfaceArea = (tempImage.size.height * tempImage.size.width);
        
        if (currentSurfaceArea < smallestSurfaceArea) {
            // The current rotation has a smaller surface area than the previous smallest surface area
            smallestSurfaceArea = currentSurfaceArea;
            boundingBoxRotation = degrees;
        }
    }
    
    UIImage *boundingBoxImage = [self imageRotatedByDegrees:boundingBoxRotation image:image];
    
    // Trim to smallest box
    boundingBoxImage = [boundingBoxImage imageByTrimmingTransparentPixels];
    
    return boundingBoxImage;
}

+ (CGFloat)degreesToRadians:(CGFloat)degrees {
    return degrees * M_PI / 180;
}

+ (UIImage *)imageRotatedByDegrees:(CGFloat)degrees image:(UIImage*)image {
    CGFloat radians = [ImageHelper degreesToRadians:degrees];
    
    UIView *rotatedViewBox = [[UIView alloc] initWithFrame:CGRectMake(0,0, image.size.width, image.size.height)];
    CGAffineTransform t = CGAffineTransformMakeRotation(radians);
    rotatedViewBox.transform = t;
    CGSize rotatedSize = rotatedViewBox.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(rotatedSize, NO, image.scale);
    CGContextRef bitmap = UIGraphicsGetCurrentContext();
    
    CGContextTranslateCTM(bitmap, rotatedSize.width / 2, rotatedSize.height / 2);
    
    CGContextRotateCTM(bitmap, radians);
    
    CGContextScaleCTM(bitmap, 1.0, -1.0);
    CGContextDrawImage(bitmap, CGRectMake(-image.size.width / 2, -image.size.height / 2 , image.size.width, image.size.height), image.CGImage );
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return newImage;
}

struct pixel {
    unsigned char r, g, b, a;
};

+ (NSUInteger)numberOfRedPixelsInImage:(UIImage*) image {
    NSUInteger numberOfRedPixels = 0;
    
    // Allocate a buffer big enough to hold all the pixels
    struct pixel* pixels = (struct pixel*) calloc(1, image.size.width * image.size.height * sizeof(struct pixel));
    
    if (pixels != nil)
    {
        // Create a new bitmap
        
        CGContextRef context = CGBitmapContextCreate(
                                                     (void*) pixels,
                                                     image.size.width,
                                                     image.size.height,
                                                     8,
                                                     image.size.width * 4,
                                                     CGImageGetColorSpace(image.CGImage),
                                                     kCGImageAlphaPremultipliedLast
                                                     );
        
        if (context != NULL)
        {
            // Draw the image in the bitmap
            
            CGContextDrawImage(context, CGRectMake(0.0f, 0.0f, image.size.width, image.size.height), image.CGImage);
            
            // Now that we have the image drawn in our own buffer, we can loop over the pixels to
            // process it. This simple case simply counts all pixels that have a pure red component.
            
            // There are probably more efficient and interesting ways to do this. But the important
            // part is that the pixels buffer can be read directly.
            NSUInteger numberOfPixels = image.size.width * image.size.height;
            
            for (int i=0; i<numberOfPixels; i++) {
                if (pixels[i].r == 255) {
                    numberOfRedPixels++;
                }
            }
            
            CGContextRelease(context);
        }
        
        free(pixels);
    }
    
    return numberOfRedPixels;
}

+ (UIImage *)resizeImage:(UIImage *)image scaledToSize:(CGSize)size {
    //UIGraphicsBeginImageContext(newSize);
    // In next line, pass 0.0 to use the current device's pixel scaling factor (and thus account for Retina resolution).
    // Pass 1.0 to force exact pixel size.
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

@end