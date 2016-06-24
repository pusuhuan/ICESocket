//
//  ICENetWorkManger+Cache.h
//  NetworkLearnClient
//
//  Created by iceman on 16/6/3.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import "ICESocketHttpRequest.h"
#import "ICESocketHttpResponse.h"
//只要返回的结果是一致的，其实接口越多越好
@interface ICENetWorkCacheManager:NSObject

//添加缓存
- (void)cache:(ICESocketHttpResponse *)response;

//如果返回为空，那么需要发送
//读取缓存
- (ICESocketHttpResponse *)getCacheWithRequest:(ICESocketHttpRequest **)request;

//从某个缓存中得到 数据
- (NSData *)getCacheBody:(ICESocketHttpResponse *)response;

//仅比对url 判断get方法缓存的存在
- (NSData *)dataWithMethodGetURL:(NSString *)urlString;

+ (void)clearCache;

@end
