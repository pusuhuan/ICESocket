//
//  ICENetWorkManager.m
//  NetworkLearnServe
//
//  Created by iceman on 16/5/27.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import "ICENetWorkManager.h"
#import "ICESocketOperation.h"
#import "ICENetWorkCacheManager.h"

static ICENetWorkManager *shareICENetManager = nil;
@interface ICENetWorkManager() <ICESocketHttpResponseDelegate>

@property (nonatomic ,strong) NSMutableArray *connectQueue;  //正在连接中的队列 request

@property (nonatomic ,strong) NSMutableArray *waitingQueue;  //已经连接  请求还没有发出去

@property (nonatomic ,strong) NSMutableArray *requestQueue;  //已经发送的request 但还没有返回

//因为keepalive不能同时发多个，所以，此队列中的request,都是保持着keepalive状态，而当前不处于发送过程中
#warning 由mananger管理request   把requset 和 socket 分开
@property (nonatomic ,strong) NSMutableArray *keepAliveQueue;
#warning keepalive线程池


@property (nonatomic ,strong) dispatch_queue_t sendQueue; //发送队列



//接受线程
@property (nonatomic ,strong) ICESocketOperation *httpOperation;
@property (nonatomic ,strong) NSOperationQueue *operationQueue;

//缓存管理
@property (nonatomic ,strong) ICENetWorkCacheManager *cacheManger;

@end

@implementation ICENetWorkManager


+ (ICENetWorkManager *)shareICENetManager
{
    @synchronized(self){
        if(shareICENetManager == nil){
            shareICENetManager = [[ICENetWorkManager alloc] init];
        }
    }
    
    return shareICENetManager;
}



- (instancetype)init
{
    self = [super init];
    if (self) {
        _connectQueue = [[NSMutableArray alloc] init];
        _waitingQueue = [[NSMutableArray alloc] init];
        _requestQueue = [[NSMutableArray alloc] init];
        _keepAliveQueue = [[NSMutableArray alloc] init];
        _operationQueue = [[NSOperationQueue alloc] init];
        _cacheManger = [[ICENetWorkCacheManager alloc] init];
        _sendQueue = dispatch_queue_create("sendQueue", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

#pragma mark -- interFace
- (void)getUrl:(NSString *)urlString request:(ICESocketHttpRequest *)request delegate:(id <ICENetWorkResponseDelegate>)delegate
{
    if (urlString.length < 1)
    {
        NSLog(@"No Url");
        return;
    }
    
    if (!request) {
        request = [[ICESocketHttpRequest alloc] init];
    }
    
    if (delegate) {
        request.delegate = delegate;
    }
    
    if ([urlString isKindOfClass:[NSString class]]) {
        request.url = urlString;
    }
    
    request.method = @"GET";
    
    ICESocketHttpResponse *response = [_cacheManger getCacheWithRequest:&request];
    
    if(response != nil)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([request.delegate respondsToSelector:@selector(iceSocketNetworkImageFinish:error:)]) {
                if ([response.content_type containsString:@"image"]) {
                    [request.delegate iceSocketNetworkImageFinish:response.bodyData error:nil];
                }
            }else if ([request.delegate respondsToSelector:@selector(iceSocketNetworkTextFinish:error:)]){
                if ([response.content_type containsString:@"text"]) {
                    [request.delegate iceSocketNetworkTextFinish:response.bodyData error:nil];
                }
            }
        });
        NSLog(@"%@: %@",@"缓存命中",request.url);
    }
    else
    {
        NSLog(@"缓存未命中 : %@",request.url);
        dispatch_async(_sendQueue, ^{
            [self sendRequest:request];
        });
    }
    
    NSLog(@"-----------结束检查缓存----------");
    
}

- (void)postUrl:(NSString *)urlString bodyData:(NSData *)bodyData request:(ICESocketHttpRequest *)request delegate:(id <ICENetWorkResponseDelegate>)delegate
{
    if (urlString.length < 1){
        NSLog(@"Url 为空 ");
        return;
    }
    
    if (!request) {
        request = [[ICESocketHttpRequest alloc] init];
    }
    
    if (delegate) {
        request.delegate = delegate;
    }
    
    if ([urlString isKindOfClass:[NSString class]]) {
        request.url = urlString;
    }
    
    if ([bodyData isKindOfClass:[NSData class]]){
        request.bodyData = bodyData;
    }
    
    request.url = urlString;
    request.method = @"POST";
    
    dispatch_async(_sendQueue, ^{
          [self sendRequest:request];
    });
}

