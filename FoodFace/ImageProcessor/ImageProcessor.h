//
//  ImageProcessor.h
//  FoodFace
//
//  Created by Aaron on 02/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

@class ImageProcessorResult;

@interface ImageProcessor : NSObject

- (id)initWithImage:(UIImage*)image;
- (ImageProcessorResult*)run:(NSDictionary*)options;

@end