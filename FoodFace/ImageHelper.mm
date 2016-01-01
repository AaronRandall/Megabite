//
//  ImageHelper.m
//  FoodFace
//
//  Created by Aaron on 01/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import "ImageHelper.h"

@implementation ImageHelper

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
{
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

+ (cv::Mat)cvMatFromUIImage:(UIImage *)image
{
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

+ (cv::Mat)highlightContoursInImage:(std::vector<std::vector<cv::Point>>)contours image:(cv::Mat)image
{
    for ( int i = 0; i< contours.size(); i++ ) {
        // draw contour
        cv::drawContours(image, contours, i, cv::Scalar(255,0,0), 10, 8, std::vector<cv::Vec4i>(), 0, cv::Point());
        
        std::vector<cv::Point> currentSquare = contours[i];
        
        //        // draw bounding rect
        //        cv::Rect rect = boundingRect(cv::Mat(squares[i]));
        //        cv::rectangle(image, rect.tl(), rect.br(), cv::Scalar(0,255,0), 2, 8, 0);
        
        //        // draw rotated rect
        //        cv::RotatedRect minRect = minAreaRect(cv::Mat(squares[i]));
        //        cv::Point2f rect_points[4];
        //        minRect.points( rect_points );
        //        for ( int j = 0; j < 4; j++ ) {
        //            cv::line( image, rect_points[j], rect_points[(j+1)%4], cv::Scalar(0,0,255), 1, 8 ); // blue
        //        }
    }
    
    return image;
}

+ (cv::vector<cv::Mat>)cutContoursFromImage:(std::vector<std::vector<cv::Point>>)contours image:(cv::Mat)image
{
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

@end
