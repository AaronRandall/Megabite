//
//  ViewController.h
//  Megabite
//
//  Created by Aaron on 27/10/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import <RSKImageCropper/RSKImageCropper.h>

@interface ViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDataSource, RSKImageCropViewControllerDelegate>

- (IBAction)takePhoto:(id)sender;
- (IBAction)defaultPhoto:(id)sender;
- (IBAction)run:(id)sender;
- (IBAction)sensitivityStepperValueChanged:(id)sender;

@property (strong, nonatomic) IBOutlet UIStepper *sensitivityStepper;
@property (strong, nonatomic) IBOutlet UISlider *maxPolygonRotationSlider;
@property (strong, nonatomic) IBOutlet UITextField *arcLengthMultiplierField;
@property (strong, nonatomic) IBOutlet UIImageView *inputImageView;
@property (strong, nonatomic) IBOutlet UIImageView *outputImageView;
@property (strong, nonatomic) IBOutlet UIImageView *debugImageView;
@property (strong, nonatomic) IBOutlet UIImageView *animatedImageView;

@end