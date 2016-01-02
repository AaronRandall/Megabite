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
}

- (void)detectContoursInImage {
    ImageProcessorResult *result = [ImageProcessorResult new];
    float arcLengthMultiplier = [self.arcLengthTextField.text floatValue];
    
    result = [processor prepareImage];
    result = [processor findContours:arcLengthMultiplier];
    result = [processor filterContours];
    
    self.debugImageView5.image = result.images[0];
}

- (void)convertImageToFoodFace {
    //UIImage *inputImage = [UIImage imageNamed:@"FoodFace7"];
    ImageProcessorResult *result = [ImageProcessorResult new];

    result = [processor extractContourBoundingBoxImages];
    result = [processor boundingBoxImagesToPolygons];
    result = [processor placePolygonsOnTargetTemplate];
    
    self.debugImageView5.image = result.results[0];
    
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
    picker.allowsEditing = YES;
    picker.sourceType = UIImagePickerControllerSourceTypeCamera;
    
    [self presentViewController:picker animated:YES completion:NULL];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *chosenImage = info[UIImagePickerControllerEditedImage];
    self.cameraImageView.image = chosenImage;
    
    [self setImageForImageProcessor:chosenImage];
    
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker {
    [picker dismissViewControllerAnimated:YES completion:NULL];
}

- (IBAction)sensitivityStepperValueChanged:(id)sender {
    self.arcLengthTextField.text = [NSString stringWithFormat:@"%.3f",self.sensitivityStepper.value];
    [self detectContoursInImage];
}
@end
