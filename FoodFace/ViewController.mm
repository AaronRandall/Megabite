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
#import "Polygon.h"
#import "UIImage+AverageColor.h"
#import "ContourAnalyser.h"
#import "ImageHelper.h"

@interface ViewController ()
    @property NSMutableArray *images;
    @property int imageIndex;
    @property float arcLengthMultiplier;
@end

@implementation ViewController {
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.arcLengthMultiplier = 0.02;
    
    [self convertImageToFoodFace];
}

- (void)convertImageToFoodFace {
    // TODO: resize input image to fixed size (1000x1000)
    // TODO: Crop image to largest possible circle
    // TODO: detect plate
    // TODO: fill extracted regions (holes) on plate
    // TODO: select template based on num. extracted contours
    // TODO: setup template with bins, bin centroid coordinates, bin surface areas, ordered by surface area (big to small)
    
    self.images = [NSMutableArray array];
    self.imageIndex = 0;
    
    // Sample images: PlateFood, Plate, FoodPlate2, Breakfast, FoodFace2, FoodFace3, FoodFace4
    UIImage *image = [UIImage imageNamed:@"FoodFace4"];
    
    // Crop the image to the plate dimensions
    image = [ImageHelper roundedRectImageFromImage:image size:image.size withCornerRadius:image.size.height/2];
    self.imageView.image = image;
    
    // Convert the image into a matrix
    cv::Mat imageMatrixAll = [ImageHelper cvMatFromUIImage:image];
    cv::Mat imageMatrixFiltered = [ImageHelper cvMatFromUIImage:image];
    cv::Mat copyImageMatrix = [ImageHelper cvMatFromUIImage:image];
    
    // Detect all contours within the image matrix, and filter for those that match detection criteria
    std::vector<std::vector<cv::Point>> allContours = [ContourAnalyser findContoursInImage:imageMatrixAll];
    std::vector<std::vector<cv::Point>> filteredContours = [ContourAnalyser filterContours:allContours];
    
    // Highlight the contours in the image
    cv::Mat cvMatWithSquaresAll = [ImageHelper highlightContoursInImage:allContours image:imageMatrixAll];
    cv::Mat cvMatWithSquaresFiltered = [ImageHelper highlightContoursInImage:filteredContours image:imageMatrixFiltered];
    
    // Convert the image matrix into an image
    UIImage *highlightedImageAll = [ImageHelper UIImageFromCVMat:cvMatWithSquaresAll];
    UIImage *highlightedImageFiltered = [ImageHelper UIImageFromCVMat:cvMatWithSquaresFiltered];
    
    self.outputImageView.image = highlightedImageFiltered;
    self.outputImageViewAll.image = highlightedImageAll;
    
    // Extract highlighted contours
    cv::vector<cv::Mat> extractedContours = [ImageHelper cutContoursFromImage:filteredContours image:copyImageMatrix];
    
    // Crop extracted contours to the size of the contour, and make background transparent
    NSMutableArray *boundingBoxContours = [ContourAnalyser reduceContoursToBoundingBox:extractedContours];
    
    [self.images addObjectsFromArray:boundingBoxContours];
    
    if (self.images.count > 0) {
        self.debugImageView1.image = self.images[0];
    }
    
    // Construct Polygon objects from the extracted images
    NSMutableArray *itemPolygons = [NSMutableArray array];
    for (int i = 0; i < self.images.count; i++) {
        Polygon *polygon = [[Polygon alloc] initWithImage:self.images[i]];
        [itemPolygons addObject:polygon];
    }
    
    // Get the bin Polygons based on the item Polygons we've extracted
    NSArray *binPolygons = [self binPolygonsForTemplateBasedOnItemPolygons:itemPolygons];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"surfaceArea" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedBinPolygons = [binPolygons sortedArrayUsingDescriptors:sortDescriptors];
    NSArray *sortedItemPolygons = [itemPolygons sortedArrayUsingDescriptors:sortDescriptors];
    
    UIImage *testImage = [UIImage imageNamed:@"EmptyPlateFood"];
    
    for (int i = 0; i < sortedBinPolygons.count; i++) {
        Polygon *currentBinPolygon = sortedBinPolygons[i];
        Polygon *currentItemPolygon = sortedItemPolygons[i];
        
        currentItemPolygon = [self rotatePolygonToCoverBin:currentItemPolygon bin:currentBinPolygon];
        
        // Add current item Polygon to the image at the bin Polygon position
        testImage = [self addItemPolygon:currentItemPolygon toImage:testImage atBinPolygon:currentBinPolygon];
    }
    
    self.debugImageView2.image = testImage;
    self.debugImageView5.image = testImage;
    
    // Debug the bin layout
    [self displayBinTemplateLayout:sortedBinPolygons usingSize:testImage.size];
}

