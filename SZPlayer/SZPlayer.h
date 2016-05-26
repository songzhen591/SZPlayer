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

@property (strong, nonatomic) AVPlayer *player;

@property (copy, nonatomic) NSString *videoName;
@property (copy, nonatomic) NSString *videoURL;

@property (assign, nonatomic) id<SZPlayerDelegate>delegate;

/**
 *  自定义播放器的frame
 */
- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSString *)videoURL;

/**
 *  播放器的横向全屏
 */
- (instancetype)initFullSvreenPlayerVideoURL:(NSString *)videoURL;

- (void)play;

- (void)pause;


@end
