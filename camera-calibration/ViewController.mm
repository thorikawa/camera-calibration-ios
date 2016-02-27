//
//  ViewController.m
//  camera-calibration
//
//  Created by Takahiro Horikawa on 2016/02/25.
//  Copyright © 2016年 Takahiro Horikawa. All rights reserved.
//

#import "ViewController.h"
#import "VideoSource.h"
#import "BGRAVideoFrame.h"
#import "Calibrator.hpp"

@interface ViewController ()<VideoSourceDelegate>

@property (strong, nonatomic) VideoSource * videoSource;
@property (nonatomic) Calibrator * calibrator;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.videoSource = [[VideoSource alloc] initWithPreset:AVCaptureSessionPreset1280x720];
    self.videoSource.delegate = self;
    // [self.videoSource setPreview:self.imageView];
    [self.videoSource startWithDevicePosition:AVCaptureDevicePositionBack];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString *filePath = [directory stringByAppendingPathComponent:[NSString stringWithUTF8String:"camera_parameter.yml"]];
    self.calibrator = new Calibrator([filePath UTF8String]);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)btnStartPressed:(id)sender {
    self.calibrator->startCapturing();
}

#pragma mark - VideoSourceDelegate
-(void)frameReady:(BGRAVideoFrame) frame
{
    // Start upload new frame to video memory in main thread
    dispatch_sync( dispatch_get_main_queue(), ^{
//        [self.visualizationController updateBackground:frame];
    });
    
    // And perform processing in current thread
    self.calibrator->processFrame(frame);
    UIImage* originalImage = [self UIImageByFrame:frame];
    UIImage* image = [ViewController resizedImage:originalImage width:320 height:180];
    
    // When it's done we query rendering from main thread
    dispatch_async( dispatch_get_main_queue(), ^{
//        NSLog(@"main");
        self.imageView.image = image;
        [self.imageView setNeedsDisplay];
    });
}

+ (UIImage *)resizedImage:(UIImage *)image width:(CGFloat)width height:(CGFloat)height
{
    UIGraphicsBeginImageContextWithOptions(CGSizeMake(width, height), NO, [[UIScreen mainScreen] scale]);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    CGContextSetInterpolationQuality(context, kCGInterpolationHigh);
    
    [image drawInRect:CGRectMake(0.0, 0.0, width, height)];
    
    UIImage *resizedImage = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return resizedImage;
}

-(UIImage*) UIImageByFrame:(BGRAVideoFrame) frame
{
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    NSData *data =
    [NSData dataWithBytes:frame.data length:frame.height*frame.stride];
    CGDataProviderRef provider =
    CGDataProviderCreateWithCFData((CFDataRef)data);
    CGImageRef imageRef = CGImageCreate(
                                        frame.width, frame.height,
                                        8, 4*8, frame.stride,
                                        colorSpace, kCGImageAlphaNone|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return ret;
}

@end
