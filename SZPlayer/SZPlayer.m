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

//手势滑动，方向是以视频播放器为基准的，不是以屏幕
typedef NS_ENUM(NSUInteger, PanGestureRecognizerDirection) {
    PanGestureRecognizerDirectionUp,
    PanGestureRecognizerDirectionDown,
    PanGestureRecognizerDirectionLeft,
    PanGestureRecognizerDirectionRight
};

static const CGFloat topViewH = 45;
static const CGFloat bottomViewH = 45;
static const CGFloat rateViewW = 120;
static const CGFloat rateViewH = 80;

@interface SZPlayer ()
{
    CGRect _frame;
}



//播放核心组件
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) AVPlayerItem *playerItem;
@property (strong, nonatomic) AVPlayerLayer *playerLayer;

//顶部view
@property (strong, nonatomic) UIImageView *topView;
@property (strong, nonatomic) UIButton *backButton;
@property (strong, nonatomic) UILabel *titleLabel;


//全屏水平滑动时显示的view
@property (strong, nonatomic) UIView *rateView;
@property (strong, nonatomic) UIImageView *rateImageView;
@property (strong, nonatomic) UILabel *rateTimeLabel;

//底部view
@property (strong, nonatomic) UIImageView *bottomView;
@property (strong, nonatomic) UIButton *playOrPauseButton;
@property (strong, nonatomic) UILabel *videoTimeLabel;
@property (strong, nonatomic) UILabel *videoDurationLabel;
@property (strong, nonatomic) UISlider *videoSlider;
@property (strong, nonatomic) UIProgressView *videoProgressView;
@property (strong, nonatomic) UIButton *fullScreenButton;

@property (assign, nonatomic) NSTimeInterval currentTime;                       //记录当前播放时间或者被拖动到的时间点
@property (assign, nonatomic) NSTimeInterval videoDuration;                     //视频总时长

@property (strong, nonatomic) NSDateFormatter *dateFormatter;

@property (assign, nonatomic) BOOL isPlayed;                                    //视频是否正在播放
@property (assign, nonatomic) BOOL isTouchDownVideoSliderOrDraggingScreen;      //用户是否正在拖动底部滑块或滑动屏幕
@property (assign, nonatomic) BOOL hideAroundingViews;                          //是否显示上下view

@property (assign, nonatomic) BOOL isFullScreenPlay;                            //是否是全屏显示

@property (strong, nonatomic) id playbackObj;


@property (assign, nonatomic) CGPoint panBeginPoint;                                //滑动初始值
@property (assign, nonatomic) PanGestureRecognizerDirection panDirection;           //滑动方向
@property (strong, nonatomic) UIPanGestureRecognizer *pan;
@property (assign, nonatomic) NSTimeInterval panBeginVideoPlayTime;                 //记录滑动开始时，播放的位置


@end

@implementation SZPlayer

NSString *const SZFullScreenBtnNotification = @"SZFullScreenButtonNotification";


- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        
        _frame = frame;
        _isPlayed = YES;
        
        self.backgroundColor = [UIColor blackColor];
        
        [self addSubview:self.topView];
        
        [self addSubview:self.bottomView];
        
        [self addSubview:self.rateView];
        
        [self.layer insertSublayer:self.playerLayer atIndex:0];
        
        //注册视频播放完毕的通知
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(videolayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
        
        //添加轻击手势
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapScreen)];
        [self addGestureRecognizer:tap];
        
        [self viewDismissAfterSeconds];
    }
    return self;
}

- (void)setVideoName:(NSString *)videoName
{
    _videoName = videoName;
    self.titleLabel.text = videoName;
}

