//
//  Polyform.m
//  FoodFace
//
//  Created by Aaron Randall on 13/12/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import "Polyform.h"

@implementation Polyform

-(id)initWithImage:(UIImage*)image {
    self = [super init];
    if (self) {
        self.image = image;
        self.surfaceArea = image.size.height * image.size.width;
    }
    return self;
}

-(id)initWithShape:(UIBezierPath*)shape {
    self = [super init];
    if (self) {
        self.shape = shape;
        self.surfaceArea = shape.bounds.size.height * shape.bounds.size.width;
    }
    return self;
}


@end
