//
//  ViewController.m
//  SZPlayer
//
//  Created by 又土又木 on 16/5/25.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "ViewController.h"
#import "SZPlayer.h"

@interface ViewController ()<SZPlayerDelegate>

{
//    BOOL _hideStatusBar;
}

@property (strong, nonatomic) SZPlayer *player;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self setNeedsStatusBarAppearanceUpdate];
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    // Do any additional setup after loading the view, typically from a nib.
//    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 200, self.view.bounds.size.width, 260)];
//    [self.view addSubview:view];
    _player = [[SZPlayer alloc] initWithFrame:CGRectMake(0, 100, self.view.bounds.size.width, 200) videoURL:@"http://baobab.cdn.wandoujia.com/14468618701471.mp4"];
    _player.delegate = self;
    [self.view addSubview:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clickFull:) name:SZFullScreenBtnNotification object:nil];
}

- (void)clickFull:(NSNotification *)notification
{
    UIButton *button = [notification object];
    if (button.selected) {
//        _hideStatusBar = YES;
//        [self prefersStatusBarHidden];
        [[UIApplication sharedApplication] setStatusBarHidden:YES];
    }else{
//        _hideStatusBar = NO;
//        [self prefersStatusBarHidden];
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }
}

- (void)videoDidPlayingOnTime:(NSTimeInterval)time
{
    NSLog(@"%f", time);
    
    if (time > 4) {
        _player.videoURL = @"http://v.jxvdy.com/sendfile/w5bgP3A8JgiQQo5l0hvoNGE2H16WbN09X-ONHPq3P3C1BISgf7C-qVs6_c8oaw3zKScO78I--b0BGFBRxlpw13sf2e54QA";
    }
    
}
- (void)tapVideoBack
{
    NSLog(@"返回");
}

//- (BOOL)prefersStatusBarHidden
//{
//    NSLog(@"%d", _hideStatusBar);
//    return _hideStatusBar;;
//}
//- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
//{
//    return UIStatusBarAnimationNone;
//}
//


@end
