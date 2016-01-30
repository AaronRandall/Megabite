//
//  AnimationHelper.h
//  Megabite
//
//  Created by Aaron Randall on 16/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface AnimationHelper : NSObject

+ (void)runPopAnimationsForImages:(NSArray*)images imageView:(UIImageView*)imageView;
+ (void)runSpinAnimationsForImages:(NSArray*)images outputImage:(UIImage*)outputImage outputImageView:(UIImageView*)outputImageView animatedImageView:(UIImageView*)animatedImageView debugImageView:(UIImageView*)debugImageView;

@end