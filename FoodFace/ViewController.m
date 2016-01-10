//
//  ViewController.m
//  FoodFace
//
//  Created by Aaron on 27/10/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import "ViewController.h"
#import "ImageProcessor.h"
#import "ImageProcessorResult.h"
#import <pop/POP.h>

@interface ViewController ()
@end

float const defaultArcMultiplier = 0.02;

/*
TODOS:
 - update ImageProcessor to return all useful images
 - optimise rotatePolygonToCoverPolygon to stop rotating if covered target surface area == target total surface area
    - investigate increasing the # supported rotations once this is done to see if the face can be better arranged
    - also investigate supporting tweaking this value from a user input
 - work out way to animate between all the different image types
 - last code cleanup
 - blog post
*/

@implementation ViewController {
    ImageProcessor *processor;
}

# pragma mark - Image processor

- (void)detectContoursInImage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        ImageProcessorResult *prepareImageResult = [processor prepareImage];
        ImageProcessorResult *findContoursResult = [processor findContours:[self.arcLengthMultiplierField.text floatValue]];
        ImageProcessorResult *filterContoursResult = [processor filterContours];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (findContoursResult.results.count > 0) {
                self.debugImageView.image = findContoursResult.results.firstObject;
                
                NSMutableArray *debugImages = [NSMutableArray arrayWithArray:findContoursResult.results];
                [debugImages addObjectsFromArray:filterContoursResult.images];
                [self runAnimationsForImages:debugImages];
            }
        });
    });
}

- (void)convertImageToFoodFace {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        ImageProcessorResult *extractContourBoundingBoxImagesResult = [processor extractContourBoundingBoxImages];
        ImageProcessorResult *boundingBoxImagesToPolygonsResult = [processor boundingBoxImagesToPolygons];
        ImageProcessorResult *placePolygonsOnTargetTemplateResult = [processor placePolygonsOnTargetTemplate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (placePolygonsOnTargetTemplateResult.results.count > 0) {
                self.outputImageView.image = placePolygonsOnTargetTemplateResult.results.firstObject;
                [self runPopAnimationsForImages:extractContourBoundingBoxImagesResult.images];
            }
        });
    });
}

- (void)runPopAnimationsForImages:(NSArray*)images {
    for (int i = 0; i < images.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i/2.f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            NSLog(@"Getting next animation");
            self.debugImageView.image = images[i];
            POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
            spring.fromValue = [NSValue valueWithCGSize:CGSizeMake(0.98, 0.98)];
            spring.toValue = [NSValue valueWithCGSize:CGSizeMake(1.03, 1.03)];
            spring.springBounciness = 20;
            spring.springSpeed = 1;
            NSString *animationId = [NSString stringWithFormat:@"animation%i",arc4random_uniform(100)];
            [self.debugImageView.layer pop_addAnimation:spring forKey:animationId];
        });
    }
}

- (void)runAnimationsForImages:(NSArray*)images {
    
    CAShapeLayer *circle = [CAShapeLayer layer];
    // Make a circular shape
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.debugImageView.frame.size.width, self.debugImageView.frame.size.height) cornerRadius:MAX(self.debugImageView.frame.size.width, self.debugImageView.frame.size.height)];
    
    circle.path = circularPath.CGPath;
    
    // Configure the appearance of the circle
    circle.fillColor = [UIColor blackColor].CGColor;
    circle.strokeColor = [UIColor blackColor].CGColor;
    circle.lineWidth = 0;
    
    self.debugImageView.layer.mask=circle;
    
    
    
    
    NSMutableArray* animationBlocks = [NSMutableArray new];
    
    typedef void(^animationBlock)(BOOL);
    
    animationBlock (^getNextAnimation)() = ^{
        animationBlock block = animationBlocks.count ? (animationBlock)animationBlocks[0] : nil;
        if (block) {
            [animationBlocks removeObjectAtIndex:0];
            return block;
        } else {
            return ^(BOOL finished){};
        }
    };
    
    // Add animations
    for (UIImage *image in images) {
        [animationBlocks addObject:^(BOOL finished){
            UIImage * toImage = image;
            [UIView transitionWithView:self.debugImageView
                              duration:0.25f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.debugImageView.image = toImage;
                            } completion:getNextAnimation()];
        }];
    }
    
    // Start the chain
    getNextAnimation()(YES);
    
    
    
    
    
    
    
    
    for (UIImage *image in images) {
//        self.debugImageView.image = image;
//        
//        CATransition *transition = [CATransition animation];
//        transition.duration = 1.0f;
//        transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//        transition.type = kCATransitionFade;
//        
//        [self.debugImageView.layer addAnimation:transition forKey:nil];
//        
        
        //self.debugImageView.image = image;
    }
    
