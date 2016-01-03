//
//  PolygonHelper.m
//  FoodFace
//
//  Created by Aaron on 02/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import "PolygonHelper.h"
#import "Polygon.h"
#import "UIImage+Trim.h"
#import "ImageHelper.h"

@implementation PolygonHelper

+ (NSArray*)binPolygonsForTemplateBasedOnItemPolygons:(NSArray*)itemPolygons {
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

+ (NSArray*)sortPolygonsBySurfaceArea:(NSArray*)polygons {
    NSSortDescriptor *sortDescriptor;
    sortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"surfaceArea" ascending:NO];
    NSArray *sortDescriptors = [NSArray arrayWithObject:sortDescriptor];
    
    return [polygons sortedArrayUsingDescriptors:sortDescriptors];
}

+ (Polygon*)rotatePolygonToCoverPolygon:(Polygon*)item bin:(Polygon*)bin {
    int smallestNumRedPixels = bin.shape.bounds.size.width * bin.shape.bounds.size.height;
    int optimalRotation = 0;
    
    for (int i = 0; i < 6; i++) {
        int degrees = i * 30;
        int redPixels = [self calculateSurfaceAreaCoverageForBin:bin item:item rotation:degrees];
        
        if (redPixels < smallestNumRedPixels) {
            smallestNumRedPixels = redPixels;
            optimalRotation = degrees;
        }
    }
    
    // NSLog(@"Optimal rotation:%d, Smallest num Red pixels: %d", optimalRotation, smallestNumRedPixels);
    
    [self calculateSurfaceAreaCoverageForBin:bin item:item rotation:optimalRotation];
    
    // Rotate the image and save it back to the Polygon
    UIImage *rotatedItemImage = [ImageHelper imageRotatedByDegrees:optimalRotation image:item.image];
    
    rotatedItemImage = [rotatedItemImage imageByTrimmingTransparentPixels];
    
    return [[Polygon alloc] initWithImage:rotatedItemImage];
}

+ (int)calculateSurfaceAreaCoverageForBin:(Polygon*)bin item:(Polygon*)item rotation:(int)rotation {
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
    
//    self.debugImageViewBin.image = bin.image;
//    self.debugImageViewItem.image = [ImageHelper imageRotatedByDegrees:degreesToRotate image:item.image];
//    self.debugImageView4.image = myImage;
    // --------------------------------------------------------------------
    
    return numberOfRedPixels;
}

+ (UIImage*)addItemPolygon:(Polygon*)itemPolygon toImage:(UIImage*)image atBinPolygon:(Polygon*)binPolygon {
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

////    // Debug the bin layout
////    [self displayBinTemplateLayout:sortedBinPolygons usingSize:testImage.size];
//- (void)displayBinTemplateLayout:(NSArray*)binPolygons usingSize:(CGSize)size {
//    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
//
//    for (int i = 0; i < binPolygons.count; i++) {
//        [((Polygon*)[binPolygons objectAtIndex:i]).shape fill];
//    }
//
//    UIImage *myImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//
//    self.debugImageView3.image = myImage;
//}

@end
