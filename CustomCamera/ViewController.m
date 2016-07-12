//
//  ViewController.m
//  CustomCamera
//
//  Created by Netho on 16/7/11.
//  Copyright © 2016年 whq. All rights reserved.
//

#import "ViewController.h"

#import <AVFoundation/AVFoundation.h>

@interface ViewController ()

/*!
 *  拍照按钮
 */
@property (nonatomic,strong) UIButton *photoClick;

/*!
 *  切换摄像头
 */
@property (nonatomic,strong) UIButton *conversationBtn;

/*!
 *  聚焦视图
 */
@property (nonatomic,strong) UIView *focusView;

#pragma mark -----------------------------------------------------------------------

/*!
 *  捕获设备,通常是前置摄像头, 后置摄像头,麦克风(音频输入)
 */
@property (nonatomic,strong) AVCaptureDevice *device;

/*!
 *  AVCaptureInput 代表输入设备, 他使用AVCaptureDevice 来初始化
 */
@property (nonatomic,strong) AVCaptureDeviceInput *input;

/*!
 *  输出图片
 */
@property (nonatomic,strong) AVCaptureStillImageOutput *imageOutput;

/*!
 *  session : 由它把输入输出结合在一起, 并开始启动 捕获设备(摄像头)
 */
@property (nonatomic,strong) AVCaptureSession *session;

/*!
 *  图像预览层, 实时显示捕获的图像
 */
@property (nonatomic,strong) AVCaptureVideoPreviewLayer *preViewLayer;

/*!
 *  照片视图
 */
@property (nonatomic,strong) UIImageView  *cameraImageView;

/*!
 *  重拍
 */
@property (nonatomic,strong) UIButton *remakeBtn;

/*!
 *  保存相片
 */
@property (nonatomic,strong) UIButton *saveImageBtn;

/*!
 *  拍照生成的图片
 */
@property (nonatomic,strong) UIImage *image;

@end

@implementation ViewController

- (UIView *)focusView
{
    if (!_focusView) {
        _focusView = [UIView new];
        _focusView.backgroundColor = [UIColor clearColor];
        _focusView.frame = CGRectMake(0, 0, 80, 80);
        _focusView.layer.borderWidth  = 1.0;
        _focusView.layer.borderColor = [UIColor colorWithRed:0.038 green:0.870 blue:1.000 alpha:1.000].CGColor;
    }
    return _focusView;
}

