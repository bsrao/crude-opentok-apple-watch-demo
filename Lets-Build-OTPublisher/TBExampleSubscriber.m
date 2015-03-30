//
//  TBSubscriber.m
//  Lets-Build-OTPublisher
//
//  Copyright (c) 2013 TokBox, Inc. All rights reserved.
//

#import "TBExampleSubscriber.h"
#import "TBExampleVideoRender.h"
@import CoreGraphics;

// Internally forward-declare that we can receive renderer delegate callbacks
@interface TBExampleSubscriber () <TBRendererDelegate>
@end

@implementation TBExampleSubscriber {
    TBExampleVideoRender* _myVideoRender;
}

@synthesize view = _myVideoRender;

- (id)initWithStream:(OTStream *)stream
            delegate:(id<OTSubscriberKitDelegate>)delegate
{
    self = [super initWithStream:stream delegate:delegate];
    if (self) {
        _myVideoRender =
        [[TBExampleVideoRender alloc] initWithFrame:CGRectMake(0,0,1,1)];
        _myVideoRender.delegate = self;
        [self setVideoRender:_myVideoRender];
        
        // Observe important stream attributes to properly react to changes
        [self.stream addObserver:self
                      forKeyPath:@"hasVideo"
                         options:NSKeyValueObservingOptionNew
                         context:nil];
        [self.stream addObserver:self
                      forKeyPath:@"hasAudio"
                         options:NSKeyValueObservingOptionNew
                         context:nil];
    }
    return self;
}

- (void)dealloc {
    [self.stream removeObserver:self forKeyPath:@"hasVideo" context:nil];
    [self.stream removeObserver:self forKeyPath:@"hasAudio" context:nil];
    [_myVideoRender release];
    [super dealloc];
}

#pragma mark - KVO listeners for UI updates

- (void)observeValueForKeyPath:(NSString *)keyPath
                      ofObject:(id)object
                        change:(NSDictionary *)change
                       context:(void *)context {
    dispatch_async(dispatch_get_main_queue(), ^() {
        if ([@"hasVideo" isEqualToString:keyPath]) {
            // If the video track has gone away, we can clear the screen.
            BOOL value = [[change valueForKey:@"new"] boolValue];
            if (value) {
                [_myVideoRender setRenderingEnabled:YES];
            } else {
                [_myVideoRender setRenderingEnabled:NO];
                [_myVideoRender clearRenderBuffer];
            }
        } else if ([@"hasAudio" isEqualToString:keyPath]) {
            // nop?
        }
    });
}

#pragma mark - Overrides for UI

- (void)setSubscribeToVideo:(BOOL)subscribeToVideo {
    [super setSubscribeToVideo:subscribeToVideo];
    [_myVideoRender setRenderingEnabled:subscribeToVideo];
    if (!subscribeToVideo) {
        [_myVideoRender clearRenderBuffer];
    }
}

// libyuv member
//
extern int I420ToARGB(const uint8_t* src_y, int src_stride_y,
                      const uint8_t* src_u, int src_stride_u,
                      const uint8_t* src_v, int src_stride_v,
                      uint8_t* dst_argb, int dst_stride_argb,
                      int width, int height);
int picCount = 0;

#pragma mark - TBRendererDelegate
- (void)renderer:(TBExampleVideoRender *)renderer
 didReceiveFrame:(OTVideoFrame *)frame
{
    picCount ++;
    if ((picCount % 5) == 0)
    {
        uint8_t *dst_argb = malloc(frame.format.imageWidth * frame.format.imageHeight * 4);
        int dst_stride_argb = frame.format.imageWidth * 4;
        
        I420ToARGB([frame.planes pointerAtIndex:0],
                                [[[[frame format] bytesPerRow] objectAtIndex:0] intValue],
                                [frame.planes pointerAtIndex:1],
                                [[[[frame format] bytesPerRow] objectAtIndex:1] intValue],
                                [frame.planes pointerAtIndex:2],
                                [[[[frame format] bytesPerRow] objectAtIndex:2] intValue],
                                dst_argb,dst_stride_argb,
                                frame.format.imageWidth, frame.format.imageHeight);
        int width = frame.format.imageWidth;
        int height = frame.format.imageHeight;
        
        CGImageRef image;
        CFDataRef bridgedData;
        CGDataProviderRef dataProvider;
        CGColorSpaceRef colorSpace;
        CGBitmapInfo infoFlags = kCGImageAlphaPremultipliedFirst; // ARGB
        
        colorSpace = CGColorSpaceCreateDeviceRGB();
        bridgedData  = (CFDataRef)[NSData dataWithBytes:dst_argb
                                                 length:(width *
                                                         height * 4)];
        dataProvider = CGDataProviderCreateWithCFData(bridgedData);
        
        image = CGImageCreate(
                              width, height, /* bpc */ 8, /* bpp */ 32, /* pitch */ width * 4,
                              colorSpace, infoFlags,
                              dataProvider, /* decode array */ NULL, /* interpolate? */ TRUE,
                              kCGRenderingIntentDefault /* adjust intent according to use */
                              );
        
        // Release things the image took ownership of.
        CGDataProviderRelease(dataProvider);
        CGColorSpaceRelease(colorSpace);
        
        // Resizing really needed ?
        //    CGColorSpaceRef colorspace = CGImageGetColorSpace(image);
        //    CGContextRef context = CGBitmapContextCreate(NULL, width, height,
        //                                                 CGImageGetBitsPerComponent(image),
        //                                                 CGImageGetBytesPerRow(image),
        //                                                 colorspace,
        //                                                 CGImageGetAlphaInfo(image));
        //    CGColorSpaceRelease(colorspace);
        //
        //
        //    // draw image to context (resizing it)
        //    CGContextDrawImage(context, CGRectMake(0, 0, 800, 800), image);
        //    // extract resulting image from context
        //    CGImageRef imgRef = CGBitmapContextCreateImage(context);
        //    CGContextRelease(context);
        
        NSLog(@"setting image %d",picCount);
        
        UIImage *img = [UIImage imageWithCGImage:image];
        [self.interfaceImage setImage:img];
        // [self.interfaceGroup setBackgroundImage:img];
        
        //  CGImageRelease(imgRef);
        CGImageRelease(image);
        free(dst_argb);
    }
}
@end
