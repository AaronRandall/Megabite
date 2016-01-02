//
//  ImageProcessorResult.h
//  FoodFace
//
//  Created by Aaron on 02/01/2016.
//  Copyright © 2016 Aaron. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ImageProcessorResult : NSObject

-(id)initWithResults:(NSArray*)results images:(NSArray*)images;

@property (nonatomic, retain) NSArray *results;
@property (nonatomic, retain) NSArray *images;

@end
