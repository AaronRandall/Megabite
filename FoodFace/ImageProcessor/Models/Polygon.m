//
//  Polygon.m
//  FoodFace
//
//  Created by Aaron Randall on 13/12/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import "Polygon.h"

@implementation Polygon

-(id)initWithImage:(UIImage*)image {
    self = [super init];
    if (self) {
        self.image = image;
        self.surfaceArea = image.size.height * image.size.width;
        self.centroidX = image.size.width / 2;
        self.centroidY = image.size.height / 2;
        self.shape = [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, image.size.width, image.size.height)];
    }
    return self;
}

-(id)initWithShape:(UIBezierPath*)shape {
    self = [super init];
    if (self) {
        self.shape = shape;
        self.surfaceArea = shape.bounds.size.height * shape.bounds.size.width;
        self.centroidX = shape.bounds.size.width / 2;
        self.centroidY = shape.bounds.size.height / 2;
        
        UIGraphicsBeginImageContextWithOptions(shape.bounds.size, NO, 0.0);
        [[UIColor redColor] set];
        UIRectFill(CGRectMake(0.0, 0.0, shape.bounds.size.width, shape.bounds.size.height));
        [self.shape fill];
        UIImage *shapeImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        self.image = shapeImage;
    }
    return self;
}


@end
