//
//  ContourAnalyser.h
//  FoodFace
//
//  Created by Aaron on 01/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <opencv2/opencv.hpp>
#import <UIKit/UIKit.h>

@interface ContourAnalyser : NSObject

+ (std::vector<std::vector<cv::Point>>)findContoursInImage:(cv::Mat)image;
+ (std::vector<std::vector<cv::Point>>)filterContours:(std::vector<std::vector<cv::Point>>)contours;

@end
