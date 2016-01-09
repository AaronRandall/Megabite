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
 - work out way to animate between all the different image types
 - last code cleanup
 - blog post
*/

@implementation ViewController {
    ImageProcessor *processor;
    NSMutableArray *outputImages;
}

# pragma mark - View lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];
    
    outputImages = [NSMutableArray array];
}

# pragma mark - Image processor

- (void)detectContoursInImage {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        ImageProcessorResult *result = [ImageProcessorResult new];
        result = [processor prepareImage];
        result = [processor findContours:[self.arcLengthMultiplierField.text floatValue]];
        result = [processor filterContours];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result.images.count > 0) {
                [outputImages addObject:result.images.firstObject];
                self.debugImageView.image = result.images.firstObject;
            }
        });
    });
}

- (void)convertImageToFoodFace {
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        ImageProcessorResult *result = [ImageProcessorResult new];
        result = [processor extractContourBoundingBoxImages];
        result = [processor boundingBoxImagesToPolygons];
        result = [processor placePolygonsOnTargetTemplate];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (result.results.count > 0) {
                [outputImages addObject:result.results.firstObject];
                self.outputImageView.image = result.results.firstObject;
                //[self runAnimations];
            }
        });
    });
}

- (void)runAnimations {
    POPSpringAnimation *sizeAnimation = [POPSpringAnimation animationWithPropertyNamed:kPOPLayerBounds];
    sizeAnimation.springBounciness = 10;
    if (self.inputImageView.bounds.size.width == 250) {
        sizeAnimation.toValue = [NSValue valueWithCGRect:CGRectMake(0, 0, self.view.bounds.size.width, self.view.bounds.size.width)];
    }
    
    [sizeAnimation setCompletionBlock:^(POPAnimation *animation, BOOL finished) {
        if(finished){
            NSLog(@"finished");
            POPBasicAnimation *basicAnimation = [POPBasicAnimation animation];
            basicAnimation.property = [POPAnimatableProperty propertyWithName:kPOPViewAlpha];
            basicAnimation.toValue= @(1);
            [self.outputImageView pop_addAnimation:basicAnimation forKey:@"basicAnimation"];
        }
    }];
    
    [self.inputImageView pop_addAnimation:sizeAnimation forKey:@"sizeAnimation"];
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