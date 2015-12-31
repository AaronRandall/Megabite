//
//  ViewController.m
//  FoodFace
//
//  Created by Aaron on 27/10/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import "ViewController.h"
#import <opencv2/opencv.hpp>
#import "UIImage+Trim.h"
#import "Polyform.h"

@interface ViewController ()
    @property NSMutableArray *images;
    @property int imageIndex;
    @property float arcLengthMultiplier;
@end

@implementation ViewController {
}

#define DEGREES_TO_RADIANS(x) (M_PI * (x) / 180.0)

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.arcLengthMultiplier = 0.02;
    
    [self convertImageToFoodFace];
}

- (UIImage*)roundedRectImageFromImage:(UIImage *)image
                                size:(CGSize)imageSize
                    withCornerRadius:(float)cornerRadius
{
    UIGraphicsBeginImageContextWithOptions(imageSize, NO, image.scale);
    CGRect bounds=(CGRect){CGPointZero,imageSize};
    [[UIBezierPath bezierPathWithRoundedRect:bounds
                                cornerRadius:cornerRadius] addClip];
    [image drawInRect:bounds];
    UIImage *finalImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return finalImage;
}

- (void)convertImageToFoodFace {
    self.images = [NSMutableArray array];
    self.imageIndex = 0;
    
    // TODO: resize input image to fixed size (1000x1000)
    // TODO: Crop image to largest possible circle
    
    // PlateFood, Plate, FoodPlate2, Breakfast, FoodFace2, FoodFace3, FoodFace4 (0.03)
    UIImage *image = [UIImage imageNamed:@"FoodFace4"];
    
    image = [self roundedRectImageFromImage:image size:image.size withCornerRadius:image.size.height/2];
    
    self.imageView.image = image;
    
    // Convert the image into a matrix
    cv::Mat imageMatrixAll = [self cvMatFromUIImage:image];
    cv::Mat imageMatrixFiltered = [self cvMatFromUIImage:image];
    cv::Mat copyImageMatrix = [self cvMatFromUIImage:image];
    
    // Detect all contours within the image matrix
    std::vector<std::vector<cv::Point>> allContours = [self findContoursInImage:imageMatrixAll];
    
    // Filter contours for those that match detection criteria
    std::vector<std::vector<cv::Point>> filteredContours = [self filterContours:allContours];
    
    // Highlight the contours in the image
    cv::Mat cvMatWithSquaresAll = [self highlightContoursInImage:allContours image:imageMatrixAll];
    cv::Mat cvMatWithSquaresFiltered = [self highlightContoursInImage:filteredContours image:imageMatrixFiltered];
    
    // Convert the image matrix into an image
    UIImage *highlightedImageAll = [self UIImageFromCVMat:cvMatWithSquaresAll];
    UIImage *highlightedImageFiltered = [self UIImageFromCVMat:cvMatWithSquaresFiltered];
    
    self.outputImageView.image = highlightedImageFiltered;
    self.outputImageViewAll.image = highlightedImageAll;
    
    // Extract highlighted contours
    cv::vector<cv::Mat> extractedContours = [self cutContoursFromImage:filteredContours image:copyImageMatrix];
    
    // Crop extracted contours to the size of the contour, and make background transparent
    for (int i = 0; i < extractedContours.size(); i++) {
        UIImage *extractedContour = [self UIImageFromCVMat:extractedContours[i]];
        
        // Make the black mask of the image transparent
        UIImage *originalImage = [extractedContour replaceColor:[UIColor colorWithRed:0.0f green:0.0f blue:0.0f alpha:1.0f] withTolerance:0.0f];
        
        //        NSLog(@"*** 1: %f, %f", originalImage.size.width, originalImage.size.height);
        
        // Trim to the bounding box
        UIImage *trimmedImage = [originalImage imageByTrimmingTransparentPixels];
        
        //        NSLog(@"*** 2: %f, %f", trimmedImage.size.width, trimmedImage.size.height);
        
        // Rotate to find the smallest possible bounding box (minimum-area enclosing rectangle)
        UIImage *boundingBoxImage = [self imageBoundingBox:trimmedImage];
        
        //        NSLog(@"*** 3: %f, %f", boundingBoxImage.size.width, boundingBoxImage.size.height);
        
        
        // TODO: filter extracted contours for anomalies (all white, all black, etc)
        // Could consider removing anything that has an average colour ~= to plate average colour after extracting all contours from the plate
        
        [self.images addObject:boundingBoxImage];
    }
    
    
    
    
    // DEBUG
    //return;
    
    if (self.images.count > 0) {
        self.debugImageView1.image = self.images[0];
    }
    
    // TODO: detect plate
    // TODO: fill extracted regions (holes) on plate
    
    
    // Construct polyform objects from the extracted images
    NSMutableArray *itemPolyforms = [NSMutableArray array];
    for (int i = 0; i < self.images.count; i++) {
        Polyform *polyform = [[Polyform alloc] initWithImage:self.images[i]];
        [itemPolyforms addObject:polyform];
    }
    
    
    // TODO: select template based on num. extracted contours
    // TODO: setup template with bins, bin centroid coordinates, bin surface areas, ordered by surface area (big to small)
    
    // Get the bin polyforms based on the item polyforms we've extracted
    NSArray *binPolyforms = [self binPolyformsForTemplateBasedOnItemPolyforms:itemPolyforms];
    
    // TODO: calculate item centroid coordinates, surface areas, ordered by surface area (big to small)
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"surfaceArea"
                                                 ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedBinPolyforms = [binPolyforms sortedArrayUsingDescriptors:sortDescriptors];
    NSArray *sortedItemPolyforms = [itemPolyforms sortedArrayUsingDescriptors:sortDescriptors];
    
    
    // TODO: find optimum rotation for current bin & item combination
    
    UIImage *testImage = [UIImage imageNamed:@"EmptyPlateFood"];
    
    for (int i = 0; i < sortedBinPolyforms.count; i++) {
        Polyform *currentBinPolyform = sortedBinPolyforms[i];
        Polyform *currentItemPolyform = sortedItemPolyforms[i];
        
        currentItemPolyform = [self rotatePolyformToCoverBin:currentItemPolyform bin:currentBinPolyform];
        
        // Add current item polyform to the image at the bin polyform position
        testImage = [self addItemPolyform:currentItemPolyform toImage:testImage atBinPolyform:currentBinPolyform];
    }
    
    self.debugImageView2.image = testImage;
    self.debugImageView5.image = testImage;
    
    // Debug the bin layout
    [self displayBinTemplateLayout:sortedBinPolyforms usingSize:testImage.size];
}