-(UIButton *)photoClick
{
    if (!_photoClick) {
        _photoClick = [UIButton buttonWithType:(UIButtonTypeCustom)];
        _photoClick.frame = CGRectMake(self.view.center.x - 25, self.view.bounds.size.height - 100, 50, 50);
        [_photoClick setImage:[UIImage imageNamed:@"photograph"] forState:(UIControlStateNormal)];
        [_photoClick setImage:[UIImage imageNamed:@"photograph_Select"] forState:(UIControlStateHighlighted)];
        [_photoClick addTarget:self action:@selector(getPhoto) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _photoClick;
}

- (UIButton *)conversationBtn
{
    if (!_conversationBtn) {
        _conversationBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        _conversationBtn.frame = CGRectMake(self.view.bounds.size.width / 2 - self.view.bounds.size.width / 10 , 60, self.view.bounds.size.width / 5, 30);
        [_conversationBtn setTitle:@"切换" forState:(UIControlStateNormal)];
        [_conversationBtn addTarget:self action:@selector(conversationAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _conversationBtn;
}

#pragma mark - 切换摄像头

- (void)conversationAction:(UIButton *)btn
{
    
    NSUInteger cameraCount = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo].count;
    if (cameraCount > 1)
    {
        NSError *error;
        
        CATransition *animation = [CATransition animation];
        animation.duration = .5;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.type = @"oglFlip";
        
        AVCaptureDevice *newCamera = nil;
        AVCaptureDeviceInput *newInput = nil;
        AVCaptureDevicePosition  postion = self.input.device.position;
        if (postion == AVCaptureDevicePositionBack) {
            newCamera = [self cameraWithPosition:(AVCaptureDevicePositionFront)];
            animation.subtype = kCATransitionFromLeft;
        }
        if (postion == AVCaptureDevicePositionFront) {
            newCamera = [self cameraWithPosition:(AVCaptureDevicePositionBack)];
            animation.type = kCATransitionFromRight;
        }
        newInput = [AVCaptureDeviceInput deviceInputWithDevice:newCamera error:&error];
        [self.preViewLayer addAnimation:animation forKey:nil];
        
        if (newInput)
        {
            [self.session beginConfiguration];
            
            [self.session removeInput:self.input];
            
            if ([self.session canAddInput:newInput])
            {
                [self.session addInput:newInput];
                self.input = newInput;
            }else
            {
                [self.session addInput:self.input];
            }
            [self.session commitConfiguration];
        }else if(error){
            NSLog(@"%@",error);
        }

        
    }

}

- (void)getPhoto
{
    [self photoBtnDidClick];
}

- (UIImageView *)cameraImageView
{
    if (!_cameraImageView) {
        _cameraImageView = [[UIImageView alloc]initWithFrame:self.view.bounds];
        _cameraImageView.userInteractionEnabled = YES;
        
        if (_saveImageBtn) {
            [_saveImageBtn removeFromSuperview];
        }
        self.saveImageBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [self.saveImageBtn setTitle:@"保存" forState:(UIControlStateNormal)];
        self.saveImageBtn.frame = CGRectMake(_cameraImageView.bounds.size.width / 6 * 5, _cameraImageView.bounds.size.height  / 9 * 8, _cameraImageView.bounds.size.width / 6, _cameraImageView.bounds.size.height / 9);
        [_cameraImageView addSubview:self.saveImageBtn];
        [self.saveImageBtn addTarget:self action:@selector(saveimage:) forControlEvents:(UIControlEventTouchUpInside)];
        
        if (_remakeBtn) {
            [_remakeBtn removeFromSuperview];
        }
        self.remakeBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [self.remakeBtn setTitle:@"重拍" forState:(UIControlStateNormal)];
        self.remakeBtn.frame = CGRectMake(10, self.saveImageBtn.frame.origin.y, self.saveImageBtn.frame.size.width, self.saveImageBtn.bounds.size.height);
        [_cameraImageView addSubview:self.remakeBtn];
        [self.remakeBtn addTarget:self action:@selector(remakeAction:) forControlEvents:(UIControlEventTouchUpInside)];
        
    }
    return _cameraImageView;
}

- (void)setSubViews
{
    [self.view addSubview:self.photoClick];
    [self.view addSubview:self.conversationBtn];
}

- (void)saveimage:(UIButton *)btn
{
    [self saveImageToPhotoAlbum:self.image];
    [self.session startRunning];
    [self.cameraImageView removeFromSuperview];
}

- (void)remakeAction:(UIButton *)btn
{
    [self.session startRunning];
    [self.cameraImageView removeFromSuperview];
}

#pragma mark - viewDidLoad

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self cameraDistrict];
    [self setSubViews];
    
    // 聚焦~
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(focusCamera:)];
    [self.view addGestureRecognizer:tap];
}


#pragma mark - 聚焦实现
- (void)focusCamera:(UITapGestureRecognizer *)tap
{
    [self focusAtPoint:[tap locationInView:tap.view]];
}

/*!
 *  根据前后位置拿到对应的摄像头
 *
 *  @param position
 *
 *  @return
 */
- (AVCaptureDevice * )cameraWithPosition:(AVCaptureDevicePosition)position
{
    NSArray *devices = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    for (AVCaptureDevice *device in devices)
    {
        if (device.position == position) {
            return device;
        }
    }
    return nil;
}


#pragma mark - 相机实现
/*!
 *  初始化各个对象
 */
- (void)cameraDistrict
{
    // AVCaptureDevicePositionBack      后置摄像头
    // AVCaptureDevicePositionFront      前置摄像头
    
    self.device = [self cameraWithPosition:(AVCaptureDevicePositionBack)];
    self.input = [[AVCaptureDeviceInput alloc] initWithDevice:self.device error:nil];
    
    self.imageOutput = [[AVCaptureStillImageOutput alloc] init];
    self.session = [[AVCaptureSession alloc]init];
    
    // 拿到的图像的大小可以自行设定
    //    AVCaptureSessionPreset320x240
    //    AVCaptureSessionPreset352x288
    //    AVCaptureSessionPreset640x480
    //    AVCaptureSessionPreset960x540
    //    AVCaptureSessionPreset1280x720
    //    AVCaptureSessionPreset1920x1080
    //    AVCaptureSessionPreset3840x2160
    self.session.sessionPreset = AVCaptureSessionPreset1280x720;
    
    // 输入,输出设备结合起来
    if ([self.session canAddInput:self.input]) {
        [self.session addInput:self.input];
    }
    
    if ([self.session canAddOutput:self.imageOutput]) {
        [self.session addOutput:self.imageOutput];
    }

    // 预览层的生成
    self.preViewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.session];
    self.preViewLayer.frame = self.view.bounds;
    self.preViewLayer.videoGravity = AVLayerVideoGravityResizeAspectFill;
    [self.view.layer addSublayer:self.preViewLayer];
    
    // 设备开始取景
    [self.session startRunning];
    if ([_device lockForConfiguration:nil]) {
        
        // 自动闪光灯
        if ([_device isFlashModeSupported:(AVCaptureFlashModeAuto)]) {
            [_device setFlashMode:(AVCaptureFlashModeAuto)];
        }
#warning \
        // 自动白平衡, 但是好像一直都进不去
        if ([_device isWhiteBalanceModeSupported:(AVCaptureWhiteBalanceModeAutoWhiteBalance)])
        {
            [_device setWhiteBalanceMode:(AVCaptureWhiteBalanceModeAutoWhiteBalance)];
        }
        [_device unlockForConfiguration];
    }
}