#pragma privateMethod
//
- (void)sendRequest:(ICESocketHttpRequest *)request
{
    [request addObserver:self forKeyPath:@"connectionStatus" options:NSKeyValueObservingOptionNew context:nil];
    
    switch (request.connectionStatus){
        case ICESocketConnectionStatusNO:
        case ICESocketConnectionStatusDisconected:
            @synchronized (_connectQueue){
                [_connectQueue addObject:request];
            }
            [request initConnect];
            break;
            
        case ICESocketConnectionStatusConnected:
            if ([_keepAliveQueue containsObject:request]) {
                @synchronized (_keepAliveQueue) {
                    @synchronized (_requestQueue){
                        [_requestQueue addObject:request];
                        [_keepAliveQueue removeObject:request];
                    }
                }
                [self sendInKeepAlive:request];
            }

            break;
            
        default:
            break;
    }
}

- (void)initHttpOperation
{
    _httpOperation = [[ICESocketOperation alloc] init];
    [_httpOperation addObserver:self forKeyPath:@"isFinished" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial  context:nil];
    [_httpOperation addObserver:self forKeyPath:@"isCancelled" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial  context:nil];
    [_httpOperation addObserver:self forKeyPath:@"isExecuting" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial context:nil];
    [_httpOperation addObserver:self forKeyPath:@"isReady" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionInitial  context:nil];
    
//    [_httpOperation start];
    [_operationQueue addOperation:_httpOperation];
}

- (void)send
{
    @synchronized (_waitingQueue){
        @synchronized (_requestQueue){
            for (NSObject *object in _waitingQueue){
                if ([object isKindOfClass:[ICESocketHttpRequest class]]) {
                    ICESocketHttpRequest *request = (ICESocketHttpRequest*)object;
                    ICESocketHttpResponse *response = [[ICESocketHttpResponse alloc] init];
                    response.delegate = self;
                    NSLog(@"开始发送请求 : %@ , scoket : %d",request.url ,request.socketFD);
                    [request send];
                    [response listenWithSocketFS:request.socketFD runloop:_httpOperation.runloop];
                }
            }
            
            [_requestQueue addObjectsFromArray:_waitingQueue];
            [_waitingQueue removeAllObjects];
        }
    }
}

- (void)sendInKeepAlive:(ICESocketHttpRequest *)request
{
    @synchronized (_keepAliveQueue){
        @synchronized (_requestQueue) {
            ICESocketHttpResponse *response = [[ICESocketHttpResponse alloc] init];
            response.delegate = self;
            NSLog(@"开始发送请求 : %@ , scoket : %d",request.url ,request.socketFD);
            [request send];
            [response listenWithSocketFS:request.socketFD runloop:_httpOperation.runloop];
            [_requestQueue addObjectsFromArray:_waitingQueue];
            [_keepAliveQueue removeObject:request];
        }
    }
}

