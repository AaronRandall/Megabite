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
#import "PolygonHelper.h"
#import "ImageProcessor.h"
#import "ImageProcessorResult.h"

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
    
    
    UIImage *inputImage = [UIImage imageNamed:@"FoodFace7"];
    ImageProcessor *processor = [[ImageProcessor alloc] initWithImage:inputImage];
    ImageProcessorResult *result = [ImageProcessorResult new];
    
    result = [processor prepareImage];
    result = [processor findContours];
    result = [processor filterContours];
    result = [processor extractContourBoundingBoxImages];
    result = [processor boundingBoxImagesToPolygons];
    result = [processor placePolygonsOnTargetTemplate];
    
    self.debugImageView5.image = result.results[0];
    
    NSLog(@"Processing complete");
    
    
//    
//    self.images = [NSMutableArray array];
//    self.imageIndex = 0;
//    
//    // Sample images: PlateFood, Plate, FoodPlate2, Breakfast, FoodFace2, FoodFace3, FoodFace4
//    UIImage *image = [UIImage imageNamed:@"FoodFace7"];
//    
//    // Crop the image to the plate dimensions
//    image = [ImageHelper roundedRectImageFromImage:image size:image.size withCornerRadius:image.size.height/2];
//    self.imageView.image = image;
//    
//    // Convert the image into a matrix
//    cv::Mat imageMatrixAll = [ImageHelper cvMatFromUIImage:image];
//    cv::Mat imageMatrixFiltered = [ImageHelper cvMatFromUIImage:image];
//    cv::Mat copyImageMatrix = [ImageHelper cvMatFromUIImage:image];
//
//    
//    
//    
//    
//    // Detect all contours within the image matrix, and filter for those that match detection criteria
//    std::vector<std::vector<cv::Point>> allContours = [ContourAnalyser findContoursInImage:imageMatrixAll];
//    std::vector<std::vector<cv::Point>> filteredContours = [ContourAnalyser filterContours:allContours];
//    
//    // Highlight the contours in the image
//    cv::Mat cvMatWithSquaresAll = [ImageHelper highlightContoursInImage:allContours image:imageMatrixAll];
//    cv::Mat cvMatWithSquaresFiltered = [ImageHelper highlightContoursInImage:filteredContours image:imageMatrixFiltered];
//    
//    // Convert the image matrix into an image
//    UIImage *highlightedImageAll = [ImageHelper UIImageFromCVMat:cvMatWithSquaresAll];
//    UIImage *highlightedImageFiltered = [ImageHelper UIImageFromCVMat:cvMatWithSquaresFiltered];
//    
//    self.outputImageView.image = highlightedImageFiltered;
//    self.outputImageViewAll.image = highlightedImageAll;
//    
//    // Extract highlighted contours
//    cv::vector<cv::Mat> extractedContours = [ImageHelper cutContoursFromImage:filteredContours image:copyImageMatrix];
//    
//    // Crop extracted contours to the size of the contour, and make background transparent
//    NSMutableArray *boundingBoxContours = [ContourAnalyser reduceContoursToBoundingBox:extractedContours];
//    
//    
//    
//    
//    
//    [self.images addObjectsFromArray:boundingBoxContours];
//    
//    if (self.images.count > 0) {
//        self.debugImageView1.image = self.images[0];
//    }
//    
//    // Construct Polygon objects from the extracted images
//    NSMutableArray *itemPolygons = [NSMutableArray array];
//    for (int i = 0; i < self.images.count; i++) {
//        Polygon *polygon = [[Polygon alloc] initWithImage:self.images[i]];
//        [itemPolygons addObject:polygon];
//    }
//    
//    // Get the bin Polygons based on the item Polygons we've extracted
//    NSArray *binPolygons = [PolygonHelper binPolygonsForTemplateBasedOnItemPolygons:itemPolygons];
//    
//    // Sort the polygons by surface area
//    NSArray *sortedBinPolygons = [PolygonHelper sortPolygonsBySurfaceArea:binPolygons];
//    NSArray *sortedItemPolygons = [PolygonHelper sortPolygonsBySurfaceArea:itemPolygons];
//    
//    UIImage *testImage = [UIImage imageNamed:@"EmptyPlate"];
//    
//    for (int i = 0; i < sortedBinPolygons.count; i++) {
//        Polygon *currentBinPolygon = sortedBinPolygons[i];
//        Polygon *currentItemPolygon = sortedItemPolygons[i];
//        
//        currentItemPolygon = [PolygonHelper rotatePolygonToCoverPolygon:currentItemPolygon bin:currentBinPolygon];
//        
//        // Add current item Polygon to the image at the bin Polygon position
//        testImage = [self addItemPolygon:currentItemPolygon toImage:testImage atBinPolygon:currentBinPolygon];
//    }
//    
//    self.debugImageView2.image = testImage;
//    self.debugImageView5.image = testImage;
//    
//    // Debug the bin layout
//    [self displayBinTemplateLayout:sortedBinPolygons usingSize:testImage.size];
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
