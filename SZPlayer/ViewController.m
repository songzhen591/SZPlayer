//
//  ViewController.m
//  SZPlayer
//
//  Created by 又土又木 on 16/5/25.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import "ViewController.h"
#import "SZPlayer.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 260)];
    [self.view addSubview:view];
    SZPlayer *player = [[SZPlayer alloc] initWithFrame:CGRectMake(0, 0, self.view.bounds.size.width, 260) videoURL:@"http://baobab.cdn.wandoujia.com/14468618701471.mp4"];
    [view addSubview:player];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
