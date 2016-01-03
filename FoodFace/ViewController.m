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

@interface ViewController ()
@end

float const defaultArcMultiplier = 0.02;

@implementation ViewController {
    ImageProcessor *processor;
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
                self.outputImageView.image = result.images.firstObject;
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
                self.outputImageView.image = result.results.firstObject;
            }
        });
    });
}

- (void)setImageForImageProcessor:(UIImage*)image {
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
    self.inputImageView.image = defaultPhoto;
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
        self.inputImageView.image = croppedImage;
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