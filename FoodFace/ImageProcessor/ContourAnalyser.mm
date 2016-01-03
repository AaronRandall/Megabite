//
//  ContourAnalyser.m
//  FoodFace
//
//  Created by Aaron on 01/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import "ContourAnalyser.h"
#import <opencv2/opencv.hpp>
#import "ImageHelper.h"
#import "UIImage+AverageColor.h"
#import "UIImage+Trim.h"

@implementation ContourAnalyser

+ (std::vector<std::vector<cv::Point>>)findContoursInImage:(cv::Mat)image arcLengthMultiplier:(float)arcLengthMultiplier {
    std::vector<std::vector<cv::Point>> validContours;
    cv::Mat pyr, timg, gray0(image.size(), CV_8U), gray;
    int thresh = 50, N = 11;
    cv::pyrDown(image, pyr, cv::Size(image.cols/2, image.rows/2));
    cv::pyrUp(pyr, timg, image.size());
    std::vector<std::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    bool skipNonConvexContours = YES;
    
    for( int c = 0; c < 3; c++ ) {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);
        for( int l = 0; l < N; l++ ) {
            if( l == 0 ) {
                cv::Canny(gray0, gray, 0, thresh, 3);
                //cv::threshold(gray0, gray, 192.0, 255.0, 1);
                
                UIImage *greyImage = [ImageHelper UIImageFromCVMat:gray];
                //self.debugImageView6.image = greyImage;
                
                cv::dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
                
                greyImage = [ImageHelper UIImageFromCVMat:gray];
                //self.debugImageView7.image = greyImage;
            }
            else {
                //                continue;
                skipNonConvexContours = YES;
                gray = gray0 >= (l+1)*255/N;
            }
            
            cv::findContours(gray, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
            
            // hierarchy is ordered as: [Next, Previous, First_Child, Parent]
            
            std::vector<cv::Point> approx;
            for( size_t i = 0; i < contours.size(); i++ )
            {
                // TODO: support adjusting 0.02 value and update detected objects
                // so user can tweak to get the correct detection
                cv::approxPolyDP(cv::Mat(contours[i]),
                                 approx,
                                 cv::arcLength(cv::Mat(contours[i]), true) * arcLengthMultiplier,
                                 true
                                 );
                
                std::vector<cv::Point> currentContour = contours[i];
                cv::Rect x = cv::boundingRect(currentContour);
                
                if (x.width > 800 || x.height > 800) {
                    //NSLog(@"Skipping contour due to width/height constraints");
                    continue;
                }
                
                // Skip small or non-convex objects
                if (std::fabs(cv::contourArea(contours[i])) < 5000
                    || fabs(contourArea(cv::Mat(contours[i]))) > 250000) {
                    // NSLog(@"Skipping contour due to surface area constraints");
                    continue;
                }
                
                //                if(hierarchy[i][2]<0) {
                //                    //Check if there is a child contour
                //                    NSLog(@"Open Contour");
                //                    continue;
                //                } else {
                //                    NSLog(@"Closed Contour");
                //                }
                //
                //
                if (skipNonConvexContours && !cv::isContourConvex(approx)) {
                    //NSLog(@"Skipping contour due to being non-convex");
                    continue;
                }
                
                //                if (std::fabs(cv::contourArea(contours[i])) < 1000 ||
                //                    !cv::isContourConvex(approx))
                //                    continue;
                //
                //                if (std::fabs(cv::contourArea(contours[i])) < 1000 ||
                //                    fabs(contourArea(cv::Mat(contours[i]))) > 500000)
                //                    continue;
                //
                //                if (!cv::isContourConvex(approx))
                //                    continue;
                //                
                //                NSLog(@"Sides: %lu", approx.size());
                //                NSLog(@"Size: %f", fabs(contourArea(cv::Mat(contours[i]))));
                
                validContours.push_back(contours[i]);
            }
        }
    }
    
    return validContours;
}

+ (std::vector<std::vector<cv::Point>>)filterContours:(std::vector<std::vector<cv::Point>>)contours {
    NSMutableSet *evictedIndexes = [NSMutableSet set];
    
    std::vector<std::vector<cv::Point>> filteredContours;
    
    for ( int x = 0; x< contours.size(); x++ ) {
        for ( int y = 0; y< contours.size(); y++ ) {
            if (y <= x) {
                continue;
            }
            
            // 0 == perfect match
            //double result = cv::matchShapes(contours[x], contours[y], 1, 1);
            //NSLog(@"Comparison result: %f", result);
            //if (result <= 0.5) {
            //    [evictedIndexes addObject:[NSNumber numberWithInt:y]];
            //}
            
            cv::Rect boundingRectX = cv::boundingRect(contours[x]);
            cv::Rect boundingRectY = cv::boundingRect(contours[y]);
            
            // Evict contours that are similar in bounds to the current contour
            if ((std::fabs(boundingRectX.x - boundingRectY.x) < 25.0f) && (std::fabs(boundingRectX.y - boundingRectY.y) < 25.0f)) {
                //NSLog(@"** removing item (x,x)(y,y): (%d,%d),(%d,%d)", boundingRectX.x, boundingRectY.x, boundingRectX.y, boundingRectY.y);
                [evictedIndexes addObject:[NSNumber numberWithInt:y]];
            }
        }
    }
    
    for ( int x = 0; x< contours.size(); x++ ) {
        if ([evictedIndexes containsObject:[NSNumber numberWithInt:x]]) {
            continue;
        }
        
        filteredContours.push_back(contours[x]);
    }
    
    //    NSLog(@"** Num. filtered items: %lu", filteredContours.size());
    
    // Evict contours which are inside other similar contours (e.g. carrot)
    evictedIndexes = [NSMutableSet set];
    for (int x = 0; x < filteredContours.size(); x++) {
        for ( int y = 0; y< filteredContours.size(); y++ ) {
            if (x == y) {
                continue;
            }
            
            // Take the first point of the current (y) contour
            cv::Point currentContourPoint = filteredContours[y][0];
            
            if(cv::pointPolygonTest(filteredContours[x], currentContourPoint, false) >= 0)
            {
                // it is inside
                [evictedIndexes addObject:[NSNumber numberWithInt:y]];
            }
        }
    }
    
    std::vector<std::vector<cv::Point>> secondPassFilteredContours;
    for ( int x = 0; x< filteredContours.size(); x++ ) {
        if ([evictedIndexes containsObject:[NSNumber numberWithInt:x]]) {
            continue;
        }
        
        secondPassFilteredContours.push_back(filteredContours[x]);
    }
    
    //    NSLog(@"** Num. second-pass filtered items: %lu", secondPassFilteredContours.size());
    return secondPassFilteredContours;
}

+ (NSMutableArray*)reduceContoursToBoundingBox:(cv::vector<cv::Mat>)contours {
    NSMutableArray *boundingBoxImages = [NSMutableArray array];
    
    for (int i = 0; i < contours.size(); i++) {
        UIImage *extractedContour = [ImageHelper UIImageFromCVMat:contours[i]];
        
        // Make the black mask of the image transparent
        UIImage *originalImage = [extractedContour replaceColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f] withTolerance:0.0f];
        
        // Trim to the bounding box
        UIImage *trimmedImage = [originalImage imageByTrimmingTransparentPixels];
        
        // Rotate to find the smallest possible bounding box (minimum-area enclosing rectangle)
        UIImage *boundingBoxImage = [ImageHelper imageBoundingBox:trimmedImage];
        
        [boundingBoxImages addObject:boundingBoxImage];
    }
    
    return boundingBoxImages;
}

@end