//    POPSpringAnimation *sizeAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBounds];
//    sizeAnimation.springBounciness = 10;
//    if (self.inputImageView.bounds.size.width == 250) {
//        sizeAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width)];
//    }
//    
//    [sizeAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
//        if(finished){
//            NSLog(@"finished");
//            POPBasicAnimation *basicAnimation = [POPBasicAnimation animation];
//            basicAnimation.property = [POPAnimatableProperty propertyWithName:kPOPViewAlpha];
//            basicAnimation.toValue= @(1);
//            [self.outputImageView pop_addAnimation:basicAnimation forKey:@"basicAnimation"];
//        }
//    }];
//    
//    [self.inputImageView pop_addAnimation:sizeAnimation forKey:@"sizeAnimation"];
}

- (void)setImageForImageProcessor:(UIImage*)image {
    self.inputImageView.image = image;
    processor = [[ImageProcessor alloc] initWithImage:image];
}

- (void)setArcLengthTestFieldFromFloat:(float)value {
    self.arcLengthMultiplierField.text = [NSString stringWithFormat:@"%.3f",value];
    self.sensitivityStepper.value = value;
}

# pragma mark - IBActions

- (IBAction)takePhoto:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (IBAction)defaultPhoto:(id)sender {
    UIImage *defaultPhoto = [UIImage imageNamed:@"Food"];
    [self setImageForImageProcessor:defaultPhoto];
    [self detectContoursInImage];
}

- (IBAction)detectContours:(id)sender {
    [self detectContoursInImage];
}

- (IBAction)convertImage:(id)sender {
    [self convertImageToFoodFace];
}

- (IBAction)sensitivityStepperValueChanged:(id)sender {
    [self setArcLengthTestFieldFromFloat:self.sensitivityStepper.value];
    [self detectContoursInImage];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    
    [picker dismissViewControllerAnimated:NO completion:^{
        RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:chosenImage];
        imageCropVC.delegate = self;
        imageCropVC.dataSource = self;
        imageCropVC.cropMode = RSKImageCropModeCustom;
        
        [self presentViewController:imageCropVC animated:NO completion:nil];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

#pragma mark - RSKImageCropViewControllerDataSource

- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller {
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle {
    [self dismissViewControllerAnimated:YES completion:^{
        [self setArcLengthTestFieldFromFloat:defaultArcMultiplier];
        [self setImageForImageProcessor:croppedImage];
        [self detectContoursInImage];
    }];
}

- (void)imageCropViewController:(RSKImageCropViewController *)controller
                  willCropImage:(UIImage *)originalImage {
}

#pragma mark - RSKImageCropViewControllerDelegate

- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller {
    return [self customImageCropMask:controller];
}

- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller {
    return [UIBezierPath bezierPathWithOvalInRect:[self customImageCropMask:controller]];
}

- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller {
    return controller.maskRect;
}

- (CGRect)customImageCropMask:(RSKImageCropViewController *)controller {
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    
    int portraitCircleMaskRectInnerEdgeInset = 1;
    CGFloat diameter = MIN(viewWidth, viewHeight) - portraitCircleMaskRectInnerEdgeInset * 2;
    CGSize maskSize = CGSizeMake(diameter, diameter);
    CGRect maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                                 (viewHeight - maskSize.height) * 0.5f,
                                 maskSize.width,
                                 maskSize.height);
    
    return maskRect;
}

@end