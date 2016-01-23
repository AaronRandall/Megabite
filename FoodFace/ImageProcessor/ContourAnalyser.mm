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

static NSMutableArray* debugImages;

+ (NSMutableArray*)getDebugImages {
    return debugImages;
}

+ (void)addDebugImage:(UIImage*)debugImage {
    if (debugImages == nil) {
        debugImages = [NSMutableArray array];
    }
    
    [debugImages addObject:debugImage];
}

+ (std::vector<std::vector<cv::Point>>)findContoursInImage:(cv::Mat)image arcLengthMultiplier:(float)arcLengthMultiplier {
    debugImages = nil;
    
    int maxThresholdLevel = 11;
    int cannyThreshold = 50;
    bool skipNonConvexContours = YES;
    
    std::vector<std::vector<cv::Point>> validContours;
    
    cv::Mat downsampledImage;
    cv::pyrDown(image, downsampledImage, cv::Size(image.cols/2, image.rows/2));

    cv::Mat upsampledImage;
    cv::pyrUp(downsampledImage, upsampledImage, image.size());
    
    std::vector<std::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    cv::Mat imageFromChannel(image.size(), CV_8U);
    cv::Mat processedImage;
    
    [self addDebugImage:[ImageHelper UIImageFromCVMat:upsampledImage]];
    
    for( int colourPlane = 0; colourPlane < 3; colourPlane++ ) {
        int currentColourPlane[] = {colourPlane, 0};
        mixChannels(&upsampledImage, 1, &imageFromChannel, 1, currentColourPlane, 1);
        
        for( int thresholdLevel = 0; thresholdLevel < maxThresholdLevel; thresholdLevel++ ) {
            if( thresholdLevel == 0 ) {
                cv::Canny(imageFromChannel, processedImage, 0, cannyThreshold, 3);
                [self addDebugImage:[ImageHelper UIImageFromCVMat:processedImage]];
                
                cv::dilate(processedImage, processedImage, cv::Mat(), cv::Point(-1,-1));
                [self addDebugImage:[ImageHelper UIImageFromCVMat:processedImage]];
            }
            else {
                skipNonConvexContours = YES;
                processedImage = imageFromChannel >= (thresholdLevel+1)*255/maxThresholdLevel;
            }
            
            // Only record debug images for the first colour plane
            if (colourPlane == 0) {
                [self addDebugImage:[ImageHelper UIImageFromCVMat:processedImage]];
            }
            
            // Hierarchy is ordered as: [Next, Previous, First_Child, Parent]
            cv::findContours(processedImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
            
            std::vector<cv::Point> approx;
            for( size_t i = 0; i < contours.size(); i++ )
            {
                cv::approxPolyDP(cv::Mat(contours[i]),
                                 approx,
                                 cv::arcLength(cv::Mat(contours[i]), true) * arcLengthMultiplier,
                                 true
                                 );
                
                std::vector<cv::Point> currentContour = contours[i];
                cv::Rect x = cv::boundingRect(currentContour);
                
                if (x.width > 800 || x.height > 800) {
                    // Skipping contour due to width/height constraints
                    continue;
                }
                
                if (std::fabs(cv::contourArea(contours[i])) < 5000
                    || fabs(contourArea(cv::Mat(contours[i]))) > 250000) {
                    // Skipping contour due to surface area constraints
                    continue;
                }
                
                if (skipNonConvexContours && !cv::isContourConvex(approx)) {
                    // Skipping contour due to being non-convex
                    continue;
                }
                
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
            
            cv::Rect boundingRectX = cv::boundingRect(contours[x]);
            cv::Rect boundingRectY = cv::boundingRect(contours[y]);
            
            // Evict contours that are similar in bounds to the current contour
            if ((std::fabs(boundingRectX.x - boundingRectY.x) < 25.0f) && (std::fabs(boundingRectX.y - boundingRectY.y) < 25.0f)) {
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
    
    // Evict contours which are inside other similar contours
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
    
    return secondPassFilteredContours;
}

+ (NSMutableArray*)reduceContoursToBoundingBox:(cv::vector<cv::Mat>)contours maxNumPolygonRotations:(int)maxNumPolygonRotations {
    debugImages = nil;
    NSMutableArray *boundingBoxImages = [NSMutableArray array];
    
    for (int i = 0; i < contours.size(); i++) {
        UIImage *extractedContour = [ImageHelper UIImageFromCVMat:contours[i]];
        
        // Make the black mask of the image transparent
        UIImage *originalImage = [extractedContour replaceColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f] withTolerance:0.0f];
        
        [self addDebugImage:originalImage];
        
        // Trim to the bounding box
        UIImage *trimmedImage = [originalImage imageByTrimmingTransparentPixels];
        
        // Rotate to find the smallest possible bounding box (minimum-area enclosing rectangle)
        UIImage *boundingBoxImage = [ImageHelper imageBoundingBox:trimmedImage maxNumPolygonRotations:maxNumPolygonRotations];
        
        [boundingBoxImages addObject:boundingBoxImage];
    }
    
    return boundingBoxImages;
}

@end