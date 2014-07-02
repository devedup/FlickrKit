//
//  NSImageJPEGRepresentation.m
//  FlickrKit OS X
//
//  Created by Johnnie Walker on 11/11/2013.
//  Copyright (c) 2013 DevedUp Ltd. All rights reserved.
//

#import "NSImageJPEGRepresentation.h"

NSBitmapImageRep * bitmapImageRepresentation(NSImage *image);
NSBitmapImageRep * bitmapImageRepresentation(NSImage *image) {
    
    int width = [image size].width;
    int height = [image size].height;
    
    if(width < 1 || height < 1)
        return nil;
    
    NSBitmapImageRep *rep = [[NSBitmapImageRep alloc]
                             initWithBitmapDataPlanes: NULL
                             pixelsWide: width
                             pixelsHigh: height
                             bitsPerSample: 8
                             samplesPerPixel: 4
                             hasAlpha: YES
                             isPlanar: NO
                             colorSpaceName: NSDeviceRGBColorSpace
                             bytesPerRow: width * 4
                             bitsPerPixel: 32];
    
    NSGraphicsContext *ctx = [NSGraphicsContext graphicsContextWithBitmapImageRep: rep];
    [NSGraphicsContext saveGraphicsState];
    [NSGraphicsContext setCurrentContext: ctx];
    [image drawAtPoint: NSZeroPoint fromRect: NSZeroRect operation: NSCompositeCopy fraction: 1.0];
    [ctx flushGraphics];
    [NSGraphicsContext restoreGraphicsState];
    
    return rep;
}

NSData * NSImageJPEGRepresentation(NSImage *image, CGFloat compressionQuality) {
    return [bitmapImageRepresentation(image) representationUsingType:NSJPEGFileType
                                                          properties: @{NSImageCompressionFactor: @(compressionQuality)}];
}