- (Polygon*)rotatePolygonToCoverBin:(Polygon*)item bin:(Polygon*)bin {
    int smallestNumRedPixels = bin.shape.bounds.size.width * bin.shape.bounds.size.height;
    int optimalRotation = 0;
    
    for (int i = 0; i < 180; i++) {
        int redPixels = [self calculateSurfaceAreaCoverageForBin:bin item:item rotation:i];
        
        if (redPixels < smallestNumRedPixels) {
            smallestNumRedPixels = redPixels;
            optimalRotation = i;
        }
    }
    
    // NSLog(@"Optimal rotation:%d, Smallest num Red pixels: %d", optimalRotation, smallestNumRedPixels);
    
    [self calculateSurfaceAreaCoverageForBin:bin item:item rotation:optimalRotation];
    
    // Rotate the image and save it back to the Polygon
    UIImage *rotatedItemImage = [ImageHelper imageRotatedByDegrees:optimalRotation image:item.image];

    rotatedItemImage = [rotatedItemImage imageByTrimmingTransparentPixels];
    
    return [[Polygon alloc] initWithImage:rotatedItemImage];
}

- (int)calculateSurfaceAreaCoverageForBin:(Polygon*)bin item:(Polygon*)item rotation:(int)rotation {
    // --------------------------------------------------------------------
    // Debug overlay of bin and item
    //    CGPathRef path = createPathRotatedAroundBoundingBoxCenter(item.shape.CGPath, M_PI / 8);
    //    item.shape = [UIBezierPath bezierPathWithCGPath:path];
    
    // Rotate the UIBezierPath
    int degreesToRotate = rotation;
    UIBezierPath *copyOfItem = [item.shape copy];
    [copyOfItem applyTransform:CGAffineTransformMakeRotation([ImageHelper degreesToRadians:degreesToRotate])];
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
    
    NSUInteger numberOfRedPixels = [ImageHelper numberOfRedPixelsInImage:myImage];
    
    self.debugImageViewBin.image = bin.image;
    self.debugImageViewItem.image = [ImageHelper imageRotatedByDegrees:degreesToRotate image:item.image];
    self.debugImageView4.image = myImage;
    // --------------------------------------------------------------------
    
    return numberOfRedPixels;
}

- (void)displayBinTemplateLayout:(NSArray*)binPolygons usingSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    for (int i = 0; i < binPolygons.count; i++) {
        [((Polygon*)[binPolygons objectAtIndex:i]).shape fill];
    }
    
    UIImage *myImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.debugImageView3.image = myImage;
}

- (NSArray*)binPolygonsForTemplateBasedOnItemPolygons:(NSArray*)itemPolygons {
    NSMutableArray *binPolygons = [NSMutableArray array];
    
    // Left eye
    Polygon *leftEye = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(300, 200, 150, 150)]];
    // Right eye
    Polygon *rightEye = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(600, 200, 150, 150)]];
    // Nose
    Polygon *nose = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(450, 450, 100, 100)]];
    // Mouth
    Polygon *mouth = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(300, 650, 400, 200)]];
    // Left ear
    Polygon *leftEar = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(50, 300, 100, 200)]];
    // Right ear
    Polygon *rightEar = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(850, 300, 100, 200)]];
    
    if (itemPolygons.count == 3) {
        [binPolygons addObject:leftEye];
        [binPolygons addObject:rightEye];
        [binPolygons addObject:mouth];
    } else if (itemPolygons.count >= 4 &&
               itemPolygons.count <= 5) {
        [binPolygons addObject:leftEye];
        [binPolygons addObject:rightEye];
        [binPolygons addObject:mouth];
        [binPolygons addObject:nose];
    } else if (itemPolygons.count >= 6) {
        [binPolygons addObject:leftEye];
        [binPolygons addObject:rightEye];
        [binPolygons addObject:mouth];
        [binPolygons addObject:nose];
        [binPolygons addObject:leftEar];
        [binPolygons addObject:rightEar];
    }
    
    return binPolygons;
}

- (UIImage*)addItemPolygon:(Polygon*)itemPolygon toImage:(UIImage*)image atBinPolygon:(Polygon*)binPolygon {
    CGSize size = CGSizeMake(1000, 1000);
    UIGraphicsBeginImageContext(size);
    
    CGPoint background = CGPointMake(0, 0);
    [image drawAtPoint:background];
    
    UIImage *item = itemPolygon.image;
    
    double pointX = (binPolygon.shape.bounds.origin.x + binPolygon.centroidX) - itemPolygon.centroidX;
    double pointY = (binPolygon.shape.bounds.origin.y + binPolygon.centroidY) - itemPolygon.centroidY;
    
    CGPoint itemPoint = CGPointMake(pointX, pointY);
    [item drawAtPoint:itemPoint];
    
    UIImage* result = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return result;
}

- (IBAction)nextButton:(id)sender {
    self.imageIndex++;
    int currentIndex = self.imageIndex % self.images.count;
    UIImage *currentImage = [self.images objectAtIndex:currentIndex];
    self.debugImageView1.image = currentImage;
}

- (IBAction)run:(id)sender {
    self.arcLengthMultiplier = [self.arcLengthTextField.text floatValue];
    [self convertImageToFoodFace];
}

@end