#pragma mark - 设置videoURL
- (void)setVideoURL:(NSString *)videoURL
{
    _videoURL = videoURL;
    
    if (self.playerItem) {
        //移除通知
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
        //移除监听
        [self removeObserverFromCurrentPlayerItem];
    }
    
    //更新数据
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:self.videoURL]];
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset];
    //监听playerItem
    [self addObserverToCurrentPlayerItem];
    //如果self.player存在则替换item
    [self.player replaceCurrentItemWithPlayerItem:self.playerItem];

    // 添加视频播放结束通知
    [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(videolayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

- (AVPlayer *)player
{
    if (_player) {
        return _player;
    }
    _player = [AVPlayer playerWithPlayerItem:self.playerItem];
    return _player;
}
- (AVPlayerItem *)playerItem
{
    if (_playerItem) {
        return _playerItem;
    }
    AVURLAsset *asset = [AVURLAsset assetWithURL:[NSURL URLWithString:self.videoURL]];
    _playerItem = [AVPlayerItem playerItemWithAsset:asset];
    [self addObserverToCurrentPlayerItem];
    return _playerItem;
}
- (AVPlayerLayer *)playerLayer
{
    if (_playerLayer) {
        return _playerLayer;
    }
    _playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    _playerLayer.frame = self.layer.bounds;
    _playerLayer.videoGravity = AVLayerVideoGravityResizeAspect;
    return _playerLayer;
}



#pragma mark - 监听self.playerItem
- (void)addObserverToCurrentPlayerItem
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
            
            [self.player play];
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
    self.playbackObj =  [weakSelf.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval, NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        
        if ([weakSelf.delegate respondsToSelector:@selector(videoDidPlayingOnTime:)]) {
            [weakSelf.delegate videoDidPlayingOnTime:CMTimeGetSeconds(weakSelf.playerItem.currentTime)];
        }
        
        if (!weakSelf.isTouchDownVideoSliderOrDraggingScreen) {
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
    [self.videoSlider setValue:_currentTime animated:YES];
}
- (void)updateRateView
{
    self.rateTimeLabel.text = [NSString stringWithFormat:@"%@ / %@", [self convertTime:self.currentTime] , [self convertTime:self.videoDuration]];
    if (self.panDirection == PanGestureRecognizerDirectionRight) {
        self.rateImageView.image = [UIImage imageNamed:@"player_goforward"];
    }else if (self.panDirection == PanGestureRecognizerDirectionLeft){
        self.rateImageView.image = [UIImage imageNamed:@"player_back"];
    }
}

#pragma mark ************************event***********************
- (void)back
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(tapVideoBack)]) {
        [self.delegate tapVideoBack];
    }
}

#pragma mark 播放或暂停
- (void)playOrPause
{
    [self viewDismissAfterSeconds];
    self.playOrPauseButton.selected = !self.playOrPauseButton.isSelected;
    if (_isPlayed) {
        [self.player pause];
    }else{
        [self.player play];
    }
    _isPlayed = !_isPlayed;
}
- (void)play
{
    [self.player play];
    _isPlayed = YES;
    self.playOrPauseButton.selected = YES;
}
- (void)pause
{
    [self.player pause];
    _isPlayed = NO;
    self.playOrPauseButton.selected = NO;
}

#pragma mark 拖动底部滑块
- (void)videoSliderBeginDragging
{
    _isTouchDownVideoSliderOrDraggingScreen = YES;
    [self viewDismissAfterSeconds];
}
- (void)videoSliderDragging
{
    [self viewDismissAfterSeconds];
    _isTouchDownVideoSliderOrDraggingScreen = YES;
    //更改当前时间
    _currentTime = _videoSlider.value;
    [self updateVideoTime];
}
- (void)videoSliderEndDragging
{
    [self viewDismissAfterSeconds];
    [self.player seekToTime:CMTimeMakeWithSeconds(_currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        _isTouchDownVideoSliderOrDraggingScreen = NO;
    }];
}

