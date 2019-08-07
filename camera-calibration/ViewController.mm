//
//  ViewController.m
//  camera-calibration
//
//  Created by Takahiro Horikawa on 2016/02/25.
//  Copyright © 2016年 Takahiro Horikawa. All rights reserved.
//

#import "Calibrator.hpp"
#import "ViewController.h"
#import "VideoSource.h"
#import "BGRAVideoFrame.h"

#import <MessageUI/MessageUI.h>

@interface ViewController ()<VideoSourceDelegate, MFMailComposeViewControllerDelegate>

@property (strong, nonatomic) VideoSource * videoSource;
@property (nonatomic) Calibrator * calibrator;

@property (nonatomic) NSString *calibrationFilePath;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    [self startCameraWithDevicePosition:AVCaptureDevicePositionBack];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *directory = [paths objectAtIndex:0];
    NSString *filePath = [directory stringByAppendingPathComponent:[NSString stringWithUTF8String:"camera_parameter.yml"]];
    self.calibrationFilePath = filePath;
    self.calibrator = new Calibrator([filePath UTF8String], (__bridge void *)self);
}

- (void)startCameraWithDevicePosition:(AVCaptureDevicePosition)position {
    self.videoSource = [[VideoSource alloc] initWithPreset:AVCaptureSessionPreset1920x1080];
    self.videoSource.delegate = self;
    // [self.videoSource setPreview:self.imageView];
    [self.videoSource startWithDevicePosition:position];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)cameraToggled:(UISegmentedControl *)sender {
    AVCaptureDevicePosition position;
    if (sender.selectedSegmentIndex == 0) { // Back camera
        position = AVCaptureDevicePositionBack;
    } else {
        position = AVCaptureDevicePositionFront;
    }

    [self startCameraWithDevicePosition:position];
}

- (IBAction)btnStartPressed:(UIButton *)sender {
    [sender setTitle:@"Calibrating..." forState:UIControlStateNormal];
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
                                        colorSpace, kCGImageAlphaNoneSkipLast|kCGBitmapByteOrderDefault,
                                        provider, NULL, false, kCGRenderingIntentDefault
                                        );
    UIImage *ret = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    CGDataProviderRelease(provider);
    CGColorSpaceRelease(colorSpace);

    return ret;
}

#pragma mark - Callback from Calibrator

// C "trampoline" function to invoke Objective-C method
void CalibrationComplete(void *obj)
{
    // Call the Objective-C method using Objective-C syntax
    [(__bridge id) obj calibrationComplete];
}

- (void)calibrationComplete {
    dispatch_async(dispatch_get_main_queue(), ^{
        [[[UIImpactFeedbackGenerator alloc] initWithStyle:UIImpactFeedbackStyleHeavy] impactOccurred];

        [self.startButton setTitle:@"Start" forState:UIControlStateNormal];

        if ([MFMailComposeViewController canSendMail]) {
            MFMailComposeViewController *mailVC = [MFMailComposeViewController new];
            mailVC.mailComposeDelegate = self;
            mailVC.subject = @"Calibration Data";
            [mailVC setMessageBody:@"" isHTML:NO];
            NSData *fileData = [NSData dataWithContentsOfFile:self.calibrationFilePath];
            [mailVC addAttachmentData:fileData
                             mimeType:@"text/yaml"
                             fileName:[NSString
                                       stringWithFormat:@"Calibration-%@.yml",
                                       self.cameraSelector.selectedSegmentIndex == 0 ? @"Back" : @"Front"]];

            [self presentViewController:mailVC animated:YES completion:nil];
        }
    });
}

#pragma mark Mail callback

- (void)mailComposeController:(MFMailComposeViewController *)controller
          didFinishWithResult:(MFMailComposeResult)result
                        error:(NSError *)error {
    [controller dismissViewControllerAnimated:YES completion:nil];
}

@end