- (Polyform*)rotatePolyformToCoverBin:(Polyform*)item bin:(Polyform*)bin {
    int smallestNumRedPixels = bin.shape.bounds.size.width * bin.shape.bounds.size.height;
    int optimalRotation = 0;
    
    for (int i = 0; i < 180; i++) {
        int redPixels = [self calculateSurfaceAreaCoverageForBin:bin item:item rotation:i];
//        NSLog(@"Rotation:%d, Red pixels: %d", i, redPixels);
        
        if (redPixels < smallestNumRedPixels) {
            smallestNumRedPixels = redPixels;
            optimalRotation = i;
        }
    }
    
//    NSLog(@"Optimal rotation:%d, Smallest num Red pixels: %d", optimalRotation, smallestNumRedPixels);
    
    [self calculateSurfaceAreaCoverageForBin:bin item:item rotation:optimalRotation];
    
    // Rotate the image and save it back to the polyform
    UIImage *rotatedItemImage = [self imageRotatedByDegrees:optimalRotation image:item.image];

    rotatedItemImage = [rotatedItemImage imageByTrimmingTransparentPixels];
    
    return [[Polyform alloc] initWithImage:rotatedItemImage];
}

- (int)calculateSurfaceAreaCoverageForBin:(Polyform*)bin item:(Polyform*)item rotation:(int)rotation {
    // --------------------------------------------------------------------
    // Debug overlay of bin and item
    //    CGPathRef path = createPathRotatedAroundBoundingBoxCenter(item.shape.CGPath, M_PI / 8);
    //    item.shape = [UIBezierPath bezierPathWithCGPath:path];
    
    // Rotate the UIBezierPath
    int degreesToRotate = rotation;
    UIBezierPath *copyOfItem = [item.shape copy];
    [copyOfItem applyTransform:CGAffineTransformMakeRotation(DEGREES_TO_RADIANS(degreesToRotate))];
    // Find the rotated path's bounding box
    CGRect boundingBox = CGPathGetPathBoundingBox(copyOfItem.CGPath);
    int rotatedCentroidX = boundingBox.size.width/2;
    int rotatedCentroidY = boundingBox.size.height/2;
    double pointX = bin.centroidX - rotatedCentroidX;
    double pointY = bin.centroidY - rotatedCentroidY;
    
    [copyOfItem applyTransform:CGAffineTransformMakeTranslation(pointX-(boundingBox.origin.x), pointY-(boundingBox.origin.y))];
    
    UIGraphicsBeginImageContextWithOptions(bin.shape.bounds.size, YES, 0.0);
    [[UIColor redColor] set]; // set the background color
    UIRectFill(CGRectMake(0.0, 0.0, bin.shape.bounds.size.width, bin.shape.bounds.size.height));
    [[UIColor blueColor] set];
    
    [copyOfItem fill];
    UIImage *myImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    NSUInteger numberOfRedPixels = [self processImage: myImage];
    
    self.debugImageViewBin.image = bin.image;
    self.debugImageViewItem.image = [self imageRotatedByDegrees:degreesToRotate image:item.image];
    self.debugImageView4.image = myImage;
    // --------------------------------------------------------------------
    
    return numberOfRedPixels;
}

