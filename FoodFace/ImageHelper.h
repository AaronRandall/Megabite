//
//  ImageHelper.h
//  FoodFace
//
//  Created by Aaron on 01/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

@interface ImageHelper : NSObject

+ (UIImage *)UIImageFromCVMat:(cv::Mat)cvMat;
+ (cv::Mat)cvMatFromUIImage:(UIImage *)image;
+ (cv::Mat)highlightContoursInImage:(std::vector<std::vector<cv::Point>>)contours image:(cv::Mat)image;
+ (cv::vector<cv::Mat>)cutContoursFromImage:(std::vector<std::vector<cv::Point>>)contours image:(cv::Mat)image;
+ (UIImage*)roundedRectImageFromImage:(UIImage *)image size:(CGSize)imageSize withCornerRadius:(float)cornerRadius;
+ (UIImage*)imageBoundingBox:(UIImage*)image;
+ (UIImage *)imageRotatedByDegrees:(CGFloat)degrees image:(UIImage*)image;
+ (CGFloat)degreesToRadians:(CGFloat)degrees;
+ (NSUInteger)numberOfRedPixelsInImage:(UIImage*)image;
+ (UIImage *)resizeImage:(UIImage *)image scaledToSize:(CGSize)size;

@end
