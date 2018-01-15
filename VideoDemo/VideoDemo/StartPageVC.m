//
//  StartPageVC.m
//  VideoDemo
//
//  Created by ZhongXiaoLong on 2018/1/15.
//  Copyright © 2018年 zhongxiaolong. All rights reserved.
//

#import "StartPageVC.h"
#import "VideoVC.h"
#import "ImageVC.h"

@interface StartPageVC ()

@end

@implementation StartPageVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)imageBtnPressed:(id)sender
{
    ImageVC *imageVC = [[ImageVC alloc] init];

    [self.navigationController pushViewController:imageVC animated:YES];
}

- (IBAction)videoBtnPressed:(id)sender
{
    VideoVC *videoVC = [[VideoVC alloc] init];

    [self.navigationController pushViewController:videoVC animated:YES];
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
