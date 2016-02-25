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
    self.videoSource = [[VideoSource alloc] init];
    self.videoSource.delegate = self;
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
    
    // When it's done we query rendering from main thread
    dispatch_async( dispatch_get_main_queue(), ^{
//        [self.visualizationController setTransformationList:(self.markerDetector->getTransformations)()];
//        [self.visualizationController drawFrame];
    });
}

@end