- (void)observeValueForKeyPath:(nullable NSString *)keyPath ofObject:(nullable id)object change:(nullable NSDictionary<NSString*, id> *)change context:(nullable void *)context
{
#warning 最好用红定义
    if ([keyPath isEqualToString:@"isExecuting"]) {
        if ([[change objectForKey:@"new"] boolValue]){
             NSLog(@"isExecuting");
            [self send];
        }
        
    }else if ([keyPath isEqualToString:@"isFinished"] ){
        if ([[change objectForKey:@"new"] boolValue]){
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            _httpOperation = nil;
            NSLog(@"isFinished");
        }
    }else if ([keyPath isEqualToString:@"isCancelled"]){
        if ([[change objectForKey:@"new"] boolValue]){
            _httpOperation = nil;
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            NSLog(@"isCancelled");
        }
    }
    
    if ([keyPath isEqualToString:@"connectionStatus"]){
        ICESocketConnectionStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        
        switch (status){
            case ICESocketConnectionStatusInited:
                [(ICESocketHttpRequest*)object tryBuildConnect];
                break;
                
            case ICESocketConnectionStatusConnected:
                @synchronized (_connectQueue) {
                    @synchronized (_waitingQueue) {
                        [_connectQueue removeObject:object];
                        [_waitingQueue addObject:object];
                    }
                }
                
                if (!_httpOperation || _httpOperation.isCancelled || _httpOperation.isFinished){
                     [self initHttpOperation];
                }
                else if (_httpOperation.isExecuting)
                {
                    [self send];
                }//if (isReady) 就等 isExecuting 中发送
                break;
                
            case ICESocketConnectionStatusDisconected:
                if([_connectQueue containsObject:object]){
                    @synchronized (_connectQueue) {
                        [_connectQueue removeObject:object];
                    }
                }
                if([_waitingQueue containsObject:object]){
                    @synchronized (_waitingQueue) {
                        [_waitingQueue removeObject:object];
                    }
                }
                if([_requestQueue containsObject:object]){
                    @synchronized (_requestQueue) {
                        [_requestQueue removeObject:object];
                    }
                }
                if ([_keepAliveQueue containsObject:object]) {
                    @synchronized (_keepAliveQueue) {
                        [_keepAliveQueue removeObject:object];
                    }
                }
                break;
                
            default:
                break;
        }
    }
}

- (void)iceSocketHttpFinishResponse:(ICESocketHttpResponse *)socketResponseOperation
{
    
    ICESocketHttpRequest *request;
    @synchronized (_requestQueue) {
        for (request in _requestQueue){
            if (request.socketFD == socketResponseOperation.socketFD) {
                socketResponseOperation.urlString = request.url;
                [_requestQueue removeObject:request];
                break;
            }
        }
    }

    
    NSError *error = nil;
#warning 206 处理
    if ([socketResponseOperation.returnCode integerValue] == 200){
        NSLog(@"反回码 200");
        [_cacheManger cache:socketResponseOperation];
        if ([socketResponseOperation.connection isEqualToString:@"close"]) {
            [request close];
        }else{
            if ([request keepAlive]){
                @synchronized (_keepAliveQueue) {
                    [_keepAliveQueue addObject:request];
                }
            }else{
                [request close];
            }
        }
    }else if ([socketResponseOperation.returnCode integerValue] == 304){
        NSLog(@"反回码 304,从本地读取缓存");
        socketResponseOperation.bodyData = [_cacheManger getCacheBody:socketResponseOperation];
        [_cacheManger cache:socketResponseOperation];
        if ([socketResponseOperation.connection isEqualToString:@"close"]) {
            [request close];
        }else{
            if ([request keepAlive]){
                @synchronized (_keepAliveQueue) {
                    [_keepAliveQueue addObject:request];
                }
            }else{
                [request close];
            }
        }
    }else if ([socketResponseOperation.returnCode integerValue] == 302){
        NSLog(@"反回码 302,重新发起请求");
        [request close];
#warning 加逻辑禁止无限302，20层。
        [self getUrl:socketResponseOperation.location request:nil delegate:request.delegate];
    }else {
        [request close];
        if (socketResponseOperation.returnPhrase) {
            error = [NSError errorWithDomain:socketResponseOperation.returnPhrase code:[socketResponseOperation.returnCode integerValue] userInfo:nil];
        }else{
            error = [NSError errorWithDomain:@"" code:[socketResponseOperation.returnCode integerValue] userInfo:nil];
        }
    }
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([request.delegate respondsToSelector:@selector(iceSocketNetworkImageFinish:error:)]) {
            if ([socketResponseOperation.content_type containsString:@"image"]) {
                [request.delegate iceSocketNetworkImageFinish:socketResponseOperation.bodyData error:error];
            }
        }else if ([request.delegate respondsToSelector:@selector(iceSocketNetworkTextFinish:error:)]){
            if ([socketResponseOperation.content_type containsString:@"text"]) {
                [request.delegate iceSocketNetworkTextFinish:socketResponseOperation.bodyData error:error];
            }
        }
    });
}

@end
