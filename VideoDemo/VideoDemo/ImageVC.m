//
//  ImageVC.m
//  VideoDemo
//
//  Created by ZhongXiaoLong on 2018/1/15.
//  Copyright © 2018年 zhongxiaolong. All rights reserved.
//

#import "ImageVC.h"
#import <Masonry/Masonry.h>
#import "XLImageFilter.h"
#import "PGImageUtility.h"
#import "UIImage+Utility.h"

@interface ImageVC ()<UINavigationControllerDelegate, UIImagePickerControllerDelegate>

@property (nonatomic) UIImageView *imageView;

@end

@implementation ImageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.

    self.view.backgroundColor = [UIColor whiteColor];
    self.title = @"图像处理";

    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];

    imageView.userInteractionEnabled = YES;
    imageView.contentMode = UIViewContentModeScaleAspectFit;

    UITapGestureRecognizer *tapGs = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                            action:@selector(imageTaped:)];
    [imageView addGestureRecognizer:tapGs];

    [self.view addSubview:imageView];
    self.imageView = imageView;

    [imageView mas_makeConstraints:^(MASConstraintMaker *make) {

        make.top.equalTo(self.view).offset(80);
        make.bottom.equalTo(self.view).offset(-100);
        make.left.equalTo(self.view);
        make.right.equalTo(self.view);
    }];

    UIButton *selectBtn = [UIButton buttonWithType:UIButtonTypeSystem];

    selectBtn.titleLabel.font = [UIFont systemFontOfSize:24];
    [selectBtn setTitle:@"选择图片" forState:UIControlStateNormal];
    [selectBtn addTarget:self
                  action:@selector(selectBtnPressed:)
        forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:selectBtn];

    [selectBtn mas_makeConstraints:^(MASConstraintMaker *make) {

        make.centerX.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-50);
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)selectBtnPressed:(id)sender
{
    UIImagePickerController *picker = [[UIImagePickerController alloc] init];

    picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

- (void)imageTaped:(UITapGestureRecognizer *)tapGs
{
    [self filterImage:self.imageView.image];
}

- (void)filterImage:(UIImage *)image
{
    if (image == nil)
    {
        return;
    }

    //1.灰度图
//    UIImage *retImage =  [[XLImageFilter shared] imageToGray:image];

    //2.双重曝光
//    NSString *path = [[NSBundle mainBundle] pathForResource:@"double" ofType:@"jpg"];
//    UIImage *testImage = [[UIImage alloc] initWithContentsOfFile:path];
//    UIImage *retImage = [[XLImageFilter shared] doubleImage:image
//                                                secondImage:testImage];

    //3.高斯模糊
//    UIImage *retImage = [[XLImageFilter shared] gaussImage:image];

    //4.获取图像轮廓
    UIImage *retImage = [[XLImageFilter shared] findContoursImage:image];

    self.imageView.image = retImage;
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info
{
    NSLog(@"image select info = %@", info);
    UIImage *orgImage = [info objectForKey:UIImagePickerControllerOriginalImage];

    orgImage = [PGImageUtility fixImageOrientation:orgImage];
    self.imageView.image = orgImage;
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
