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
#import <RSKImageCropper/RSKImageCropper.h>

@interface ViewController ()
@end

float const defaultArcMultiplier = 0.02;

@implementation ViewController {
    ImageProcessor *processor;
}

@synthesize sensitivityStepper;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // TODO: resize input image to fixed size (1000x1000)
    // TODO: Crop image to largest possible circle
    // TODO: detect plate
    // TODO: fill extracted regions (holes) on plate
    // TODO: select template based on num. extracted contours
    // TODO: setup template with bins, bin centroid coordinates, bin surface areas, ordered by surface area (big to small)
    // TODO: allow for tweaking arc length multiplier and other input values
    // TODO: capture image from camera
    // TODO: show processing progress
    // TODO: benchmarking
    
    // TODO: crop image to circle (while taking image)
    // TODO: support tweaking number of image & polygon rotations allowed (with stepper)
}

- (void)didReceiveMemoryWarning {
    NSLog(@"Uh oh. Intensive image processing on an iPhone is possibly not a great idea.");
}

- (void)detectContoursInImage {
    ImageProcessorResult *result = [ImageProcessorResult new];
    float arcLengthMultiplier = [self.arcLengthTextField.text floatValue];
    
    result = [processor prepareImage];
    result = [processor findContours:arcLengthMultiplier];
    result = [processor filterContours];
    
    if (result.images.count > 0) {
        self.debugImageView5.image = result.images[0];
    }
}

- (void)convertImageToFoodFace {
    //UIImage *inputImage = [UIImage imageNamed:@"FoodFace7"];
    ImageProcessorResult *result = [ImageProcessorResult new];

    result = [processor extractContourBoundingBoxImages];
    result = [processor boundingBoxImagesToPolygons];
    result = [processor placePolygonsOnTargetTemplate];
    
    if (result.results.count > 0) {
        self.debugImageView5.image = result.results[0];
    }
    
    NSLog(@"Processing complete");
}

////    // Debug the bin layout
////    [self displayBinTemplateLayout:sortedBinPolygons usingSize:testImage.size];
//- (void)displayBinTemplateLayout:(NSArray*)binPolygons usingSize:(CGSize)size {
//    UIGraphicsBeginImageContextWithOptions(size, NO, 0.0);
//    
//    for (int i = 0; i < binPolygons.count; i++) {
//        [((Polygon*)[binPolygons objectAtIndex:i]).shape fill];
//    }
//    
//    UIImage *myImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    
//    self.debugImageView3.image = myImage;
//}

- (IBAction)nextButton:(id)sender {
//    self.imageIndex++;
//    int currentIndex = self.imageIndex % self.images.count;
//    UIImage *currentImage = [self.images objectAtIndex:currentIndex];
//    self.debugImageView1.image = currentImage;
}

- (void)setImageForImageProcessor:(UIImage*)image {
    processor = [[ImageProcessor alloc] initWithImage:image];
}

- (IBAction)detectContours:(id)sender {
    [self detectContoursInImage];
}

- (IBAction)run:(id)sender {
    [self convertImageToFoodFace];
}

- (IBAction)takePhotoButton:(id)sender {
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];
    picker.delegate = self;
    picker.allowsEditing = NO;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerOriginalImage];
    //self.cameraImageView.image = chosenImage;

    [picker dismissViewControllerAnimated:NO completion:^{
//        [self setArcLengthTestFieldFromFloat:defaultArcMultiplier];
//        [self setImageForImageProcessor:chosenImage];
//        [self detectContoursInImage];
        
        RSKImageCropViewController *imageCropVC = [[RSKImageCropViewController alloc] initWithImage:chosenImage];
        imageCropVC.delegate = self;
        imageCropVC.dataSource = self;
        imageCropVC.cropMode = RSKImageCropModeCustom;
//        CGRect bounds=(CGRect){CGPointZero,chosenImage.size};
//        imageCropVC.maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds
//                                                          cornerRadius:100.0f];
        [self presentViewController:imageCropVC animated:NO completion:nil];
    }];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)sensitivityStepperValueChanged:(id)sender {
    [self setArcLengthTestFieldFromFloat:self.sensitivityStepper.value];
    [self detectContoursInImage];
}

- (void)setArcLengthTestFieldFromFloat:(float)value {
    self.arcLengthTextField.text = [NSString stringWithFormat:@"%.3f",value];
}






// Crop image has been canceled.
- (void)imageCropViewControllerDidCancelCrop:(RSKImageCropViewController *)controller
{
    [self dismissViewControllerAnimated:YES completion:nil];
//    [self.navigationController popViewControllerAnimated:YES];
}

// The original image has been cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
{
//    self.imageView.image = croppedImage;
//    [self.navigationController popViewControllerAnimated:YES];
    
    [self dismissViewControllerAnimated:YES completion:^{
        self.cameraImageView.image = croppedImage;
        [self setArcLengthTestFieldFromFloat:defaultArcMultiplier];
        [self setImageForImageProcessor:croppedImage];
        [self detectContoursInImage];
    }];
}

// The original image has been cropped. Additionally provides a rotation angle used to produce image.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                   didCropImage:(UIImage *)croppedImage
                  usingCropRect:(CGRect)cropRect
                  rotationAngle:(CGFloat)rotationAngle
{
//    self.imageView.image = croppedImage;
    [self dismissViewControllerAnimated:YES completion:^{
        self.cameraImageView.image = croppedImage;
        [self setArcLengthTestFieldFromFloat:defaultArcMultiplier];
        [self setImageForImageProcessor:croppedImage];
        [self detectContoursInImage];
    }];
//    [self.navigationController popViewControllerAnimated:YES];
}

// The original image will be cropped.
- (void)imageCropViewController:(RSKImageCropViewController *)controller
                  willCropImage:(UIImage *)originalImage
{
    // Use when `applyMaskToCroppedImage` set to YES.
}

// Returns a custom rect for the mask.
- (CGRect)imageCropViewControllerCustomMaskRect:(RSKImageCropViewController *)controller
{
    CGRect maskRect;
    
    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    
    int portraitCircleMaskRectInnerEdgeInset = 1;
    CGFloat diameter = MIN(viewWidth, viewHeight) - portraitCircleMaskRectInnerEdgeInset * 2;
    
    CGSize maskSize = CGSizeMake(diameter, diameter);
    
    maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                          (viewHeight - maskSize.height) * 0.5f,
                          maskSize.width,
                          maskSize.height);
    
    return maskRect;
}

// Returns a custom path for the mask.
- (UIBezierPath *)imageCropViewControllerCustomMaskPath:(RSKImageCropViewController *)controller
{
    CGRect maskRect;

    CGFloat viewWidth = CGRectGetWidth(self.view.bounds);
    CGFloat viewHeight = CGRectGetHeight(self.view.bounds);
    
    int portraitCircleMaskRectInnerEdgeInset = 1;
    CGFloat diameter = MIN(viewWidth, viewHeight) - portraitCircleMaskRectInnerEdgeInset * 2;
    
    CGSize maskSize = CGSizeMake(diameter, diameter);
    
    maskRect = CGRectMake((viewWidth - maskSize.width) * 0.5f,
                               (viewHeight - maskSize.height) * 0.5f,
                               maskSize.width,
                               maskSize.height);
    
    return [UIBezierPath bezierPathWithOvalInRect:maskRect];
}

// Returns a custom rect in which the image can be moved.
- (CGRect)imageCropViewControllerCustomMovementRect:(RSKImageCropViewController *)controller
{
    // If the image is not rotated, then the movement rect coincides with the mask rect.
    return controller.maskRect;
}

@end
