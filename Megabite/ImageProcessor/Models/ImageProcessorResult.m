//
//  ImageProcessorResult.m
//  Megabite
//
//  Created by Aaron on 02/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import "ImageProcessorResult.h"

@implementation ImageProcessorResult

- (id)initWithResults:(NSArray*)results images:(NSArray*)images {
    self = [super init];
    if (self) {
        _results = results;
        _images = images;
    }
    return self;
}

- (UIImage*)croppedInputImage {
    UIImage *croppedInputImage;
    if (self.results) {
        croppedInputImage = self.results[0];
    }
    
    return croppedInputImage;
}

- (NSArray*)extractedContourBoundingBoxImages {
    NSArray *extractedContourBoundingBoxImages;
    if (self.results) {
        extractedContourBoundingBoxImages = self.results[1];
    }
    
    return extractedContourBoundingBoxImages;
}

- (UIImage*)outputImage {
    UIImage *outputImage;
    if (self.results) {
        outputImage = self.results[2];
    }
    
    return outputImage;
}

@end