#pragma mark - 轻击屏幕
- (void)tapScreen
{
    [self viewDismissAfterSeconds];
    _hideAroundingViews = !_hideAroundingViews;
    if (_hideAroundingViews) {
        [self hideViews];
    }else{
        [self showViews];
    }
}
#pragma mark - 点击全屏
- (void)fullScreenClick:(UIButton *)sender
{
    [self viewDismissAfterSeconds];
    
    if (!_isFullScreenPlay) {
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformIdentity;
            self.transform = CGAffineTransformMakeRotation(M_PI / 2);
            self.frame = CGRectMake(0, 0, SZScreenW, SZScreenH);
            self.playerLayer.frame = CGRectMake(0,0, SZScreenH,SZScreenW);
            [self setupSubViewFrames];
            [[UIApplication sharedApplication].keyWindow addSubview:self];
            self.isFullScreenPlay = YES;
            self.fullScreenButton.selected = YES;
        }];
        
        //全屏模式下添加pan手势
        self.pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(pan:)];
        [self addGestureRecognizer:self.pan];
        
    }else{
        
        
        //移除手势
        [self removeGestureRecognizer:self.pan];
        
        [UIView animateWithDuration:0.2 animations:^{
            self.transform = CGAffineTransformIdentity;
            self.frame = _frame;
            self.playerLayer.frame =  self.bounds;
            self.isFullScreenPlay = NO;
            [self setupSubViewFrames];
            self.fullScreenButton.selected = NO;
        }];
        
    }
    
    //发送全屏通知
    [[NSNotificationCenter defaultCenter] postNotificationName:SZFullScreenBtnNotification object:sender];
}


- (void)pan:(UIPanGestureRecognizer *)pan
{
    CGPoint velocityPoint = [pan velocityInView:self];
    
    switch (pan.state) {
        case UIGestureRecognizerStateBegan:{
            
            self.isTouchDownVideoSliderOrDraggingScreen = YES;
            
            //记录滑动初始值
            self.panBeginPoint = [pan locationInView:self];
            
            self.panBeginVideoPlayTime = self.currentTime;
            
            break;
        }
            
        case UIGestureRecognizerStateChanged:{
            //判断滑动方向
            BOOL isHorizontalPan = (fabs(velocityPoint.x)) > (fabs(velocityPoint.y));
            
            if (isHorizontalPan) {
                
                self.rateView.hidden = NO;
                
                if (velocityPoint.x > 0) {
                    self.panDirection = PanGestureRecognizerDirectionRight;
                }else{
                    self.panDirection = PanGestureRecognizerDirectionLeft;
                }
                
                [self horizontalDraggingOnScreen];
                
            }else{
                if (velocityPoint.y > 0) {
                    self.panDirection = PanGestureRecognizerDirectionDown;
                }else{
                    self.panDirection = PanGestureRecognizerDirectionUp;
                }
            }
            break;
        }
          
        case UIGestureRecognizerStateEnded:{
            
            self.rateView.hidden = YES;
            
            switch (_panDirection) {
                case PanGestureRecognizerDirectionRight: case PanGestureRecognizerDirectionLeft:
                    
                    [self horizontalDragEndOnScreen];
                    break;
                case PanGestureRecognizerDirectionDown: case PanGestureRecognizerDirectionUp:
                    
                    break;
                    
                default:
                    break;
            }
            break;
            
            break;
        }
            
        default:
            break;
    }
}

