//
//  SZPlayer.m
//  SZPlayer
//
//  Created by 又土又木 on 16/5/25.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "SZPlayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>

//获取设备的物理宽高
#define SZScreenW [[UIScreen mainScreen] bounds].size.width
//屏幕高度
#define SZScreenH [[UIScreen mainScreen] bounds].size.height

static const CGFloat topViewH = 45;
static const CGFloat bottomViewH = 45;

@interface SZPlayer ()
{
    CGRect _frame;
}

@property (copy, nonatomic) NSString *videoURL;

//播放核心组件
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

//顶部view
@property (strong, nonatomic) UIImageView *topView;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UILabel *titleLabel;

//底部view
@property (strong, nonatomic) UIImageView *bottomView;
@property (strong, nonatomic) UIButton *playOrPauseButton;
@property (strong, nonatomic) UILabel *videoTimeLabel;
@property (strong, nonatomic) UILabel *videoDurationLabel;
@property (strong, nonatomic) UISlider *videoSlider;
@property (strong, nonatomic) UIProgressView *videoProgressView;
@property (strong, nonatomic) UIButton *fullScreenButton;

@property (assign, nonatomic) NSTimeInterval currentTime;           //记录当前播放时间或者被拖动到的时间点
@property (assign, nonatomic) NSTimeInterval videoDuration;         //视频总时长

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (assign, nonatomic) BOOL isPlayed;                        //视频是否正在播放
@property (assign, nonatomic) BOOL isTouchDownVideoSlider;          //用户是否正在拖动底部滑块
@property (assign, nonatomic) BOOL hideAroundingViews;              //是否显示上下view

@property (assign, nonatomic) BOOL isFullScreenPlay;                //是否是全屏显示

@end

@implementation SZPlayer

- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSString *)videoURL
{
    if (self = [super initWithFrame:frame]) {
        
        _videoURL = videoURL;
        _frame = frame;
        _isPlayed = YES;
        self.backgroundColor = [UIColor blackColor];
        
        [self.layer addSublayer:self.playerLayer];
        
        [self addSubview:self.topView];
        
        [self addSubview:self.bottomView];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(videolayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        
        //添加轻击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen)];
        [self addGestureRecognizer:tap];
    }
    return self;
}

#pragma mark ----------------topView
- (UIImageView *)topView
{
    if (_topView) {
        return _topView;
    }
    _topView = [[UIImageView alloc] init];
    _topView.userInteractionEnabled = YES;
    _topView.backgroundColor = [UIColor blueColor];
//    _topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
    _topView.frame = CGRectMake(0, 0, _frame.size.width, topViewH);
    [_topView addSubview:self.backButton];
    [_topView addSubview:self.titleLabel];
    
    return _topView;
}
- (UIButton *)backButton
{
    if (_backButton) {
        return _backButton;
    }
    _backButton = [UIButton buttonWithType:UIButtonTypeSystem];
    CGFloat backButtonWH = 40;
    _backButton.frame = CGRectMake(10, (topViewH - backButtonWH) *0.5, backButtonWH, backButtonWH);
    [_backButton setTitle:@"返回" forState:UIControlStateNormal];
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return _backButton;
}
- (UILabel *)titleLabel
{
    if (_titleLabel) {
        return _titleLabel;
    }
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"精彩的视频";
    _titleLabel.font = [UIFont systemFontOfSize:18];
    _titleLabel.textColor = [UIColor whiteColor];
    _titleLabel.frame = CGRectMake(CGRectGetMaxX(_backButton.frame) + 30, 0, _frame.size.width - CGRectGetMaxX(_backButton.frame), topViewH);
    return _titleLabel;
}

#pragma mark ------------bottomView
- (UIImageView *)bottomView
{
    if (_bottomView) {
        return _bottomView;
    }
    _bottomView = [[UIImageView alloc] init];
    _bottomView.userInteractionEnabled = YES;
    _bottomView.backgroundColor = [UIColor blueColor];
    _bottomView.frame = CGRectMake(0, _frame.size.height - bottomViewH, _frame.size.width, bottomViewH);
    
    [_bottomView addSubview:self.playOrPauseButton];
    [_bottomView addSubview:self.videoTimeLabel];
    [_bottomView addSubview:self.videoProgressView];
    [_bottomView addSubview:self.videoSlider];
    [_bottomView addSubview:self.videoDurationLabel];
    [_bottomView addSubview:self.fullScreenButton];
    
    return _bottomView;
}

- (UIButton *)playOrPauseButton
{
    if (_playOrPauseButton) {
        return _playOrPauseButton;
    }
    _playOrPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
    CGFloat playButtonWH = 40;
    
    _playOrPauseButton.frame = CGRectMake(10, (bottomViewH - playButtonWH) *0.5, playButtonWH, playButtonWH);
    [_playOrPauseButton setBackgroundImage:[UIImage imageNamed:@"ad_play_p"] forState:UIControlStateNormal];
    [_playOrPauseButton setBackgroundImage:[UIImage imageNamed:@"ad_pause_p"] forState:UIControlStateSelected];
    [_playOrPauseButton addTarget:self action:@selector(playOrPause) forControlEvents:UIControlEventTouchUpInside];
    _playOrPauseButton.contentMode = UIViewContentModeScaleAspectFit;
    _playOrPauseButton.selected = YES;
    return _playOrPauseButton;
}

- (UILabel *)videoTimeLabel
{
    if (_videoTimeLabel) {
        return _videoTimeLabel;
    }
    _videoTimeLabel = [[UILabel alloc] init];
    _videoTimeLabel.font = [UIFont systemFontOfSize:12.0];
    _videoTimeLabel.textColor = [UIColor whiteColor];
    _videoTimeLabel.text = @"00:00:00";
    _videoTimeLabel.textAlignment = NSTextAlignmentCenter;
    _videoTimeLabel.frame = CGRectMake(CGRectGetMaxX(_playOrPauseButton.frame), 0, 60, bottomViewH);
    return _videoTimeLabel;
}
- (UILabel *)videoDurationLabel
{
    if (_videoDurationLabel) {
        return _videoDurationLabel;
    }
    _videoDurationLabel = [[UILabel alloc] init];
    _videoDurationLabel.font = [UIFont systemFontOfSize:12.0];
    _videoDurationLabel.textColor = [UIColor whiteColor];
    _videoDurationLabel.text = @"00:00:00";
    _videoDurationLabel.textAlignment = NSTextAlignmentCenter;
    _videoDurationLabel.frame = CGRectMake(CGRectGetMaxX(_videoProgressView.frame), 0, _videoTimeLabel.bounds.size.width, _videoTimeLabel.bounds.size.height);
    return _videoDurationLabel;
}

- (UIProgressView *)videoProgressView
{
    if (_videoProgressView) {
        return _videoProgressView;
    }
    _videoProgressView = [[UIProgressView alloc] init];
    CGFloat progressViewY = (bottomViewH - 2 )* 0.5;
    _videoProgressView.frame = CGRectMake(CGRectGetMaxX(_videoTimeLabel.frame), progressViewY, 100, bottomViewH);
    return _videoProgressView;
}
- (UISlider *)videoSlider
{
    if (_videoSlider) {
        return _videoSlider;
    }
    _videoSlider = [[UISlider alloc] init];
    _videoSlider.frame = _videoProgressView.frame;
    [_videoSlider setThumbImage:[UIImage imageNamed:@"progressThumb"] forState:UIControlStateNormal];
    [_videoSlider setThumbImage:[UIImage imageNamed:@"progressThumb"] forState:UIControlStateHighlighted];
    UIGraphicsBeginImageContextWithOptions((CGSize){ 1, 1 }, NO, 0.0f);
    UIImage *transparentImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    [_videoSlider setMinimumTrackImage:transparentImage forState:UIControlStateNormal];
    [_videoSlider setMaximumTrackImage:transparentImage forState:UIControlStateNormal];
    // slider开始滑动事件
    [_videoSlider addTarget:self action:@selector(videoSliderBeginDragging) forControlEvents:UIControlEventTouchDown];
    // slider滑动中事件
    [_videoSlider addTarget:self action:@selector(videoSliderDragging) forControlEvents:UIControlEventValueChanged];
    // slider结束滑动事件
    [_videoSlider addTarget:self action:@selector(videoSliderEndDragging) forControlEvents:UIControlEventTouchUpInside | UIControlEventTouchCancel | UIControlEventTouchUpOutside];
    return _videoSlider;
}

- (UIButton *)fullScreenButton
{
    if (_fullScreenButton) {
        return _fullScreenButton;
    }
    _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [_fullScreenButton setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [_fullScreenButton setImage:[UIImage imageNamed:@"nonfullscreen"] forState:UIControlStateSelected];
    _fullScreenButton.frame = CGRectMake(CGRectGetMaxX(_videoDurationLabel.frame), 0, bottomViewH, bottomViewH);
    [_fullScreenButton addTarget:self action:@selector(fullScreenClick:) forControlEvents:UIControlEventTouchUpInside];
    return _fullScreenButton;
}


#pragma mark --------核心组件
- (AVPlayerLayer *)playerLayer
{
    if (_playerLayer) {
        return _playerLayer;
    }
    AVAudioSession *audioSesstion = [AVAudioSession sharedInstance];
    [audioSesstion setActive:YES error:NULL];
    [audioSesstion setCategory:AVAudioSessionCategoryPlayback error:nil];
    
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:self.videoURL]];
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self addObserver];
    _player = [[AVPlayer alloc] initWithPlayerItem:_playerItem];
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:_player];
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    _playerLayer.frame = self.layer.bounds;
    [_player play];
    return _playerLayer;
}

