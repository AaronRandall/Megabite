//
//  AnimationHelper.m
//  Megabite
//
//  Created by Aaron Randall on 16/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import "AnimationHelper.h"
#import <pop/POP.h>

float const delayBetweenAnimations = 2.0f;
float const spinAnimationDuration = 5.0f;
float const popAnimationSizeDelta = 0.03f;

@implementation AnimationHelper

+ (void)runPopAnimationsForImages:(NSArray*)images imageView:(UIImageView*)imageView {
    for (int i = 0; i < images.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i/delayBetweenAnimations * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            imageView.image = images[i];
            POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
            spring.fromValue = [NSValue valueWithCGSize:CGSizeMake(1 - popAnimationSizeDelta, 1 - popAnimationSizeDelta)];
            spring.toValue = [NSValue valueWithCGSize:CGSizeMake(1.f + popAnimationSizeDelta, 1 + popAnimationSizeDelta)];
            spring.springBounciness = 20;
            spring.springSpeed = 5;
            NSString *animationId = [NSString stringWithFormat:@"animation%i",arc4random_uniform(100)];
            [imageView.layer pop_addAnimation:spring forKey:animationId];
        });
    }
}

+ (void)runSpinAnimationsForImages:(NSArray*)images outputImage:(UIImage*)outputImage outputImageView:(UIImageView*)outputImageView animatedImageView:(UIImageView*)animatedImageView croppedImageView:(UIImageView*)croppedImageView {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (images.count/delayBetweenAnimations * NSEC_PER_SEC) + (1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        outputImageView.image = nil;
        animatedImageView.image = nil;
        
        outputImageView.image = outputImage;
        
        outputImageView.alpha = 0;
        [UIView animateWithDuration:spinAnimationDuration animations:^(void) {
            outputImageView.alpha = 1;
        }];
        
        // Spin the cropped input image
        NSString *transformRotationKey = @"transform.rotation";
        CABasicAnimation* inputImageSpinAnimation = [CABasicAnimation animationWithKeyPath:transformRotationKey];
        inputImageSpinAnimation.toValue = [NSNumber numberWithFloat:10*M_PI];
        inputImageSpinAnimation.duration = spinAnimationDuration;
        inputImageSpinAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        inputImageSpinAnimation.removedOnCompletion = YES;
        inputImageSpinAnimation.fillMode = kCAFillModeForwards;
        [croppedImageView.layer addAnimation:inputImageSpinAnimation forKey:@"inputImageSpinAnimation"];
        
        // Spin the output image
        CABasicAnimation* outputImageSpinAnimation = [CABasicAnimation animationWithKeyPath:transformRotationKey];
        outputImageSpinAnimation.toValue = [NSNumber numberWithFloat:10*M_PI];
        outputImageSpinAnimation.duration = spinAnimationDuration;
        outputImageSpinAnimation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        outputImageSpinAnimation.removedOnCompletion = YES;
        outputImageSpinAnimation.fillMode = kCAFillModeForwards;
        [outputImageView.layer addAnimation:outputImageSpinAnimation forKey:@"outputImageSpinAnimation"];
    });
}

@end