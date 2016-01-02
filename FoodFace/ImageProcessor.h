//
//  ImageProcessor.h
//  FoodFace
//
//  Created by Aaron on 02/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@class ImageProcessorResult;

@interface ImageProcessor : NSObject

-(id)initWithImage:(UIImage*)image;

-(ImageProcessorResult*)prepareImage;
-(ImageProcessorResult*)findContours;
-(ImageProcessorResult*)filterContours;
-(ImageProcessorResult*)extractContourBoundingBoxImages;
-(ImageProcessorResult*)boundingBoxImagesToPolygons;
-(ImageProcessorResult*)placePolygonsOnTargetTemplate;

@end
