//
//  SZPlayer.h
//  SZPlayer
//
//  Created by 又土又木 on 16/5/25.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SZPlayer;
@class AVPlayer;
@protocol SZPlayerDelegate <NSObject>

@optional
/**
 *  视频播放到的时间
 */
- (void)videoDidPlayingOnTime:(NSTimeInterval)time;



@end

@interface SZPlayer : UIView

@property (strong, nonatomic) AVPlayer *player;

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
