//
//  Polygon.m
//  FoodFace
//
//  Created by Aaron Randall on 13/12/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import "Polygon.h"

@implementation Polygon

- (id)initWithImage:(UIImage*)image {
    self = [super init];
    if (self) {
        self.image = image;
        self.shape = [self shapeFromImage:image];
    }
    return self;
}

- (id)initWithShape:(UIBezierPath*)shape {
    self = [super init];
    if (self) {
        self.shape = shape;
        self.image = [self imageFromShape:shape];
    }
    return self;
}

- (int)surfaceArea {
    return self.shape.bounds.size.height * self.shape.bounds.size.width;
}

- (int)centroidX {
    return self.shape.bounds.size.width / 2;
}

- (int)centroidY {
    return self.shape.bounds.size.height / 2;
}

- (UIBezierPath*)shapeFromImage:(UIImage*)image {
    return [UIBezierPath bezierPathWithRect:CGRectMake(0, 0, image.size.width, image.size.height)];
}

- (UIImage*)imageFromShape:(UIBezierPath*)shape {
    UIBezierPath *filledShape = [UIBezierPath new];
    
    UIGraphicsBeginImageContextWithOptions(shape.bounds.size, NO, 0.0);
    [[UIColor redColor] set];
    UIRectFill(CGRectMake(0.0, 0.0, shape.bounds.size.width, shape.bounds.size.height));
    [filledShape fill];
    UIImage *shapeImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    return shapeImage;
}

@end