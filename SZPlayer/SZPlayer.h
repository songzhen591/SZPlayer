//
//  SZPlayer.h
//  SZPlayer
//
//  Created by 又土又木 on 16/5/25.
//  Copyright © 2016年 ytuymu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SZPlayer : UIView

- (instancetype)initWithFrame:(CGRect)frame videoURL:(NSString *)videoURL;

- (void)reduction:(UIView *)view;

@end
