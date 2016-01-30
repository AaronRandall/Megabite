//
//  Polygon.h
//  Megabite
//
//  Created by Aaron Randall on 13/12/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

@interface Polygon : NSObject

- (id)initWithImage:(UIImage*)image;
- (id)initWithShape:(UIBezierPath*)shape;

@property (strong, nonatomic) UIImage *image;
@property (strong, nonatomic) UIBezierPath *shape;
@property (assign, nonatomic) int surfaceArea;
@property (assign, nonatomic) int centroidX;
@property (assign, nonatomic) int centroidY;

@end