#pragma mark - 监听self.playerItem
- (void)addObserver
{
    //监听视频准备情况
    [_playerItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionNew context:nil];
    //缓冲进度
    [_playerItem addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    //seekToTime后，缓冲数据为空，而且有效时间内数据无法补充，播放失败
    [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:NSKeyValueObservingOptionNew context:nil];
    [_playerItem addObserver:self forKeyPath:@"playbackLikelyToKeepUp" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - APlayerItem属性变化回调
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if ([keyPath isEqualToString:@"status"]) {
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            NSLog(@"准备播放");
            //获取总时长
            CMTime duration = self.playerItem.duration;
            _videoDuration = CMTimeGetSeconds(duration);
            //更新UI
            [self updateVideoDuration];
            
            //设置slider最大值
            self.videoSlider.maximumValue = _videoDuration;

            //监听播放进度
            [self monitorVideoPlaying];
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]){
        if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
            
            //更显缓冲区
            self.videoProgressView.progress = [self videoBufferDuration] / _videoDuration;
        }
    }
    else if ([keyPath isEqualToString:@"playbackBufferEmpty"]){
        NSLog(@"卡主啦");
        //视频卡主
    }else if ([keyPath isEqualToString:@"playbackLikelyToKeepUp"]){
        NSLog(@"走起");
    }
}

#pragma mark - 监听播放进度
- (void)monitorVideoPlaying
{
    __weak typeof(self) weakSelf = self;
    Float64 interval = 0.5 *  _videoDuration / self.videoSlider.bounds.size.width;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        
        if (!weakSelf.isTouchDownVideoSlider) {
            _currentTime = CMTimeGetSeconds(weakSelf.playerItem.currentTime);
            [weakSelf updateVideoTime];
            [weakSelf updateBottomSlider];
        }
    }];
}

