//
//  UIImage+Trim.m
//  FoodFace
//
//  Created by Aaron on 27/10/2015.
//  Copyright © 2015 Aaron. All rights reserved.
//

#import "UIImage+Trim.h"

@implementation UIImage (Trim)

- (UIImage *)trimmedImage {
    
    CGImageRef inImage = self.CGImage;
    CFDataRef m_DataRef;
    m_DataRef = CGDataProviderCopyData(CGImageGetDataProvider(inImage));
    
    UInt8 * m_PixelBuf = (UInt8 *) CFDataGetBytePtr(m_DataRef);
    
    size_t width = CGImageGetWidth(inImage);
    size_t height = CGImageGetHeight(inImage);
    
    CGPoint top,left,right,bottom;
    
    BOOL breakOut = NO;
    for (int x = 0;breakOut==NO && x < width; x++) {
        for (int y = 0; y < height; y++) {
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                left = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
        }
    }
    
    breakOut = NO;
    for (int y = 0;breakOut==NO && y < height; y++) {
        
        for (int x = 0; x < width; x++) {
            
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                top = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
            
        }
    }
    
    breakOut = NO;
    for (int y = height-1;breakOut==NO && y >= 0; y--) {
        
        for (int x = width-1; x >= 0; x--) {
            
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                bottom = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
            
        }
    }
    
    breakOut = NO;
    for (int x = width-1;breakOut==NO && x >= 0; x--) {
        
        for (int y = height-1; y >= 0; y--) {
            
            int loc = x + (y * width);
            loc *= 4;
            if (m_PixelBuf[loc + 3] != 0) {
                right = CGPointMake(x, y);
                breakOut = YES;
                break;
            }
            
        }
    }
    
    
    CGFloat scale = self.scale;
    
    CGRect cropRect = CGRectMake(left.x / scale, top.y/scale, (right.x - left.x)/scale, (bottom.y - top.y) / scale);
    UIGraphicsBeginImageContextWithOptions( cropRect.size,
                                           NO,
                                           scale);
    [self drawAtPoint:CGPointMake(-cropRect.origin.x, -cropRect.origin.y)
            blendMode:kCGBlendModeCopy
                alpha:1.];
    UIImage *croppedImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    CFRelease(m_DataRef);
    return croppedImage;
}

- (UIImage *)replaceColor:(UIColor*)color withTolerance:(float)tolerance {
    CGImageRef imageRef = [self CGImage];
    
    NSUInteger width = CGImageGetWidth(imageRef);
    NSUInteger height = CGImageGetHeight(imageRef);
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    
    NSUInteger bytesPerPixel = 4;
    NSUInteger bytesPerRow = bytesPerPixel * width;
    NSUInteger bitsPerComponent = 8;
    NSUInteger bitmapByteCount = bytesPerRow * height;
    
    unsigned char *rawData = (unsigned char*) calloc(bitmapByteCount, sizeof(unsigned char));
    
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
                                                 bitsPerComponent, bytesPerRow, colorSpace,
                                                 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    
    CGColorRef cgColor = [color CGColor];
    const CGFloat *components = CGColorGetComponents(cgColor);
    float r = components[0];
    float g = components[1];
    float b = components[2];
    //float a = components[3]; // not needed
    
    r = r * 255.0;
    g = g * 255.0;
    b = b * 255.0;
    
    const float redRange[2] = {
        MAX(r - (tolerance / 2.0), 0.0),
        MIN(r + (tolerance / 2.0), 255.0)
    };
    
    const float greenRange[2] = {
        MAX(g - (tolerance / 2.0), 0.0),
        MIN(g + (tolerance / 2.0), 255.0)
    };
    
    const float blueRange[2] = {
        MAX(b - (tolerance / 2.0), 0.0),
        MIN(b + (tolerance / 2.0), 255.0)
    };
    
    int byteIndex = 0;
    
    while (byteIndex < bitmapByteCount) {
        unsigned char red   = rawData[byteIndex];
        unsigned char green = rawData[byteIndex + 1];
        unsigned char blue  = rawData[byteIndex + 2];
        
        if (((red >= redRange[0]) && (red <= redRange[1])) &&
            ((green >= greenRange[0]) && (green <= greenRange[1])) &&
            ((blue >= blueRange[0]) && (blue <= blueRange[1]))) {
            // make the pixel transparent
            //
            rawData[byteIndex] = 0;
            rawData[byteIndex + 1] = 0;
        rawData[byteIndex + 2] = 0;
            rawData[byteIndex + 3] = 0;
        }
        
        byteIndex += 4;
    }
    
    CGImageRef imgref = CGBitmapContextCreateImage(context);
    UIImage *result = [UIImage imageWithCGImage:imgref];
    
    CGImageRelease(imgref);
    CGContextRelease(context);
    free(rawData);
    
    return result;
}
@end
