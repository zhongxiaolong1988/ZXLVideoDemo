//
//  XLTipsView.m
//  VideoDemo
//
//  Created by ZhongXiaoLong on 16/10/20.
//  Copyright © 2016年 zhongxiaolong. All rights reserved.
//

#import "XLTipsView.h"

static XLTipsView *s_TipsView = NULL;

@interface XLTipsView ()
{

}
@property (nonatomic) UILabel *mTipsLabel;
@end

@implementation XLTipsView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];

    if (self)
    {
        [self initUI];
    }

    return self;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];

    if (self)
    {
        [self initUI];
    }

    return self;
}

- (void)initUI
{
    self.backgroundColor = [UIColor colorWithWhite:0 alpha:0.1];

    static const CGFloat kCenterViewWidth = 200;
    static const CGFloat kCenterViewHeight = 200;

    UIView *centerView = [[UIView alloc] initWithFrame:CGRectMake((self.bounds.size.width - kCenterViewWidth) / 2,
                                                                  (self.bounds.size.height - kCenterViewHeight) / 2,
                                                                  kCenterViewWidth,
                                                                  kCenterViewHeight)];

    centerView.backgroundColor = [UIColor colorWithWhite:0 alpha:0.5];
    [self addSubview:centerView];

    UILabel *tipsLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 40, 180, 100)];

    tipsLabel.numberOfLines = 3;
    tipsLabel.textAlignment = NSTextAlignmentCenter;
    tipsLabel.font = [UIFont systemFontOfSize:18];
    tipsLabel.textColor = [UIColor whiteColor];
    [centerView addSubview:tipsLabel];
    self.mTipsLabel = tipsLabel;

    UIButton *cancelBtn = [UIButton buttonWithType:UIButtonTypeSystem];

    [cancelBtn setFrame:CGRectMake(50, 140, 100, 40)];
    cancelBtn.titleLabel.font = [UIFont systemFontOfSize:18];
    [cancelBtn setTitle:@"取消" forState:UIControlStateNormal];
    [cancelBtn addTarget:self
                  action:@selector(handleBtnPressed:)
        forControlEvents:UIControlEventTouchUpInside];
    [centerView addSubview:cancelBtn];
}

- (void)handleBtnPressed:(UIButton *)button
{
    //取消按钮被点击
    if (self.cancelBlock)
    {
        self.cancelBlock();
    }
}

+ (void)showInView:(UIView *)view cancelBlock:(void (^)(void))cancelBlock
{
    if (s_TipsView != nil)
    {
        [s_TipsView removeFromSuperview];
        s_TipsView = nil;
    }

    if (view == nil)
    {
        view = [UIApplication sharedApplication].windows[0];
    }

    dispatch_async(dispatch_get_main_queue(), ^{
        s_TipsView = [[XLTipsView alloc] initWithFrame:view.bounds];

        s_TipsView.cancelBlock = cancelBlock;
        [view addSubview:s_TipsView];
    });
}

+ (void)setText:(NSString *)aText
{
    dispatch_async(dispatch_get_main_queue(), ^{
        s_TipsView.mTipsLabel.text = aText;
    });
}

+ (void)dismiss
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [s_TipsView removeFromSuperview];
        s_TipsView = nil;
    });
}

@end
