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
    
    // Construct polyform objects from the extracted images
    NSMutableArray *itemPolyforms = [NSMutableArray array];
    for (int i = 0; i < self.images.count; i++) {
        Polyform *polyform = [[Polyform alloc] initWithImage:self.images[i]];
        [itemPolyforms addObject:polyform];
    }
    
    // Get the bin polyforms based on the item polyforms we've extracted
    NSArray *binPolyforms = [self binPolyformsForTemplateBasedOnItemPolyforms:itemPolyforms];
    
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"surfaceArea" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    NSArray *sortedBinPolyforms = [binPolyforms sortedArrayUsingDescriptors:sortDescriptors];
    NSArray *sortedItemPolyforms = [itemPolyforms sortedArrayUsingDescriptors:sortDescriptors];
    
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
        
        if (redPixels < smallestNumRedPixels) {
            smallestNumRedPixels = redPixels;
            optimalRotation = i;
        }
    }
    
    // NSLog(@"Optimal rotation:%d, Smallest num Red pixels: %d", optimalRotation, smallestNumRedPixels);
    
    [self calculateSurfaceAreaCoverageForBin:bin item:item rotation:optimalRotation];
    
    // Rotate the image and save it back to the polyform
    UIImage *rotatedItemImage = [ImageHelper imageRotatedByDegrees:optimalRotation image:item.image];

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

- (void)displayBinTemplateLayout:(NSArray*)binPolyforms usingSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
    
    for (int i = 0; i < binPolyforms.count; i++) {
        [((Polyform*)[binPolyforms objectAtIndex:i]).shape fill];
    }
    
    UIImage *myImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    self.debugImageView3.image = myImage;
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

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
