//
//  ICESocketHttp.m
//  NetworkLearnClient
//
//  Created by iceman on 16/5/27.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import "ICESocketHttpRequest.h"
#import <sys/socket.h>
#import <netdb.h>
#include <ifaddrs.h>
#include <arpa/inet.h>
#import "netinet/tcp.h"
#import "ipstackdetect.h"



@interface ICESocketHttpRequest()

@property (nonatomic,assign)bool isIpv6;
@property (nonatomic,assign)int tryDNSTimes;
@property (nonatomic,assign)int tryConnectTimes;
@property (nonatomic,assign)struct sockaddr_in nativeAddr;
@property (nonatomic,assign)ICESocketConnectionStatus connectionStatus;

@property (nonatomic ,copy) NSString *host;
@property (nonatomic ,copy) NSString *port;
@property (nonatomic ,copy) NSString *resourceLocation;




@end

@implementation ICESocketHttpRequest


- (instancetype)init
{
    self = [super init];
    if (self) {

        _socketFD = socket(AF_INET, SOCK_STREAM, 0);
        _tryDNSTimes = 0;
        _tryConnectTimes = 0;
        _connectionStatus = ICESocketConnectionStatusNO;
    }
    return self;
}

- (void)initConnect
{
    _isIpv6 = (local_ipstack_detect() == ELocalIPStack_IPv6 ? YES : NO);
    
    if(_isIpv6){
        self.connectionStatus = ICESocketConnectionStatusInited;
    }else{
#warning dns解析需要设置超时，新增线程，防止阻塞
        struct hostent *remoteHostEnt = gethostbyname([self.host UTF8String]);
        //失败后3次重试
        if (nil == remoteHostEnt){
            _tryDNSTimes++;
            if(_tryDNSTimes <= 3){
                [self performSelector:@selector(initConnect) withObject:nil afterDelay:_tryDNSTimes];
            }
            NSLog(@"dns解析失败%@ ,socket : %D",  self.url ,self.socketFD);
            [self setConnectionStatus:ICESocketConnectionStatusDisconected];
            return;
        }
        
        NSLog(@"dns解析成功%@ ,socket : %D",  self.url ,self.socketFD);
        
        struct in_addr* remoteInAddr = (struct in_addr*)remoteHostEnt->h_addr_list[0];
        
        _nativeAddr.sin_len       = sizeof(struct sockaddr_in);
        _nativeAddr.sin_family    = AF_INET;
        _nativeAddr.sin_port      = htons([self.port integerValue]);
        _nativeAddr.sin_addr      = *remoteInAddr;
        
        self.connectionStatus = ICESocketConnectionStatusInited;
        
    }
}


- (void)tryBuildConnect
{
    //三次握手
    if (_isIpv6) {
        [self setConnectionStatus:ICESocketConnectionStatusConnecting];
        BOOL isSuccess = NO;
        struct addrinfo hints, *res, *res0;
        int error;
        
        memset(&hints, 0, sizeof(hints));
        hints.ai_family = PF_UNSPEC;
        hints.ai_socktype = SOCK_STREAM;
        hints.ai_flags = AI_DEFAULT;
        error = getaddrinfo([self.host UTF8String],[self.port UTF8String], &hints, &res0);
        
        if (!error) {
            for (res = res0; res; res = res->ai_next) {
                _socketFD = socket(res->ai_family, res->ai_socktype, res->ai_protocol);
                if (self.socketFD < 0) {
                    continue;
                }
                
                struct sockaddr_in6* saddr = (struct sockaddr_in6*)res->ai_addr;
                saddr->sin6_port = htons([self.port integerValue]);
                int result = connect(self.socketFD, (const struct sockaddr *)saddr, res->ai_addrlen);
                if (result < 0) {
                    printf("socket connect failed, errno:%d",errno);
                    close(self.socketFD);
                    _socketFD = -1;
                    continue;
                }
                
                isSuccess = YES;
                break;  /* okay we got one */
            }
        }

        
        if (isSuccess){
            [self setConnectionStatus:ICESocketConnectionStatusConnected];
        }else{
            [self setConnectionStatus:ICESocketConnectionStatusDisconected];
        }
        
        freeaddrinfo(res0);

    }else{
        [self setConnectionStatus:ICESocketConnectionStatusConnecting];
        NSLog(@"开始建立TCP连接 %@",[NSString stringWithUTF8String:inet_ntoa(_nativeAddr.sin_addr)]);
#warning 超时操作
        int result = connect(self.socketFD, (const struct sockaddr *)&_nativeAddr, (socklen_t)sizeof(_nativeAddr));
        //中间路由器可以崩溃、重启，网线可以被挂断再连通，只要两端的主机没有被重启，TCP 连接就可以被一直保持下来。
        if (-1 == result){
            close(self.socketFD);
            _socketFD = -1;
            _tryDNSTimes++;
            if(_tryDNSTimes <= 3){
                [self performSelector:@selector(tryBuildConnect) withObject:nil afterDelay:_tryDNSTimes];
            }else{
                [self setConnectionStatus:ICESocketConnectionStatusDisconected];
            }
        }else{
            NSLog(@"TCP连接建立成功 %@",[NSString stringWithUTF8String:inet_ntoa(_nativeAddr.sin_addr)]);
            [self setConnectionStatus:ICESocketConnectionStatusConnected];
        }
    }
}

