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
    
    // Define all available bins
    Polygon *leftEye = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(280, 200, 150, 150)]];
    Polygon *rightEye = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(580, 200, 150, 150)]];
    Polygon *nose = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(450, 450, 100, 100)]];
    Polygon *mouth = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(300, 650, 400, 200)]];
    Polygon *leftEar = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(50, 300, 100, 200)]];
    Polygon *rightEar = [[Polygon alloc] initWithShape:[UIBezierPath bezierPathWithRect:CGRectMake(850, 300, 100, 200)]];
    
    // Construct bin template layout based on the number of extracted items
    if (itemPolygons.count == 3) {
        [binPolygons addObject:leftEye];
        [binPolygons addObject:rightEye];
        [binPolygons addObject:mouth];
    } else if (itemPolygons.count > 3 &&
               itemPolygons.count <= 5) {
        [binPolygons addObject:leftEye];
        [binPolygons addObject:rightEye];
        [binPolygons addObject:mouth];
        [binPolygons addObject:nose];
    } else if (itemPolygons.count > 5) {
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

+ (Polygon*)rotatePolygonToCoverPolygon:(Polygon*)item bin:(Polygon*)bin maxNumPolygonRotations:(int)maxNumPolygonRotations {
    int smallestNumUncoveredPixels = bin.shape.bounds.size.width * bin.shape.bounds.size.height;
    int optimalRotation = 0;
    
    int maximumNumRotationsInDegrees = 180;
    
    for (int i = 0; i < maxNumPolygonRotations; i++) {
        int degrees = i * maximumNumRotationsInDegrees/maxNumPolygonRotations;
        int uncoveredBinPixels = [self calculateSurfaceAreaCoverageForBin:bin item:item rotation:degrees];
    
        if (uncoveredBinPixels == 0) {
            // If the entire bin surface is covered, don't attempt any other rotations
            break;
        }
        
        if (uncoveredBinPixels < smallestNumUncoveredPixels) {
            smallestNumUncoveredPixels = uncoveredBinPixels;
            optimalRotation = degrees;
        }
    }
    
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
    
    // Fill the bin polygon surface area in red
    [[UIColor redColor] set];
    UIRectFill(CGRectMake(0.0, 0.0, bin.shape.bounds.size.width, bin.shape.bounds.size.height));

    // Fill the item polygon surface area in blue
    [[UIColor blueColor] set];
    [copyOfItem fill];
    
    UIImage *binWithItemOverlayed = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    // Calculate the number of visible bin polygon pixels (from under the item polygon)
    NSUInteger numberOfVisibleBinPixels = [ImageHelper numberOfRedPixelsInImage:binWithItemOverlayed];
    
//    self.debugImageViewBin.image = bin.image;
//    self.debugImageViewItem.image = [ImageHelper imageRotatedByDegrees:degreesToRotate image:item.image];
//    self.debugImageView4.image = myImage;
    
    return (int)numberOfVisibleBinPixels;
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

+ (UIImage*)displayBinTemplateLayout:(NSArray*)binPolygons usingSize:(CGSize)size {
    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);

    for (int i = 0; i < binPolygons.count; i++) {
        [((Polygon*)[binPolygons objectAtIndex:i]).shape fill];
    }

    UIImage *binTemplateLayout = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();

    return binTemplateLayout;
}

@end