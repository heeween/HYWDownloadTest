//
//  XMGDownloadManager.h
//  05-掌握-大文件下载
//
//  Created by xiaomage on 15/7/16.
//  Copyright (c) 2015年 小码哥. All rights reserved.
//

#import <UIKit/UIKit.h>
// 沙盒路径（caches）
#define HYWCaches [NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject]
// 沙盒文件路径
#define HYWCachesFilePath(fileName) [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) lastObject] stringByAppendingPathComponent:fileName]

@interface HYWDownloadManager : NSObject

+ (instancetype)sharedManager;

- (void)pauseAndRestartDownload;

- (void)downloadWithURL:(NSString *)url progress:(void (^)(CGFloat progress))progress success:(void (^)(NSURL *targetPath))success failure:(void (^)(NSError *error))failure;

- (CGFloat)downloadedProgress;

@end

@interface NSString (Hash)
@property (readonly) NSString *md5String;
@end