- (NSTimeInterval)videoBufferDuration {
    NSArray *loadedTimeRanges = [[_player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [loadedTimeRanges.firstObject CMTimeRangeValue];// 获取缓冲区域
    float startSeconds = CMTimeGetSeconds(timeRange.start);
    float durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

#pragma mark - update
- (void)updateVideoDuration
{
    self.videoDurationLabel.text = [self convertTime:_videoDuration];
}
- (void)updateVideoTime
{
    self.videoTimeLabel.text = [self convertTime:_currentTime];
}
- (void)updateBottomSlider
{
    self.videoSlider.value = _currentTime;
}

#pragma mark ************************event***********************
#pragma mark 播放或暂停
- (void)playOrPause
{
    self.playOrPauseButton.selected = !self.playOrPauseButton.isSelected;
    if (_isPlayed) {
        [self.player pause];
    }else{
        [self.player play];
    }
    _isPlayed = !_isPlayed;
}

#pragma mark 拖动底部滑块
- (void)videoSliderBeginDragging
{
    _isTouchDownVideoSlider = YES;
}
- (void)videoSliderDragging
{
    _isTouchDownVideoSlider = YES;
    //更改当前时间
    _currentTime = _videoSlider.value;
    [self updateVideoTime];
}
- (void)videoSliderEndDragging
{
    _isTouchDownVideoSlider = NO;
    [self.player seekToTime:CMTimeMakeWithSeconds(_currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        NSLog(@"跳转完毕");
    }];
}

#pragma mark - 轻击屏幕
- (void)tapScreen
{
    _hideAroundingViews = !_hideAroundingViews;
    if (_hideAroundingViews) {
        [UIView animateWithDuration:0.2 animations:^{
            self.topView.alpha = 0;
            self.bottomView.alpha = 0;
        }];
    }else{
        [UIView animateWithDuration:0.2 animations:^{
            self.topView.alpha = 1;
            self.bottomView.alpha = 1;
        }];
    }
}

#pragma mark ***********************notification***********************
- (void)videolayDidEnd:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        
        [weakSelf.videoSlider setValue:0.0 animated:YES];
        weakSelf.playOrPauseButton.selected = NO;
        weakSelf.isPlayed = NO;
    }];
}


- (void)fullScreenClick:(UIButton *)sender
{
    if (!_isFullScreenPlay) {
        self.transform = CGAffineTransformIdentity;
        self.transform = CGAffineTransformMakeRotation(M_PI / 2);
        self.frame = CGRectMake(0, 0, SZScreenW, SZScreenH);
        self.playerLayer.frame = CGRectMake(0,0, SZScreenH,SZScreenW);
        [self setupSubViewFrames];
        
        [[UIApplication sharedApplication].keyWindow addSubview:self];
        self.isFullScreenPlay = YES;
    }else{
        self.transform = CGAffineTransformIdentity;
        self.frame = _frame;
        self.playerLayer.frame =  self.bounds;
        _topView.frame = CGRectMake(0, 0, _frame.size.width, topViewH);
        _bottomView.frame = CGRectMake(0, _frame.size.height - bottomViewH, _frame.size.width, bottomViewH);
        NSLog(@"%@", NSStringFromCGRect(_topView.frame));
        self.isFullScreenPlay = NO;
    }
    
}



- (void)setupSubViewFrames
{
    self.topView.frame = CGRectMake(0,0 ,SZScreenH, topViewH);
    
    self.bottomView.frame = CGRectMake(0, SZScreenW - bottomViewH, SZScreenH, bottomViewH);
    
}



#pragma mark - converTime
- (NSString *)convertTime:(CGFloat)second{
    NSDate *d = [NSDate dateWithTimeIntervalSince1970:second];
    if (second/3600 >= 1) {
        [self.dateFormatter setDateFormat:@"HH:mm:ss"];
    } else {
        [self.dateFormatter setDateFormat:@"mm:ss"];
    }
    NSString *showtimeNew = [self.dateFormatter stringFromDate:d];
    return showtimeNew;
}

- (NSDateFormatter *)dateFormatter {
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    return _dateFormatter;
}


-(void)dealloc
{
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
    
    [self.player.currentItem cancelPendingSeeks];
    [self.player.currentItem.asset cancelLoading];
    [self.player pause];
    [self removeFromSuperview];
    [self.playerLayer removeFromSuperlayer];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    self.player = nil;
    self.playerItem = nil;
    self.playerLayer = nil;
}


@end
