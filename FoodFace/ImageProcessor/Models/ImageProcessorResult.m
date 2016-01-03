//
//  ImageProcessorResult.m
//  FoodFace
//
//  Created by Aaron on 02/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import "ImageProcessorResult.h"

@implementation ImageProcessorResult

- (id)initWithResults:(NSArray*)results images:(NSArray*)images {
    self = [super init];
    if (self) {
        self.results = results;
        self.images = images;
    }
    return self;
}

@end