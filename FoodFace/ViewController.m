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
 - optimise rotatePolygonToCoverPolygon to stop rotating if covered target surface area == target total surface area
    - investigate increasing the # supported rotations once this is done to see if the face can be better arranged
    - also investigate supporting tweaking this value from a user input
*/

@implementation ViewController {
    ImageProcessor *processor;
}

# pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Make the debug image view circular
    CAShapeLayer *circle = [CAShapeLayer layer];
    UIBezierPath *circularPath=[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, self.debugImageView.frame.size.width, self.debugImageView.frame.size.height) cornerRadius:MAX(self.debugImageView.frame.size.width, self.debugImageView.frame.size.height)];
    circle.path = circularPath.CGPath;
    circle.fillColor = [UIColor blackColor].CGColor;
    circle.strokeColor = [UIColor blackColor].CGColor;
    circle.lineWidth = 0;
    
    self.debugImageView.layer.mask=circle;
}

# pragma mark - Image processor

- (void)detectContoursInImage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        ImageProcessorResult *prepareImageResult = [processor prepareImage];
        ImageProcessorResult *findContoursResult = [processor findContours:[self.arcLengthMultiplierField.text floatValue]];
        ImageProcessorResult *filterContoursResult = [processor filterContours];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (findContoursResult.results.count > 0) {
                self.debugImageView.image = prepareImageResult.images.firstObject;;
                
                NSMutableArray *debugImages = [NSMutableArray arrayWithArray:findContoursResult.results];
                // Show the contours highlighted
                //[debugImages addObjectsFromArray:filterContoursResult.images];
                //[self runFadeAnimationsForImages:debugImages completion:^{
                    [self convertImageToFoodFace];
                //}];
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
                //self.outputImageView.image = placePolygonsOnTargetTemplateResult.results.firstObject;
                
                NSMutableArray *debugImages = [NSMutableArray arrayWithArray:extractContourBoundingBoxImagesResult.images];
//                [debugImages addObject:placePolygonsOnTargetTemplateResult.results.firstObject];
                
                [self runPopAnimationsForImages:debugImages];
                
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (debugImages.count/2.f * NSEC_PER_SEC) + (1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{

                    
                    self.outputImageView.alpha = 0;
                    [UIView animateWithDuration:5.0 animations:^(void) {
                        self.outputImageView.alpha = 1;
                    }];
                    
                                        self.outputImageView.image = nil;
                    
                                        CABasicAnimation* spinAnimationOriginal = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
                                        spinAnimationOriginal.toValue = [NSNumber numberWithFloat:10*M_PI];
                                        spinAnimationOriginal.duration = 5;
                                        spinAnimationOriginal.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                                        spinAnimationOriginal.removedOnCompletion = YES;
                                        spinAnimationOriginal.fillMode = kCAFillModeForwards;
                                        [self.debugImageView.layer addAnimation:spinAnimationOriginal forKey:@"spinAnimationOriginal"];
                    
                    
                    
                                        self.outputImageView.image = placePolygonsOnTargetTemplateResult.results.firstObject;
                                        CABasicAnimation* spinAnimationNew = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
//                                        spinAnimationNew.beginTime = CACurrentMediaTime() + 1.0f;
                                        spinAnimationNew.toValue = [NSNumber numberWithFloat:10*M_PI];
                                        spinAnimationNew.duration = 5;
                                        spinAnimationNew.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
                                        spinAnimationNew.removedOnCompletion = YES;
                                        spinAnimationNew.fillMode = kCAFillModeForwards;
                    
//                    
//                                        CABasicAnimation *fadeAnim=[CABasicAnimation animationWithKeyPath:@"opacity"];
//                                        fadeAnim.fromValue=[NSNumber numberWithDouble:0.0];
//                                        fadeAnim.toValue=[NSNumber numberWithDouble:1.0];
//                    
//                    CAAnimationGroup *group = [CAAnimationGroup animation];
//                    group.duration = 4;
//                    group.repeatCount = 0;
//                    group.autoreverses = NO;
//                    group.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
//                    group.animations = @[spinAnimationNew];
                    
                    [self.outputImageView.layer addAnimation:spinAnimationNew forKey:@"allMyAnimations"];
                    
                    
//                                        [self.self.outputImageView.layer addAnimation:spinAnimationNew forKey:@"spinAnimationNew"];
                    
                    
                });
            }
        });
    });
}

- (void)runPopAnimationsForImages:(NSArray*)images {
    for (int i = 0; i < images.count; i++) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, i/2.f * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
            self.outputImageView.image = images[i];
            POPSpringAnimation *spring = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerScaleXY];
            spring.fromValue = [NSValue valueWithCGSize:CGSizeMake(0.98, 0.98)];
            spring.toValue = [NSValue valueWithCGSize:CGSizeMake(1.03, 1.03)];
            spring.springBounciness = 20;
            spring.springSpeed = 1;
            NSString *animationId = [NSString stringWithFormat:@"animation%i",arc4random_uniform(100)];
            [self.outputImageView.layer pop_addAnimation:spring forKey:animationId];
        });
    }
}

- (void)runFadeAnimationsForImages:(NSArray*)images completion:(void (^)())allAnimationsCompletion {
    // Queue up the image animation blocks and run
    NSMutableArray* animationBlocks = [NSMutableArray new];
    typedef void(^animationBlock)(BOOL);
    
    animationBlock (^getNextAnimation)() = ^{
        animationBlock block = animationBlocks.count ? (animationBlock)animationBlocks[0] : nil;
        if (block) {
            [animationBlocks removeObjectAtIndex:0];
            return block;
        } else {
            return ^(BOOL finished){
                allAnimationsCompletion();
            };
        }
    };
    
    for (UIImage *image in images) {
        [animationBlocks addObject:^(BOOL finished){
            UIImage * toImage = image;
            [UIView transitionWithView:self.debugImageView
                              duration:0.75f
                               options:UIViewAnimationOptionTransitionCrossDissolve
                            animations:^{
                                self.debugImageView.image = toImage;
                            } completion:getNextAnimation()];
        }];
    }
    
    getNextAnimation()(YES);
}

- (void)setImageForImageProcessor:(UIImage*)image {
    self.inputThumbnailImageView.image = image;
    self.inputImageView.image = image;
    self.debugImageView.image = nil;
    self.outputImageView.image = nil;
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
//    [self detectContoursInImage];
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