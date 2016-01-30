//
//  AnimationHelper.m
//  FoodFace
//
//  Created by Aaron Randall on 16/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import "AnimationHelper.h"
#import <pop/POP.h>

@implementation AnimationHelper

+ (void)runPopAnimationsForImages:(NSArray*)images imageView:(UIImageView*)imageView {
    for (int i = 0; i < images.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i/2.f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            imageView.image = images[i];
            POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
            spring.fromValue = [NSValue valueWithCGSize:CGSizeMake(0.98, 0.98)];
            spring.toValue = [NSValue valueWithCGSize:CGSizeMake(1.03, 1.03)];
            spring.springBounciness = 20;
            spring.springSpeed = 5;
            NSString *animationId = [NSString stringWithFormat:@"animation%i",arc4random_uniform(100)];
            [imageView.layer pop_addAnimation:spring forKey:animationId];
        });
    }
}

+ (void)runSpinAnimationsForImages:(NSArray*)images outputImage:(UIImage*)outputImage outputImageView:(UIImageView*)outputImageView animatedImageView:(UIImageView*)animatedImageView debugImageView:(UIImageView*)debugImageView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (images.count/2.f * NSEC_PER_SEC) + (1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        outputImageView.image = nil;
        animatedImageView.image = nil;
        
        outputImageView.alpha = 0;
        [UIView animateWithDuration:5.0 animations:^(void) {
            outputImageView.alpha = 1;
        }];
        
        // Spin the cropped input image
        CABasicAnimation* spinAnimationOriginal = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        spinAnimationOriginal.toValue = [NSNumber numberWithFloat:10*M_PI];
        spinAnimationOriginal.duration = 5;
        spinAnimationOriginal.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        spinAnimationOriginal.removedOnCompletion = YES;
        spinAnimationOriginal.fillMode = kCAFillModeForwards;
        [debugImageView.layer addAnimation:spinAnimationOriginal forKey:@"spinAnimationOriginal"];
        
        
        outputImageView.image = outputImage;
        
        // Spin the output image
        CABasicAnimation* spinAnimationNew = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        spinAnimationNew.toValue = [NSNumber numberWithFloat:10*M_PI];
        spinAnimationNew.duration = 5;
        spinAnimationNew.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        spinAnimationNew.removedOnCompletion = YES;
        spinAnimationNew.fillMode = kCAFillModeForwards;
        
        [outputImageView.layer addAnimation:spinAnimationNew forKey:@"allMyAnimations"];
    });
}

@end