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
    self.imageView.image = [UIImage imageNamed:@"PlateFood"];
    
    UIImage *image = [UIImage imageNamed:@"PlateFood"];
    cv::Mat cvMat = [self cvMatFromUIImage:image];
    
    std::vector<std::vector<cv::Point> > squares;
    squares = [self findSquaresInImage:cvMat];
    cv::Mat cvMatWithSquares = [self debugSquares:squares image:cvMat];
    
    UIImage *squaredImage = [self UIImageFromCVMat:cvMatWithSquares];
    NSLog(@"");
    
    self.outputImageView.image = squaredImage;
    
//    //cv:IplImage iplImage = *[self createIplImageFromUIImage:image];
//    NSLog(@"Here");
//    
//    //std::vector<std::vector<cv::Point>> ;
//    //cv::findContours(iplImage, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
//    
//    
//    cv::Mat canny_output;
//    cv::vector<cv::vector<Point> > contours;
//    cv::vector<cv::Vec4i> hierarchy;
//    
//    /// Detect edges using canny
//    //Canny( src_gray, canny_output, thresh, thresh*2, 3 );
//    /// Find contours
//    
//   // cv::findContours( iplImage, contours, hierarchy, CV_RETR_TREE, CV_CHAIN_APPROX_SIMPLE, nil );
//    
//    cv::Mat bwImage;
//    cv::cvtColor(cvMat, bwImage, CV_RGB2GRAY);
////    vector< vector<cv::Point> > contours;
//    
//    cv::findContours(bwImage, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
//    
//    for( size_t i = 0; i < contours.size(); i++ )
//    {
//        NSLog(@"In here");
//    }
}

- (std::vector<std::vector<cv::Point> >)findSquaresInImage:(cv::Mat)_image
{
    std::vector<std::vector<cv::Point> > squares;
    cv::Mat pyr, timg, gray0(_image.size(), CV_8U), gray;
    int thresh = 50, N = 11;
    cv::pyrDown(_image, pyr, cv::Size(_image.cols/2, _image.rows/2));
    cv::pyrUp(pyr, timg, _image.size());
    std::vector<std::vector<cv::Point> > contours;
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
            cv::findContours(gray, contours, CV_RETR_LIST, CV_CHAIN_APPROX_SIMPLE);
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
                
                squares.push_back(contours[i]);
                
//                 if (approx.size() > 4)
//                 {
//                     // Detect and label circles
//                     double area = cv::contourArea(contours[i]);
//                     cv::Rect r = cv::boundingRect(contours[i]);
//                     int radius = r.width / 2;
//                     
//                     if (std::abs(1 - ((double)r.width / r.height)) <= 0.2 &&
//                         std::abs(1 - (area / (CV_PI * std::pow(radius, 2)))) <= 0.2)
//                     {
//                         squares.push_back(contours[i]);
//                     }
//                 } else {
//                    //squares.push_back(contours[i]);
//                }
                
                //cv::approxPolyDP(cv::Mat(contours[i]), approx, arcLength(cv::Mat(contours[i]), true)*0.02, true);
                //squares.push_back(approx);
                
//                if( approx.size() == 4 && fabs(contourArea(cv::Mat(approx))) > 1000 && cv::isContourConvex(cv::Mat(approx))) {
//                    double maxCosine = 0;
//                    
//                    for( int j = 2; j < 5; j++ )
//                    {
//                        //double cosine = fabs(angle(approx[j%4], approx[j-2], approx[j-1]));
//                        //maxCosine = MAX(maxCosine, cosine);
//                    }
//                    
//                    if( maxCosine < 0.3 ) {
//                        NSLog(@"found edge detection");
//                        squares.push_back(approx);
//                    }
//                }
            }
        }
    }
 
    return squares;
}

- (cv::Mat)debugSquares:(std::vector<std::vector<cv::Point> >)squares image:(cv::Mat)image
{
//    NSMutableArray *evictedIndexes = [NSMutableArray array];
    
    NSMutableSet *evictedIndexes = [NSMutableSet set];
    
    std::vector<std::vector<cv::Point>> filtered;
    
    for ( int x = 0; x< squares.size(); x++ ) {
        for ( int y = 0; y< squares.size(); y++ ) {
            if (y <= x) {
                continue;
            }
            
            // 0 == perfect match
            double result = cv::matchShapes(squares[x], squares[y], 1, 1);
            NSLog(@"Comparison result: %f", result);
//            if (result <= 0.5) {
//                [evictedIndexes addObject:[NSNumber numberWithInt:y]];
//            }
            
            cv::Rect boundingRectX = cv::boundingRect(squares[x]);
            cv::Rect boundingRectY = cv::boundingRect(squares[y]);

            if ((std::fabs(boundingRectX.x - boundingRectY.x) < 25.0f) && (std::fabs(boundingRectX.y - boundingRectY.y) < 25.0f)) {
                NSLog(@"** removing item (x,x)(y,y): (%d,%d),(%d,%d)", boundingRectX.x, boundingRectY.x, boundingRectX.y, boundingRectY.y);
                [evictedIndexes addObject:[NSNumber numberWithInt:y]];
            }
        }
    }
    
    // TODO: Evict contours which are inside other similar contours (e.g. carrot)
    
    for ( int x = 0; x< squares.size(); x++ ) {
        if ([evictedIndexes containsObject:[NSNumber numberWithInt:x]]) {
            continue;
        }
        
        filtered.push_back(squares[x]);
    }
    
    NSLog(@"** Num. filtered items: %lu", filtered.size());
    
    for ( int i = 0; i< filtered.size(); i++ ) {
        // draw contour
        cv::drawContours(image, filtered, i, cv::Scalar(255,0,0), 3, 8, std::vector<cv::Vec4i>(), 0, cv::Point());
        
        std::vector<cv::Point> currentSquare = filtered[i];
        
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
