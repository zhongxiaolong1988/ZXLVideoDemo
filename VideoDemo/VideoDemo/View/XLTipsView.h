//
//  XLTipsView.h
//  VideoDemo
//
//  Created by ZhongXiaoLong on 16/10/20.
//  Copyright © 2016年 zhongxiaolong. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface XLTipsView : UIView
{

}
//取消按钮被点击
@property (nonatomic, copy) void (^cancelBlock)();

/**
 在view中显示

 @param view        superview
 @param cancelBlock 取消按钮回调
 */
+ (void)showInView:(UIView *)view
       cancelBlock:(void(^)(void))cancelBlock;

/**
 设置提示文字

 @param aText 提示文字
 */
+ (void)setText:(NSString *)aText;

/**
 消失，和显示函数配对使用
 */
+ (void)dismiss;
@end