struct pixel {
    unsigned char r, g, b, a;
};

/**
 * Process the image and return the number of pure red pixels in it.
 */

- (NSUInteger) processImage: (UIImage*) image
{
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
            
            while (numberOfPixels > 0) {
                if (pixels->r == 255) {
                    numberOfRedPixels++;
                }
                pixels++;
                numberOfPixels--;
            }
            
            CGContextRelease(context);
        }
        
        //free(pixels);
    }
    
    return numberOfRedPixels;
}

- (void)displayBinTemplateLayout:(NSArray*)binPolyforms usingSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    for (int i = 0; i < binPolyforms.count; i++) {
        [((Polyform*)[binPolyforms objectAtIndex:i]).shape fill];
    }
    
    UIImage *myImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.debugImageView3.image = myImage;
}

- (UIImage*)imageBoundingBox:(UIImage*)image {
    int boundingBoxRotation = 0;
    int smallestSurfaceArea = image.size.height * image.size.width;
    
    for (int i = 0; i < 180; i++) {
        // Rotate the image
        UIImage *tempImage = [self imageRotatedByDegrees:i image:image];
        
        // Trim to smallest box
        tempImage = [tempImage imageByTrimmingTransparentPixels];
        int currentSurfaceArea = (tempImage.size.height * tempImage.size.width);
        
        if (currentSurfaceArea < smallestSurfaceArea) {
            // The current rotation has a smaller surface area than the previous smallest surface area
            smallestSurfaceArea = currentSurfaceArea;
            boundingBoxRotation = i;
        }
        
        // Observe bounding box size
        //NSLog(@"Rotation: %d, SurfaceArea: %f (%f, %f)", i, (tempImage.size.width * tempImage.size.height),tempImage.size.width, tempImage.size.height);
    }
    
    UIImage *boundingBoxImage = [self imageRotatedByDegrees:boundingBoxRotation image:image];
    
    // Trim to smallest box
    boundingBoxImage = [boundingBoxImage imageByTrimmingTransparentPixels];
    
    return boundingBoxImage;
}

- (CGFloat)degreesToRadians:(CGFloat)degrees
{
    return degrees * M_PI / 180;
}