- (void)setConnectionStatus:(ICESocketConnectionStatus)status
{
    _connectionStatus = status;
}


- (void)close
{
    //这里不可以用self.connectionStatus = ICESocketConnectionStatusDisconected,
    //因为这样会引起外面的监听者动作，而close可能就是外面监听者自己调用的。
    _connectionStatus = ICESocketConnectionStatusDisconected;
    close(self.socketFD);
}


- (BOOL)send
{
    @synchronized(self) {        
        if (self.connectionStatus != ICESocketConnectionStatusConnected){
            return NO;
        }
        
        NSMutableData *writeData = [[NSMutableData alloc] init];
        [writeData appendData:[self dataHead]];
        if (_bodyData) {
            [writeData appendData:[self bodyData]];
        }
        
        
        NSLog(@"数据写入请求管道");
        write(self.socketFD, [writeData bytes], writeData.length);
        
        return YES;
    }
}


- (BOOL)keepAlive
{
    BOOL on = YES;
    int delay = 5;
    int nRet = setsockopt(self.socketFD, SOL_SOCKET, SO_KEEPALIVE, &on, sizeof(on));
    
    
    if (nRet == 1) {
        NSLog(@"打开 keep-alive result %d",nRet);
        nRet = setsockopt(self.socketFD, IPPROTO_TCP, TCP_KEEPALIVE, &delay, sizeof(delay));
    }else{
         NSLog(@"打开 keep-alive 失败");
//        [self setConnectionStatus:ICESocketConnectionStatusDisconected];
        return NO;
    }
    
    if (nRet == 1) {
        [self setConnectionStatus:ICESocketConnectionStatusConnected];
        return YES;
    }
    
    NSLog(@"打开 keep-alive 失败");
    [self setConnectionStatus:ICESocketConnectionStatusDisconected];
    return NO;
}


