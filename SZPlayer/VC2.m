//
//  VC2.m
//  SZPlayer
//
//  Created by songzhen on 16/5/26.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "VC2.h"
#import "SZPlayer.h"

@interface VC2 ()<SZPlayerDelegate>

@property (strong, nonatomic) SZPlayer *player;

@property (strong, nonatomic) UIView *alertView;

@end

@implementation VC2

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
//    _player = [[SZPlayer alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 200) videoURL:@"http://baobab.cdn.wandoujia.com/14468618701471.mp4"];
    
    
    
    _player = [[SZPlayer alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 250)];
    _player.videoURL = @"http://baobab.cdn.wandoujia.com/14468618701471.mp4";
    _player.delegate = self;
    [self.view addSubview:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(clickFull:) name:SZFullScreenBtnNotification object:nil];
    
    
    _alertView = [[NSBundle mainBundle] loadNibNamed:@"PopView" owner:self options:nil].firstObject;
    _alertView.center = _player.center;
    _alertView.hidden = YES;
    [_player addSubview:_alertView];
    
}


- (void)clickFull:(NSNotification *)notification
{
    UIButton *button = [notification object];
    if (button.selected) {
//        [[UIApplication sharedApplication] setStatusBarHidden:YES];
        NSLog(@"全屏");
        
        [self.player toFullScreen];
        
        _alertView.center = CGPointMake(self.view.bounds.size.height * 0.5, self.view.bounds.size.width * 0.5);
    }else{
//        [[UIApplication sharedApplication] setStatusBarHidden:NO];
        [self.player toDetailView:self.view];
        NSLog(@"半屏");
         _alertView.center = _player.center;
    }
}

- (void)videoDidPlayingOnTime:(NSTimeInterval)time
{    
}
- (void)tapVideoBack
{
    NSLog(@"返回");
    if (self.navigationController) {
        [self.navigationController popViewControllerAnimated:YES];
    }else{
        [self dismissViewControllerAnimated:YES completion:nil];
    }
//    [self.navigationController popViewControllerAnimated:YES];
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
- (IBAction)pay:(UIButton *)sender {
}
- (IBAction)notPay:(UIButton *)sender {
}
- (BOOL)prefersStatusBarHidden
{
    return YES;
}


@end