- (UIImage *)imageRotatedByDegrees:(CGFloat)degrees image:(UIImage*)image {
    CGFloat radians = [self degreesToRadians:degrees];
    
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

- (NSArray*)binPolyformsForTemplateBasedOnItemPolyforms:(NSArray*)itemPolyforms {
    NSMutableArray *binPolyforms = [NSMutableArray array];
    
    // Left eye
    Polyform *leftEye = [[Polyform alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(300, 200, 150, 150)]];
    // Right eye
    Polyform *rightEye = [[Polyform alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(600, 200, 150, 150)]];
    // Nose
    Polyform *nose = [[Polyform alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(450, 450, 100, 100)]];
    // Mouth
    Polyform *mouth = [[Polyform alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(300, 650, 400, 200)]];
    // Left ear
    Polyform *leftEar = [[Polyform alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(50, 300, 100, 200)]];
    // Right ear
    Polyform *rightEar = [[Polyform alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(850, 300, 100, 200)]];
    
    if (itemPolyforms.count == 3) {
        [binPolyforms addObject:leftEye];
        [binPolyforms addObject:rightEye];
        [binPolyforms addObject:mouth];
    } else if (itemPolyforms.count >= 4 &&
               itemPolyforms.count <= 5) {
        [binPolyforms addObject:leftEye];
        [binPolyforms addObject:rightEye];
        [binPolyforms addObject:mouth];
        [binPolyforms addObject:nose];
    } else if (itemPolyforms.count >= 6) {
        [binPolyforms addObject:leftEye];
        [binPolyforms addObject:rightEye];
        [binPolyforms addObject:mouth];
        [binPolyforms addObject:nose];
        [binPolyforms addObject:leftEar];
        [binPolyforms addObject:rightEar];
    }
    
    return binPolyforms;
}

- (UIImage*)addItemPolyform:(Polyform*)itemPolyform toImage:(UIImage*)image atBinPolyform:(Polyform*)binPolyform {
    CGSize size = CGSizeMake(1000, 1000);
    UIGraphicsBeginImageContext(size);
    
    CGPoint background = CGPointMake(0, 0);
    [image drawAtPoint:background];
    
    UIImage *item = itemPolyform.image;
    
    double pointX = (binPolyform.shape.bounds.origin.x + binPolyform.centroidX) - itemPolyform.centroidX;
    double pointY = (binPolyform.shape.bounds.origin.y + binPolyform.centroidY) - itemPolyform.centroidY;
    
    CGPoint itemPoint = CGPointMake(pointX, pointY);
    [item drawAtPoint:itemPoint];
    
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
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
                
                UIImage *greyImage = [self UIImageFromCVMat:gray];
                self.debugImageView6.image = greyImage;
            }
            else {
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
                                 cv::arcLength(cv::Mat(contours[i]), true) * self.arcLengthMultiplier,
                                 true
                                 );
                
                // Skip small or non-convex objects 
                if (std::fabs(cv::contourArea(contours[i])) < 2000
                    || !cv::isContourConvex(approx)
                    || fabs(contourArea(cv::Mat(contours[i]))) > 250000)
                    continue;
                
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
    
//    NSLog(@"** Num. second-pass filtered items: %lu", secondPassFilteredContours.size());
    return secondPassFilteredContours;
}

- (cv::vector<cv::Mat>)cutContoursFromImage:(std::vector<std::vector<cv::Point>>)contours image:(cv::Mat)image
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

- (cv::Mat)highlightContoursInImage:(std::vector<std::vector<cv::Point>>)contours image:(cv::Mat)image
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

- (IBAction)nextButton:(id)sender {
    self.imageIndex++;
    int currentIndex = self.imageIndex % self.images.count;
    UIImage *currentImage = [self.images objectAtIndex:currentIndex];
    self.debugImageView1.image = currentImage;
    NSLog(@"Height: %f, Width: %f", currentImage.size.height, currentImage.size.width);
}

- (IBAction)run:(id)sender {
    self.arcLengthMultiplier = [self.arcLengthTextField.text floatValue];
    [self convertImageToFoodFace];
}
@end