#pragma mark - 处理手势的水平滑动
- (void)horizontalDraggingOnScreen
{
    
    self.isTouchDownVideoSliderOrDraggingScreen = YES;
    CGFloat changedX = [self.pan locationInView:self].x - self.panBeginPoint.x;
    CGFloat scale = changedX / self.playerLayer.bounds.size.width;
    _currentTime = self.panBeginVideoPlayTime + self.videoSlider.maximumValue * scale;
    
    //保证已播放时间可用
    if (_currentTime < 0) {
        _currentTime = 0;
    }
    if (_currentTime > _videoDuration) {
        _currentTime = _videoDuration;
    }
    
    [self updateBottomSlider];
    [self updateVideoTime];
    [self updateRateView];
    
}
- (void)horizontalDragEndOnScreen
{
    //跳转
    [self viewDismissAfterSeconds];
    [self.player seekToTime:CMTimeMakeWithSeconds(_currentTime, NSEC_PER_SEC) toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero completionHandler:^(BOOL finished) {
        _isTouchDownVideoSliderOrDraggingScreen = NO;
    }];
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

#pragma mark - 更新frame
- (void)setupSubViewFrames
{
    //以self.playerLayer为基准
    self.topView.frame = CGRectMake(0, 0, self.playerLayer.frame.size.width, topViewH);
    self.bottomView.frame = CGRectMake(0, self.playerLayer.frame.size.height - bottomViewH, self.playerLayer.frame.size.width, bottomViewH);
    self.fullScreenButton.frame = CGRectMake(self.playerLayer.frame.size.width - bottomViewH, 0, bottomViewH, bottomViewH);
    self.videoDurationLabel.frame = CGRectMake(self.playerLayer.frame.size.width - self.fullScreenButton.bounds.size.width - self.videoTimeLabel.bounds.size.width, 0, self.videoTimeLabel.bounds.size.width, bottomViewH);
    CGFloat progressViewY = (bottomViewH - 2 )* 0.5;
    CGFloat progressViewW = self.playerLayer.bounds.size.width - CGRectGetMaxX(_videoTimeLabel.frame) - self.videoDurationLabel.frame.size.width - self.fullScreenButton.frame.size.width;
    _videoProgressView.frame = CGRectMake(CGRectGetMaxX(_videoTimeLabel.frame), progressViewY, progressViewW, bottomViewH);
    self.videoSlider.frame = CGRectMake(self.videoProgressView.frame.origin.x, 0, self.videoProgressView.bounds.size.width, bottomViewH);
    
    _rateView.center = CGPointMake(self.playerLayer.bounds.size.width *0.5, self.playerLayer.bounds.size.height *0.5);
}

#pragma mark - 计时隐藏
//做任何操作之前调用此方法，重新计时，3秒后隐藏视图
- (void)viewDismissAfterSeconds
{
    [UIView cancelPreviousPerformRequestsWithTarget:self selector:@selector(hideViews) object:nil];
    [self performSelector:@selector(hideViews) withObject:nil afterDelay:3];
}

- (void)hideViews
{
    [UIView animateWithDuration:0.2 animations:^{
        self.topView.alpha = 0;
        self.bottomView.alpha = 0;
        self.hideAroundingViews = YES;
    }];
}
- (void)showViews
{
    [UIView animateWithDuration:0.2 animations:^{
        self.topView.alpha = 1;
        self.bottomView.alpha = 1;
        self.hideAroundingViews = NO;
    }];
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


- (void)removeObserverFromCurrentPlayerItem
{
    [self.playerItem removeObserver:self forKeyPath:@"status"];
    [self.playerItem removeObserver:self forKeyPath:@"loadedTimeRanges"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackBufferEmpty"];
    [self.playerItem removeObserver:self forKeyPath:@"playbackLikelyToKeepUp"];
}

#pragma mark - 释放
- (void)releaseSZPlayer
{
    [self removeObserverFromCurrentPlayerItem];
    
    //移除此监听一定要提前，防止防止页面已经注销，但仍然对视频进行监控
    [self.player removeTimeObserver:self.playbackObj];
    
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

-(void)dealloc
{
    [self releaseSZPlayer];
}


#pragma mark ----------------topView
- (UIImageView *)topView
{
    if (_topView) {
        return _topView;
    }
    _topView = [[UIImageView alloc] init];
    _topView.userInteractionEnabled = YES;
    _topView.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.7];
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
    [_backButton addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
    return _backButton;
}
- (UILabel *)titleLabel
{
    if (_titleLabel) {
        return _titleLabel;
    }
    _titleLabel = [[UILabel alloc] init];
    _titleLabel.text = @"精彩的视频";
    _titleLabel.font = [UIFont systemFontOfSize:16.0f];
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
    _bottomView.frame = CGRectMake(0, _frame.size.height - bottomViewH, _frame.size.width, bottomViewH);
    _bottomView.backgroundColor = self.topView.backgroundColor;
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
    
    _playOrPauseButton.frame = CGRectMake(0, (bottomViewH - playButtonWH) *0.5, playButtonWH, playButtonWH);
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
    _videoTimeLabel.frame = CGRectMake(CGRectGetMaxX(_playOrPauseButton.frame), 0,60, bottomViewH);
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
    CGFloat durationLabelX = _frame.size.width - CGRectGetWidth(self.fullScreenButton.frame) - _videoTimeLabel.bounds.size.width;
    _videoDurationLabel.frame = CGRectMake(durationLabelX, 0, _videoTimeLabel.bounds.size.width, _videoTimeLabel.bounds.size.height);
    return _videoDurationLabel;
}

- (UIProgressView *)videoProgressView
{
    if (_videoProgressView) {
        return _videoProgressView;
    }
    _videoProgressView = [[UIProgressView alloc] init];
    CGFloat progressViewY = (bottomViewH - 2 )* 0.5;
    CGFloat progressViewW = _frame.size.width - CGRectGetMaxX(_videoTimeLabel.frame) - self.videoDurationLabel.frame.size.width - self.fullScreenButton.frame.size.width;
    _videoProgressView.frame = CGRectMake(CGRectGetMaxX(_videoTimeLabel.frame), progressViewY, progressViewW, bottomViewH);
    return _videoProgressView;
}
- (UISlider *)videoSlider
{
    if (_videoSlider) {
        return _videoSlider;
    }
    _videoSlider = [[UISlider alloc] init];
    _videoSlider.frame = CGRectMake(self.videoProgressView.frame.origin.x, 0, self.videoProgressView.bounds.size.width, bottomViewH);
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
    CGFloat fullScreenButtonWH = bottomViewH;
    CGFloat fullScreenButtonX = _frame.size.width - fullScreenButtonWH;
    _fullScreenButton.frame = CGRectMake(fullScreenButtonX, 0, fullScreenButtonWH, fullScreenButtonWH);
    [_fullScreenButton addTarget:self action:@selector(fullScreenClick:) forControlEvents:UIControlEventTouchUpInside];
    return _fullScreenButton;
}

- (UIView *)rateView
{
    if (_rateView) {
        return _rateView;
    }
    _rateView = [[UIView alloc] init];
    _rateView.backgroundColor = self.topView.backgroundColor;
    _rateView.center = CGPointMake(self.playerLayer.bounds.size.width *0.5, self.playerLayer.bounds.size.height *0.5);
    _rateView.bounds = CGRectMake(0, 0, rateViewW, rateViewH);
    _rateView.hidden = YES;
    
    [_rateView addSubview:self.rateImageView];
    [_rateView addSubview:self.rateTimeLabel];
    return _rateView;
}
- (UIImageView *)rateImageView
{
    if (_rateImageView) {
        return _rateImageView;
    }
    _rateImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"player_goforward"]];
    _rateImageView.contentMode = UIViewContentModeScaleAspectFit;
    _rateImageView.frame = CGRectMake(0, 0, rateViewW, 40);
    return _rateImageView;
}
- (UILabel *)rateTimeLabel
{
    if (_rateTimeLabel) {
        return _rateTimeLabel;
    }
    _rateTimeLabel = [[UILabel alloc] init];
    _rateTimeLabel.text = @"00:00:00 / 00:00:00";
    _rateTimeLabel.textAlignment = NSTextAlignmentCenter;
    _rateTimeLabel.frame = CGRectMake(0, CGRectGetMaxY(self.rateImageView.frame), rateViewW, rateViewH - self.rateImageView.frame.size.height);
    _rateTimeLabel.font = [UIFont systemFontOfSize:12.0];
    _rateTimeLabel.textColor = [UIColor whiteColor];
    return _rateTimeLabel;
}


@end
