//
//  ViewController.m
//  FoodFace
//
//  Created by Aaron on 27/10/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIImage *image = [UIImage imageNamed:@"PlateFood"];
    
    self.imageView.image = image;
    
    // Convert the image into a matrix
    cv::Mat imageMatrix = [self cvMatFromUIImage:image];
    
    // Detect all contours within the image matrix
    std::vector<std::vector<cv::Point>> contours = [self findContoursInImage:imageMatrix];
    
    // Filter contours for those that match detection criteria
    std::vector<std::vector<cv::Point>> filteredContours = [self filterContours:contours];
    
    // Highlight the contours in the image
    cv::Mat cvMatWithSquares = [self highlightContoursInImage:filteredContours image:imageMatrix];
    
    // Convert the image matrix into an image
    UIImage *squaredImage = [self UIImageFromCVMat:cvMatWithSquares];
    
    self.outputImageView.image = squaredImage;
}

- (std::vector<std::vector<cv::Point>>)findContoursInImage:(cv::Mat)image
{
    std::vector<std::vector<cv::Point>> validContours;
    cv::Mat pyr, timg, gray0(image.size(), CV_8U), gray;
    int thresh = 50, N = 11;
    cv::pyrDown(image, pyr, cv::Size(image.cols/2, image.rows/2));
    cv::pyrUp(pyr, timg, image.size());
    std::vector<std::vector<cv::Point>> contours;
    cv::vector<cv::Vec4i> hierarchy;
    
    for( int c = 0; c < 3; c++ ) {
        int ch[] = {c, 0};
        mixChannels(&timg, 1, &gray0, 1, ch, 1);
        for( int l = 0; l < N; l++ ) {
            if( l == 0 ) {
                cv::Canny(gray0, gray, 0, thresh, 3);
                cv::dilate(gray, gray, cv::Mat(), cv::Point(-1,-1));
            }
            else {
                gray = gray0 >= (l+1)*255/N;
            }
            cv::findContours(gray, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE);
            
            // hierarchy is ordered as: [Next, Previous, First_Child, Parent]
            
            std::vector<cv::Point> approx;
            for( size_t i = 0; i < contours.size(); i++ )
            {
                cv::approxPolyDP(cv::Mat(contours[i]),
                                 approx,
                                 cv::arcLength(cv::Mat(contours[i]), true) * 0.02,
                                 true
                                 );
                
                // Skip small or non-convex objects 
                if (std::fabs(cv::contourArea(contours[i])) < 1000 || !cv::isContourConvex(approx) || fabs(contourArea(cv::Mat(contours[i]))) > 50000)
                    continue;
                
                NSLog(@"Sides: %lu", approx.size());
                NSLog(@"Size: %f", fabs(contourArea(cv::Mat(contours[i]))));
                
                validContours.push_back(contours[i]);
            }
        }
    }
 
    return validContours;
}

- (std::vector<std::vector<cv::Point>>)filterContours:(std::vector<std::vector<cv::Point>>)contours
{
    NSMutableSet *evictedIndexes = [NSMutableSet set];
    
    std::vector<std::vector<cv::Point>> filteredContours;
    
    for ( int x = 0; x< contours.size(); x++ ) {
        for ( int y = 0; y< contours.size(); y++ ) {
            if (y <= x) {
                continue;
            }
            
            // 0 == perfect match
            double result = cv::matchShapes(contours[x], contours[y], 1, 1);
            NSLog(@"Comparison result: %f", result);
            //if (result <= 0.5) {
            //    [evictedIndexes addObject:[NSNumber numberWithInt:y]];
            //}
            
            cv::Rect boundingRectX = cv::boundingRect(contours[x]);
            cv::Rect boundingRectY = cv::boundingRect(contours[y]);
            
            // Evict contours that are similar in bounds to the current contour
            if ((std::fabs(boundingRectX.x - boundingRectY.x) < 25.0f) && (std::fabs(boundingRectX.y - boundingRectY.y) < 25.0f)) {
                NSLog(@"** removing item (x,x)(y,y): (%d,%d),(%d,%d)", boundingRectX.x, boundingRectY.x, boundingRectX.y, boundingRectY.y);
                [evictedIndexes addObject:[NSNumber numberWithInt:y]];
            }
        }
    }
    
    // TODO: Evict contours which are inside other similar contours (e.g. carrot)
    // http://stackoverflow.com/questions/8508096/how-to-check-if-one-contour-is-nested-embedded-in-opencv
    
    for ( int x = 0; x< contours.size(); x++ ) {
        if ([evictedIndexes containsObject:[NSNumber numberWithInt:x]]) {
            continue;
        }
        
        filteredContours.push_back(contours[x]);
    }

    NSLog(@"** Num. filtered items: %lu", filteredContours.size());
    
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
                NSLog(@"");
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
    
    NSLog(@"** Num. second-pass filtered items: %lu", secondPassFilteredContours.size());
    return secondPassFilteredContours;
}

- (cv::Mat)highlightContoursInImage:(std::vector<std::vector<cv::Point>>)contours image:(cv::Mat)image
{
    for ( int i = 0; i< contours.size(); i++ ) {
        // draw contour
        cv::drawContours(image, contours, i, cv::Scalar(255,0,0), 3, 8, std::vector<cv::Vec4i>(), 0, cv::Point());
        
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (cv::Mat)cvMatFromUIImage:(UIImage *)image
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

-(UIImage *)UIImageFromCVMat:(cv::Mat)cvMat
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

- (IplImage *)createIplImageFromUIImage:(UIImage *)image {
    // Getting CGImage from UIImage
    CGImageRef imageRef = image.CGImage;
    
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    // Creating temporal IplImage for drawing
    IplImage *iplimage = cvCreateImage(
                                       cvSize(image.size.width,image.size.height), IPL_DEPTH_8U, 4
                                       );
    // Creating CGContext for temporal IplImage
    CGContextRef contextRef = CGBitmapContextCreate(
                                                    iplimage->imageData, iplimage->width, iplimage->height,
                                                    iplimage->depth, iplimage->widthStep,
                                                    colorSpace, kCGImageAlphaPremultipliedLast|kCGBitmapByteOrderDefault
                                                    );
    // Drawing CGImage to CGContext
    CGContextDrawImage(
                       contextRef,
                       CGRectMake(0, 0, image.size.width, image.size.height),
                       imageRef
                       );
    CGContextRelease(contextRef);
    CGColorSpaceRelease(colorSpace);
    
    // Creating result IplImage
    IplImage *ret = cvCreateImage(cvGetSize(iplimage), IPL_DEPTH_8U, 3);
    cvCvtColor(iplimage, ret, CV_RGBA2BGR);
    cvReleaseImage(&iplimage);
    
    return ret;
}

@end
