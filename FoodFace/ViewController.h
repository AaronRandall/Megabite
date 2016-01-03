//
//  ViewController.h
//  FoodFace
//
//  Created by Aaron on 27/10/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import <RSKImageCropper/RSKImageCropper.h>

@interface ViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDataSource, RSKImageCropViewControllerDelegate>

- (IBAction)takePhoto:(id)sender;
- (IBAction)defaultPhoto:(id)sender;
- (IBAction)detectContours:(id)sender;
- (IBAction)convertImage:(id)sender;
- (IBAction)sensitivityStepperValueChanged:(id)sender;

@property (weak, nonatomic) IBOutlet UIStepper *sensitivityStepper;
@property (weak, nonatomic) IBOutlet UITextField *arcLengthMultiplierField;
@property (weak, nonatomic) IBOutlet UIImageView *inputImageView;
@property (weak, nonatomic) IBOutlet UIImageView *outputImageView;

@end