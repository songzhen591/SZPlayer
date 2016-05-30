//
//  SZPlayer.h
//  SZPlayer
//
//  Created by 又土又木 on 16/5/25.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import <UIKit/UIKit.h>


extern NSString *const SZFullScreenBtnNotification;

@class SZPlayer;
@class AVPlayer;
@protocol SZPlayerDelegate <NSObject>


@optional
/**
 *  视频播放到的时间
 */
- (void)videoDidPlayingOnTime:(NSTimeInterval)time;

/**
 *  点击返回（关闭）按钮
 */
- (void)tapVideoBack;

@end

@interface SZPlayer : UIView

//视频title
@property (copy, nonatomic) NSString *videoName;

//视频url
@property (copy, nonatomic) NSString *videoURL;

@property (assign, nonatomic) id<SZPlayerDelegate>delegate;

//开始播放
- (void)play;

//暂停播放
- (void)pause;

//小屏显示
- (void)toDetailView:(UIView *)view;

//全屏显示
- (void)toFullScreen;

//页面销毁时需要调用彻底释放播放器
- (void)releaseSZPlayer;


@end
