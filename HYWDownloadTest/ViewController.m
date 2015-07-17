//
//  ViewController.m
//  用自己的框架断点下载
//
//  Created by heew on 15/7/16.
//  Copyright (c) 2015年 adhx. All rights reserved.
//

#import "ViewController.h"
#import "HYWDownloadManager.h"
#import "ProgressView.h"
#import <MediaPlayer/MediaPlayer.h>


@interface ViewController () <NSURLSessionDataDelegate>
@property (weak, nonatomic) IBOutlet ProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIButton *button;
@end

@implementation ViewController


static NSString *urlString = @"http://120.25.226.186:32812/resources/videos/minion_01.mp4";


- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置progressview初始状态
    self.progressView.progress = 0.00001;
    
    // 开启下载任务
    HYWDownloadManager *mgr = [HYWDownloadManager sharedManager];
    [mgr downloadWithURL:urlString progress:^(CGFloat progress) {
        
        // 主线程刷新UI界面
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            self.progressView.progress = progress;
        }];
    } success:^(NSURL *targetPath) {
        
        // 下载完成直接播放
        [[NSOperationQueue mainQueue] addOperationWithBlock:^{
            [self buttonClick:self.button];
        }];
    } failure:^(NSError *error) {
    }];
    
}



- (IBAction)buttonClick:(UIButton *)sender {
    
    // 获得下载管理器
    HYWDownloadManager *mgr = [HYWDownloadManager sharedManager];
    
    // 如果下载完毕,打开播放
    if (mgr.downloadedProgress == 1) {
        sender.selected = NO;

        NSString *typeString = [[urlString componentsSeparatedByString:@"."] lastObject];
        NSString *strurl =[HYWCachesFilePath([urlString md5String]) stringByAppendingFormat:@".%@",typeString];
        NSURL *url = [NSURL fileURLWithPath:strurl];
        NSLog(@"%@",url);
        MPMoviePlayerViewController *vc = [[MPMoviePlayerViewController alloc] initWithContentURL:url];
        [self presentViewController:vc animated:YES completion:nil];
        return;
    }
    
    // 其他情况,就开始或暂停下载
    [mgr pauseAndRestartDownload];
    
    // 切换按钮状态
    sender.selected = !sender.isSelected;
}

@end
