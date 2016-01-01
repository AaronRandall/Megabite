//
//  Polygon.h
//  FoodFace
//
//  Created by Aaron Randall on 13/12/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Polygon : NSObject

-(id)initWithImage:(UIImage*)image;
-(id)initWithShape:(UIBezierPath*)shape;

@property UIImage *image;
@property UIBezierPath *shape;
@property int appliedRotation;
@property int surfaceArea;
@property int positionX;
@property int positionY;
@property int centroidX;
@property int centroidY;

@end
