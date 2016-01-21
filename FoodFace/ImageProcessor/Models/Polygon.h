//
//  Polygon.h
//  FoodFace
//
//  Created by Aaron Randall on 13/12/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

@interface Polygon : NSObject

- (id)initWithImage:(UIImage*)image;
- (id)initWithShape:(UIBezierPath*)shape;

@property UIImage *image;
@property UIBezierPath *shape;
@property (assign, nonatomic) int surfaceArea;
@property (assign, nonatomic) int centroidX;
@property (assign, nonatomic) int centroidY;

@end