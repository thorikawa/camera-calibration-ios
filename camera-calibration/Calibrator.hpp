//
//  calibration.hpp
//  camera-calibration
//
//  Created by Takahiro Horikawa on 2016/02/25.
//  Copyright © 2016年 Takahiro Horikawa. All rights reserved.
//

#ifndef calibration_hpp
#define calibration_hpp

#include "BGRAVideoFrame.h"
#include "opencv2/opencv.hpp"

class Calibrator
{
public:
    Calibrator(std::string outputPath);
    int processFrame(BGRAVideoFrame frame);
    void startCapturing();
private:
    enum { DETECTION = 0, CAPTURING = 1, CALIBRATED = 2 };
    enum Pattern { CHESSBOARD, CIRCLES_GRID, ASYMMETRIC_CIRCLES_GRID };
    
    void calcChessboardCorners(cv::Size boardSize, float squareSize, std::vector<cv::Point3f>& corners, Pattern patternType = CHESSBOARD);
    bool runCalibration( std::vector<std::vector<cv::Point2f> > imagePoints,
                        cv::Size imageSize, cv::Size boardSize, Pattern patternType,
                        float squareSize, float aspectRatio,
                        int flags, cv::Mat& cameraMatrix, cv::Mat& distCoeffs,
                        std::vector<cv::Mat>& rvecs, std::vector<cv::Mat>& tvecs,
                        std::vector<float>& reprojErrs,
                        double& totalAvgErr);
    bool runAndSave(const std::vector<std::vector<cv::Point2f> >& imagePoints,
                    cv::Size imageSize, cv::Size boardSize, Pattern patternType, float squareSize,
                    float aspectRatio, int flags, cv::Mat& cameraMatrix,
                    cv::Mat& distCoeffs, bool writeExtrinsics, bool writePoints );
    void saveCameraParams(cv::Size imageSize, cv::Size boardSize,
                          float squareSize, float aspectRatio, int flags,
                          const cv::Mat& cameraMatrix, const cv::Mat& distCoeffs,
                          const std::vector<cv::Mat>& rvecs, const std::vector<cv::Mat>& tvecs,
                          const std::vector<float>& reprojErrs,
                          const std::vector<std::vector<cv::Point2f> >& imagePoints,
                          double totalAvgErr );
    std::string outputPath;
    float squareSize;
    float aspectRatio;
    cv::Size boardSize, imageSize;
    Pattern pattern;
    bool writeExtrinsics, writePoints, undistortImage, flipVertical;
    int mode, i, nframes, flags, delay;
    
    std::vector<std::vector<cv::Point2f> > imagePoints;
    clock_t prevTimestamp;
    cv::Mat cameraMatrix, distCoeffs;
};

#endif /* calibration_hpp */
