//
//  ViewController.h
//  FoodFace
//
//  Created by Aaron on 27/10/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <RSKImageCropper/RSKImageCropper.h>

@interface ViewController : UIViewController<UIImagePickerControllerDelegate, UINavigationControllerDelegate, RSKImageCropViewControllerDataSource, RSKImageCropViewControllerDelegate>

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *outputImageView;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView2;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView3;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView4;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView5;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageViewBin;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageViewItem;
@property (weak, nonatomic) IBOutlet UIImageView *outputImageViewAll;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView6;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView7;
- (IBAction)nextButton:(id)sender;
- (IBAction)run:(id)sender;
@property (weak, nonatomic) IBOutlet UITextField *arcLengthTextField;
@property (strong, nonatomic) IBOutlet UIImageView *cameraImageView;
- (IBAction)takePhotoButton:(id)sender;
- (IBAction)detectContours:(id)sender;
@property (weak, nonatomic) IBOutlet UIStepper *sensitivityStepper;
- (IBAction)sensitivityStepperValueChanged:(id)sender;

@end

