//
//  ContourAnalyser.h
//  FoodFace
//
//  Created by Aaron on 01/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import <opencv2/opencv.hpp>

@interface ContourAnalyser : NSObject

+ (std::vector<std::vector<cv::Point>>)findContoursInImage:(cv::Mat)image arcLengthMultiplier:(float)arcLengthMultiplier;
+ (std::vector<std::vector<cv::Point>>)filterContours:(std::vector<std::vector<cv::Point>>)contours;
+ (NSMutableArray*)reduceContoursToBoundingBox:(cv::vector<cv::Mat>)contours;

@end
