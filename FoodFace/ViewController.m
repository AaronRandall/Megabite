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
#import "AnimationHelper.h"

@interface ViewController ()
@end

float const defaultArcMultiplier = 0.02;

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
    
    [AnimationHelper runPopAnimationsForImages:extractedContourBoundingBoxImages imageView:self.animatedImageView];
    [AnimationHelper runSpinAnimationsForImages:extractedContourBoundingBoxImages outputImage:outputImage outputImageView:self.outputImageView animatedImageView:self.animatedImageView debugImageView:self.debugImageView];
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
    int sliderValue = (int)self.maxPolygonRotationSlider.value;
    return [[ImageProcessor rotationValues] objectAtIndex:sliderValue];
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