- (NSData *)dataHead
{
    NSMutableString *headString = [[NSMutableString alloc] init];
    [headString appendFormat:@"%@ %@ HTTP/1.1\r\n",_method,_resourceLocation];
    [headString appendFormat:@"Host: %@\r\n",_host];
    
    if (_if_none_match) {
      [headString appendFormat:@"If-None-Match: %@\r\n",_if_none_match];
    }
    
    if (_accept) {
      [headString appendFormat:@"Accept: %@\r\n",_accept];
    }
    
    if (_accept_charset) {
        [headString appendFormat:@"Accept-Charset: %@\r\n",_accept_charset];
    }
    
    if (_accept_encoding) {
        [headString appendFormat:@"Accept-Encoding: %@\r\n",_accept_encoding];
    }
    if (_accept_language) {
        [headString appendFormat:@"Accept-Language: %@\r\n",_accept_language];
    }
    if (_accept_ranges) {
        [headString appendFormat:@"Accept-Ranges: %@\r\n",_accept_ranges];
    }
    if (_authorization) {
        [headString appendFormat:@"Authorization: %@\r\n",_authorization];
    }
    
    _connection = @"close";
    if (_connection) {
        [headString appendFormat:@"Connection: %@\r\n",_connection];
    }
    if (_cookie) {
        [headString appendFormat:@"Set-Cookie: %@\r\n",_cookie];
    }
    if (_content_length) {
        [headString appendFormat:@"Content-Length: %@\r\n",_content_length];
    }
    if (_content_type) {
        [headString appendFormat:@"Content-Type: %@\r\n",_content_type];
    }
    if (_date) {
        [headString appendFormat:@"Date: %@\r\n",_date];
    }
    
    if (_user_agent) {
        [headString appendFormat:@"User-Agent: %@\r\n",_user_agent];
    }
    
    [headString appendString:@"\r\n"];

    return [headString dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)getBody:(NSDictionary *)dic
{
    return [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
}

#pragma -- Json
- (NSData *)dataWithbody:(NSDictionary *)dictionaryBody
{
    NSError *parseError = nil;
    
    if (!dictionaryBody) {
        return [NSJSONSerialization dataWithJSONObject:dictionaryBody options:NSJSONWritingPrettyPrinted error:&parseError];
    }else{
        return nil;
    }
    
//   NSJSONWritingPrettyPrinted 是有换位符的。
//   如果NSJSONWritingPrettyPrinted 是nil 的话 返回的数据是没有 换位符的
}


#pragma mark -- cache parse
- (BOOL)needRequestWithCachePath:(NSString **)pathString
{
    return YES;
}


#pragma mark -- url
- (void)setUrl:(NSString *)url
{
    _url = [url copy];
    
    NSArray *array = [_url componentsSeparatedByString:@"/"];
    
    if (array.count > 0) {
        if ([array[0] isEqualToString:@"http:"]) {
            self.port = @"80";
            
            if (array.count > 2) {
                self.host = array[2];
                if (array.count > 3) {
                    self.resourceLocation = @"/";
                    for (int n = 3; n < array.count; n++) {
                        self.resourceLocation = [_resourceLocation stringByAppendingPathComponent:array[n]];
                    }
                }
            }
            else
            {
                return;
            }
        }
        else if([array[0] isEqualToString:@"https:"])
        {
            self.port = @"443";
            if (array.count > 2) {
                self.host = array[2];
                if (array.count > 3) {
                    self.resourceLocation = @"/";
                    for (int n = 3; n < array.count; n++) {
                        self.resourceLocation = [_resourceLocation stringByAppendingPathComponent:array[n]];
                    }
                }
            }
            else
            {
                return;
            }
        }
        else
        {
            self.port = @"8888";
            self.host = array[0];
            if (array.count > 1) {
                self.resourceLocation = @"/";
                for (int n = 1; n < array.count; n++) {
                    self.resourceLocation = [_resourceLocation stringByAppendingPathComponent:array[n]];
                }
            }
        }
    }
    
//    NSString *parten = @"\\.cn";
//    NSError* error = NULL;
//    
//    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:parten options:NSRegularExpressionCaseInsensitive error:&error];
//    
//    NSRange range = [reg rangeOfFirstMatchInString:url options:NSMatchingReportCompletion range:NSMakeRange(0, [url length])];
//    
//    if(range.length == 0){
//        parten = @"\\.com";
//        reg = [NSRegularExpression regularExpressionWithPattern:parten options:NSRegularExpressionCaseInsensitive error:&error];
//        range = [reg rangeOfFirstMatchInString:url options:NSMatchingReportCompletion range:NSMakeRange(0, [url length])];
//    }
//    
//    if(range.length != 0){
//        self.host = [url substringToIndex:range.location + range.length];
//        self.resourceLocation = [url substringFromIndex:range.location + range.length];
//        self.port = @"80";
//    }
}

#pragma mark -- Set Get
- (void)setMethod:(NSString *)method
{
    _method = [[method uppercaseString] copy];
}

@end
