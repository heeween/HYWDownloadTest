//
//  HYWDownloadManager.m
//
//  Created by heew on 15/7/16.
//  Copyright (c) 2015年 贺彦文. All rights reserved.
//

#import "HYWDownloadManager.h"
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>





@interface HYWDownloadManager () <NSURLSessionDataDelegate>
/**下载URL */
@property (nonatomic, strong) NSString *downloadUrl;
/** 下载任务 */
@property (nonatomic, strong) NSURLSessionDataTask *task;
/** session */
@property (nonatomic, strong) NSURLSession *session;
/** 写文件的流对象 */
@property (nonatomic, strong) NSOutputStream *stream;
/** 文件的总长度 */
@property (nonatomic, assign) NSInteger totalLength;
/**进度block */
@property (nonatomic, strong) void (^progress)(CGFloat progress);
/**下载成功block */
@property (nonatomic, strong) void (^success)(NSURL *targetPath);
/**下载失败block */
@property (nonatomic, strong) void (^failure)(NSError *error);
/**文件名 */
@property (nonatomic, strong) NSString *fileName;
@end






@implementation HYWDownloadManager
static id _instance;

+ (instancetype)sharedManager {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [[self alloc] init];
    });
    return _instance;
} // 单例方法

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _instance = [super allocWithZone:zone];
    });
    return _instance;
} // 单例方法

- (id)copyWithZone:(NSZone *)zone {
    return _instance;
} // 单例方法

- (NSURLSession *)session {
    if (!_session) {
        _session = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:self delegateQueue:[[NSOperationQueue alloc] init]];
    }
    return _session;
} // session懒加载

- (NSOutputStream *)stream {
    if (!_stream) {
        _stream = [[NSOutputStream alloc] init];
    }
    return _stream;
}  // stream懒加载

- (NSString *)fileName {
    if (_fileName == nil) {
        _fileName = [NSString stringWithFormat:@"%@.mp4",[self.downloadUrl md5String]];
    }
    return _fileName;
} // fileName懒加载

- (NSURLSessionDataTask *)task {
    if (!_task) {
        // 创建请求
        NSURL *url = [NSURL URLWithString:self.downloadUrl];
        NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
        
        NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:HYWCachesFilePath(@"HYWDownloadInfo.plist")];
        NSInteger totalLength = [dict[self.fileName] integerValue];
        
        NSInteger downloadLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:HYWCachesFilePath(self.fileName) error:nil][NSFileSize] integerValue];
        
        if (totalLength && totalLength == downloadLength) {
            NSLog(@"已经下载过了");
            return nil;
        }
        
        // 设置请求头
        NSString *range = [NSString stringWithFormat:@"bytes=%zd-", downloadLength];
        [request setValue:range forHTTPHeaderField:@"Range"];
        
        
        // 创建一个Data任务
        _task = [self.session dataTaskWithRequest:request];
    }
    return _task;
} // task懒加载

- (void)downloadWithURL:(NSString *)url progress:(void (^)(CGFloat progress))progress success:(void (^)(NSURL *targetPath))success failure:(void (^)(NSError *error))failure {
    self.downloadUrl = url;
    self.progress = progress;
    self.success = success;
    self.failure = failure;
} // 下载方法

- (CGFloat)downloadedProgress {
    NSInteger downloadLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:HYWCachesFilePath(self.fileName) error:nil][NSFileSize] integerValue];
    
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:HYWCachesFilePath(@"HYWDownloadInfo.plist")];
    NSInteger totalLength = [dict[self.fileName] integerValue];
    return (1.0 * downloadLength / totalLength);
}   // 下载进度

- (void)pauseAndRestartDownload {
    
    if (self.task.state == NSURLSessionTaskStateRunning) {
        [self.task suspend];
        return;
    }
    [self.task resume];
} //暂停和继续下载







#pragma mark - <NSURLSessionDataDelegate>
/**
 * 1.接收到响应
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveResponse:(NSHTTPURLResponse *)response completionHandler:(void (^)(NSURLSessionResponseDisposition))completionHandler {
    // 根据响应头的建议文件名设置io流的路径
    self.stream = [NSOutputStream outputStreamToFileAtPath:HYWCachesFilePath(self.fileName) append:YES];
    // 打开流
    [self.stream open];
    
    // 存储总长度
    NSMutableDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:HYWCachesFilePath(@"HYWDownloadInfo.plist")];
    if (dict == nil) {
        dict = [NSMutableDictionary dictionary];
        // 获得服务器这次请求 返回数据的总长度
        NSInteger downloadLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:HYWCachesFilePath(self.fileName) error:nil][NSFileSize] integerValue];
        self.totalLength = [response.allHeaderFields[@"Content-Length"] integerValue] + downloadLength;
        
        dict[self.fileName] = @(self.totalLength);
        [dict writeToFile:HYWCachesFilePath(@"HYWDownloadInfo.plist") atomically:YES];
    }
    
    // 接收这个请求，允许接收服务器的数据
    completionHandler(NSURLSessionResponseAllow);
}



/**
 * 2.接收到服务器返回的数据（这个方法可能会被调用N次）
 */
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask didReceiveData:(NSData *)data {
    // 写入数据
    [self.stream write:data.bytes maxLength:data.length];
    
    // 下载进度
    NSInteger downloadLength = [[[NSFileManager defaultManager] attributesOfItemAtPath:HYWCachesFilePath(self.fileName) error:nil][NSFileSize] integerValue];
    
    // 回调progress进度值
    if (self.progress) {
        self.progress(1.0 * downloadLength / self.totalLength);
    }
}




/**
 * 3.请求完毕（成功\失败）
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (error) {
        if (self.failure) {
            self.failure(error);
        }
    }else {
        if (self.success) {
            self.success([NSURL fileURLWithPath:[HYWCaches stringByAppendingPathComponent:self.fileName]]);
        }
        // 关闭流
    }
    [self.stream close];
    self.stream = nil;
    
//     清除任务
    self.task = nil;
    self.session = nil;
}

@end






@implementation NSString (Hash)

- (NSString *)md5String
{
    const char *string = self.UTF8String;
    int length = (int)strlen(string);
    unsigned char bytes[CC_MD5_DIGEST_LENGTH];
    CC_MD5(string, length, bytes);
    return [self stringFromBytes:bytes length:CC_MD5_DIGEST_LENGTH];
}

#pragma mark - Helpers

- (NSString *)stringFromBytes:(unsigned char *)bytes length:(int)length
{
    NSMutableString *mutableString = @"".mutableCopy;
    for (int i = 0; i < length; i++)
        [mutableString appendFormat:@"%02x", bytes[i]];
    return [NSString stringWithString:mutableString];
}
@end
