//
//  VC3.m
//  SZPlayer
//
//  Created by songzhen on 16/5/30.
//  Copyright © 2016年 ytuymu. All rights reserved.
//
/**
 *  全屏显示播放器
 *
 *
 */

#import "VC3.h"
#import "SZPlayer.h"

@interface VC3 ()<SZPlayerDelegate>

@property (strong,nonatomic) SZPlayer *player;


@end

@implementation VC3

- (void)viewDidLoad {
    [super viewDidLoad];

    [self.view addSubview:self.player];
}

- (SZPlayer *)player
{
    if (_player) {
        return _player;
    }
    _player = [[SZPlayer alloc] init];
    _player.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.height, [UIScreen mainScreen].bounds.size.width);
    _player.videoURL = @"http://baobab.cdn.wandoujia.com/14468618701471.mp4";
    _player.fullScreenButton.hidden = YES;
    _player.delegate = self;
    [UIView performWithoutAnimation:^{
        [_player toFullScreen];
    }];
    
    return _player;
}

- (void)tapVideoBack
{
    [self.navigationController popViewControllerAnimated:YES];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.navigationController.navigationBar.hidden = YES;
}
-(void)viewWillDisappear:(BOOL)animated
{
    [self.player pause];
    self.navigationController.navigationBar.hidden = NO;
}
- (void)dealloc
{
    [_player releaseSZPlayer];
}
- (BOOL)prefersStatusBarHidden
{
    return YES;
}

@end
