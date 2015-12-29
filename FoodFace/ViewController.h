//
//  ViewController.h
//  FoodFace
//
//  Created by Aaron on 27/10/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController

@property (weak, nonatomic) IBOutlet UIImageView *imageView;
@property (weak, nonatomic) IBOutlet UIImageView *outputImageView;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView1;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView2;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView3;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageView4;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageViewBin;
@property (weak, nonatomic) IBOutlet UIImageView *debugImageViewItem;
- (IBAction)nextButton:(id)sender;

@end

