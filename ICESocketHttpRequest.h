//
//  ICESocketHttp.h
//  NetworkLearnClient
//
//  Created by iceman on 16/5/27.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import <Foundation/Foundation.h>


//typedef enum : NSUInteger {
//    HttpMethodGet = 0,
//    HttpMethodPost,
//    HttpMethodPut,
//    HttpMethodDelete,
//} HttpMethod;

typedef NS_ENUM(NSInteger, ICESocketConnectionStatus) {
    ICESocketConnectionStatusNO,
    ICESocketConnectionStatusInited, //已经拿到ip地址，初始化了socket
    ICESocketConnectionStatusConnecting,
    ICESocketConnectionStatusConnected,
    ICESocketConnectionStatusDisconected,
};

typedef NS_ENUM(NSInteger, ICESocketConnectionErrorCode) { /** The task error */
    ICESocketConnectionErrorCodeNone = 0, /** No error */
    ICESocketConnectionErrorCodeNetUnavailable = 1, /** network unavailable */
    ICESocketConnectionErrorCodeTimeOut = 2, /** time out */
    ICESocketConnectionErrorCodeInitError = 3, /** init error */
    ICESocketConnectionErrorCodeHostError = 4, /** host error */
    ICESocketConnectionErrorCodeConnectError = 5, /** connect error */
    ICESocketConnectionErrorCodeSendError = 6, /** send error */
    ICESocketConnectionErrorCodeUnknowError = 0xffff /** The undefined error code */
};

@interface ICESocketHttpRequest : NSObject


@property (nonatomic,copy) NSString *accept;
@property (nonatomic,copy) NSString *accept_charset;
@property (nonatomic,copy) NSString *accept_encoding;
@property (nonatomic,copy) NSString *accept_language;
@property (nonatomic,copy) NSString *accept_ranges;
@property (nonatomic,copy) NSString *authorization;
@property (nonatomic,copy) NSString *connection;
@property (nonatomic,copy) NSString *cookie;
@property (nonatomic,copy) NSString *content_length;
@property (nonatomic,copy) NSString *content_type;
@property (nonatomic,copy) NSString *date;

@property (nonatomic,copy) NSString *if_modified_since;
@property (nonatomic,copy) NSString *if_none_match;

@property (nonatomic,copy) NSString *user_agent;
/*
 **请求方法
 */
@property (nonatomic,copy) NSString *method;

@property (nonatomic,copy) NSString *max_forwards;
@property (nonatomic,copy) NSString *proxy_authorization;
@property (nonatomic,copy) NSString *range;
@property (nonatomic,copy) NSString *referer;
@property (nonatomic,copy) NSString *upgrade;

@property (nonatomic,copy) NSString *via;
@property (nonatomic,copy) NSString *warning;


@property (nonatomic ,copy) NSString *url;

@property (nonatomic ,assign)int socketFD;

@property (nonatomic ,readonly)ICESocketConnectionStatus connectionStatus;

@property (nonatomic ,strong)NSData *headData;

@property (nonatomic ,strong)NSData *bodyData;

@property (nonatomic ,assign)id delegate;
//解析地址，初始化socket
- (void)initConnect;
//发起连接请求
- (void)tryBuildConnect;

- (BOOL)send;

- (void)close;

- (BOOL)keepAlive;

@end