#pragma mark -- 拍照相关

/*!
 *  拍照
 */
- (void)photoBtnDidClick
{
    AVCaptureConnection *connection = [self.imageOutput connectionWithMediaType:AVMediaTypeVideo];
    if (!connection) {
        NSLog(@"拍照失败");
        return;
    }
    
    [self.imageOutput captureStillImageAsynchronouslyFromConnection:connection completionHandler:^(CMSampleBufferRef imageDataSampleBuffer, NSError *error) {
        if (!imageDataSampleBuffer) {
            return ;
        }
        NSData *imageData = [AVCaptureStillImageOutput jpegStillImageNSDataRepresentation:imageDataSampleBuffer];
        self.image = [UIImage imageWithData:imageData];
        [self.session stopRunning];
        [self.view addSubview:self.cameraImageView];
        
    }];
}

/*!
 *  保存图片到相册
 */

- (void)saveImageToPhotoAlbum:(UIImage *)saveImage
{
    UIImageWriteToSavedPhotosAlbum(saveImage, self, @selector(image:didFinishSavingWithError:contextInfo:), nil);
}

// 指定的回调方法.固定格式 (API有)
- (void)image:(UIImage *)image didFinishSavingWithError:(NSError *)error contextInfo:(void *)context
{
    
    NSString *msg = nil;
    if (error !=nil)
    {
        msg = @"保存图片失败";
    }else
    {
        msg = @"保存图片成功";
    }
    NSLog(@"%@",msg);
    
    CGRect rect = [msg boundingRectWithSize:CGSizeMake(NSIntegerMax, 0) options:(NSStringDrawingUsesLineFragmentOrigin) attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:18]} context:nil];
    NSLog(@"%f",rect.size.width);
    
    UILabel *label = [[UILabel alloc] init];
    label.layer.masksToBounds = YES;
    label.frame = CGRectMake(0, 0, rect.size.width + 20, 40);
    label.center = self.view.center;
    label.text = msg;
    label.layer.cornerRadius = 10.0;
    label.textAlignment = NSTextAlignmentCenter;
    label.font = [UIFont systemFontOfSize:18];
    label.textColor = [UIColor colorWithRed:1.000 green:0.257 blue:0.255 alpha:1.000];
    label.backgroundColor = [[UIColor colorWithWhite:0.337 alpha:1.000] colorWithAlphaComponent:0.9];
    [self.view addSubview:label];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [label removeFromSuperview];
    });
    
}

#pragma mark -- 聚焦

- (void)focusAtPoint:(CGPoint )point
{
    CGSize size = self.view.bounds.size;
    CGPoint focusPoint = CGPointMake(point.x / size.width,point.y / size.height);
    NSError *error;
    if ([self.device lockForConfiguration:&error])
    {
        // 自动聚焦
        if ([self.device isFocusModeSupported:(AVCaptureFocusModeAutoFocus)])
        {
            [self.device setFocusMode:(AVCaptureFocusModeAutoFocus)];
            [self.device setFocusPointOfInterest:focusPoint];
        }
        // 触摸
        if ([self.device isExposureModeSupported:(AVCaptureExposureModeAutoExpose)])
        {
            [self.device setExposureMode:(AVCaptureExposureModeAutoExpose)];
            [self.device setExposurePointOfInterest:focusPoint];
        }
        
        [self.device unlockForConfiguration];
        if (!self.focusView)
        {
            [self.focusView removeFromSuperview];
        }
        self.focusView.center = point;
        [self.view addSubview:self.focusView];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.focusView.transform = CGAffineTransformMakeScale(0.75, 0.75);
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:0.3 animations:^{
                self.focusView.transform = CGAffineTransformIdentity;
            } completion:^(BOOL finished) {
               
                [self.focusView removeFromSuperview];
            }];
        }];
    }
}



@end
