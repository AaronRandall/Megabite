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
 - investigate increasing the # supported rotations once this is done to see if the face can be better arranged
 - also investigate supporting tweaking this value from a user input
 */

@implementation ViewController {
    ImageProcessor *processor;
}

# pragma mark - Image processor

- (void)runImageProcessing {
    [processor run:[self options] completion:^(ImageProcessorResult *result) {
        [self runAnimationsWithResult:result];
    }];
}

- (void)runAnimationsWithResult:(ImageProcessorResult*)result {
    UIImage *croppedInputImage = result.results[0];
    NSArray *extractedContourBoundingBoxImages = result.results[1];
    UIImage *outputImage = result.results[2];
    
    self.debugImageView.image = croppedInputImage;
    
    [self runPopAnimationsForImages:extractedContourBoundingBoxImages];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (extractedContourBoundingBoxImages.count/2.f * NSEC_PER_SEC) + (1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        self.outputImageView.image = nil;
        self.animatedImageView.image = nil;
        
        self.outputImageView.alpha = 0;
        [UIView animateWithDuration:5.0 animations:^(void) {
            self.outputImageView.alpha = 1;
        }];
        
        // Spin the cropped input image
        CABasicAnimation* spinAnimationOriginal = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        spinAnimationOriginal.toValue = [NSNumber numberWithFloat:10*M_PI];
        spinAnimationOriginal.duration = 5;
        spinAnimationOriginal.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        spinAnimationOriginal.removedOnCompletion = YES;
        spinAnimationOriginal.fillMode = kCAFillModeForwards;
        [self.debugImageView.layer addAnimation:spinAnimationOriginal forKey:@"spinAnimationOriginal"];
        

        self.outputImageView.image = outputImage;

        // Spin the output image
        CABasicAnimation* spinAnimationNew = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
        spinAnimationNew.toValue = [NSNumber numberWithFloat:10*M_PI];
        spinAnimationNew.duration = 5;
        spinAnimationNew.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        spinAnimationNew.removedOnCompletion = YES;
        spinAnimationNew.fillMode = kCAFillModeForwards;
        
        [self.outputImageView.layer addAnimation:spinAnimationNew forKey:@"allMyAnimations"];
    });
}

- (void)runPopAnimationsForImages:(NSArray*)images {
    for (int i = 0; i < images.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i/2.f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.animatedImageView.image = images[i];
            POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
            spring.fromValue = [NSValue valueWithCGSize:CGSizeMake(0.98, 0.98)];
            spring.toValue = [NSValue valueWithCGSize:CGSizeMake(1.03, 1.03)];
            spring.springBounciness = 20;
            spring.springSpeed = 5;
            NSString *animationId = [NSString stringWithFormat:@"animation%i",arc4random_uniform(100)];
            [self.animatedImageView.layer pop_addAnimation:spring forKey:animationId];
        });
    }
}

- (void)setImageForImageProcessor:(UIImage*)image {
    self.inputImageView.image = image;
    self.debugImageView.image = nil;
    self.outputImageView.image = nil;
    processor = [[ImageProcessor alloc] initWithImage:image];
}

- (void)setArcLengthTestFieldFromFloat:(float)value {
    self.arcLengthMultiplierField.text = [NSString stringWithFormat:@"%.3f",value];
    self.sensitivityStepper.value = value;
}

- (NSNumber*)maxPolygonRotationValue {
    NSArray *rotationValues = @[@2, @3, @4, @5, @6, @9, @20, @30, @60, @90, @180];
    int sliderValue = (int)self.maxPolygonRotationSlider.value;
    
    NSLog(@"rotationValues: %@", rotationValues[sliderValue]);
    
    return rotationValues[sliderValue];
}

- (NSDictionary*)options {
    return @{@"arcLengthMultiplier" : self.arcLengthMultiplierField.text,
             @"maxNumPolygonRotations" : [self maxPolygonRotationValue]};
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
    [self runImageProcessing];
}

- (IBAction)run:(id)sender {
    [self runImageProcessing];
}

- (IBAction)sensitivityStepperValueChanged:(id)sender {
    [self setArcLengthTestFieldFromFloat:self.sensitivityStepper.value];
    [self runImageProcessing];
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
        [self runImageProcessing];
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