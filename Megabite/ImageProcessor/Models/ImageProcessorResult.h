//
//  ImageProcessorResult.h
//  Megabite
//
//  Created by Aaron on 02/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

@interface ImageProcessorResult : NSObject

- (id)initWithResults:(NSArray*)results images:(NSArray*)images;

@property (nonatomic, readonly, retain) NSArray *results;
@property (nonatomic, readonly, retain) NSArray *images;
@property (nonatomic, readonly, retain) UIImage *croppedInputImage;
@property (nonatomic, readonly, retain) UIImage *outputImage;
@property (nonatomic, readonly, retain) NSArray *extractedContourBoundingBoxImages;

@end