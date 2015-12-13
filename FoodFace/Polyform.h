//
//  Polyform.h
//  FoodFace
//
//  Created by Aaron Randall on 13/12/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

@interface Polyform : NSObject

// Polyform
//   - Geometric shape (UIBezierPath)
//   - AppliedRotation
//   - SurfaceArea
//   - Origin (x,y)

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
