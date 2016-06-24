//
//  ICESocketHttpResponse.h
//  NetworkLearnClient
//
//  Created by iceman on 16/5/30.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ICESocketHttpResponse;
@class ICESocketHttpRequest;
@protocol ICESocketHttpResponseDelegate <NSObject>

- (void)iceSocketHttpFinishResponse:(ICESocketHttpResponse *)socketResponseOperation;

@end


@interface ICESocketHttpResponse : NSObject <NSCoding>

@property (nonatomic,copy) NSString *returnCode;
@property (nonatomic,copy) NSString *returnPhrase;

@property (nonatomic,copy) NSString *accept_ranges;
@property (nonatomic,copy) NSString *age;
@property (nonatomic,copy) NSString *allow;

@property (nonatomic,copy) NSString *content_encoding;
@property (nonatomic,copy) NSString *content_language;
@property (nonatomic,copy) NSString *content_length;
@property (nonatomic,copy) NSString *content_location;
@property (nonatomic,copy) NSString *content_md5;
@property (nonatomic,copy) NSString *content_range;
@property (nonatomic,copy) NSString *content_type;
@property (nonatomic,copy) NSString *connection;
@property (nonatomic,copy) NSString *date;
@property (nonatomic,copy) NSString *etag;

@property (nonatomic,copy) NSString *cache_control;//也是判断本地缓存，优先级高于expires
//可能值public、private、no-cache、no- store、no-transform、must-revalidate、proxy-revalidate、max-age
//各个消息中的指令含义如下：
//Public指示响应可被任何缓存区缓存。
//Private指示对于单个用户的整个或部分响应消息，不能被共享缓存处理。这允许服务器仅仅描述当用户的部分响应消息，此响应消息对于其他用户的请求无效。
//no-cache指示请求或响应消息不能缓存
//no-store用于防止重要的信息被无意的发布。在请求消息中发送将使得请求和响应消息都不使用缓存。
//max-age指示客户机可以接收生存期不大于指定时间（以秒为单位）的响应。
//min-fresh指示客户机可以接收响应时间小于当前时间加上指定时间的响应。
//max-stale指示客户机可以接收超出超时期间的响应消息。如果指定max-stale消息的值，那么客户机可以接收超出超时期指定值之内的响应消息。
@property (nonatomic,copy) NSString *expires;//本地缓存

@property (nonatomic,copy) NSString *last_modified;
@property (nonatomic,copy) NSString *location;
@property (nonatomic,copy) NSString *pragma;
@property (nonatomic,copy) NSString *proxy_aythenticate;
@property (nonatomic,copy) NSString *refresh;
@property (nonatomic,copy) NSString *retry_after;
@property (nonatomic,copy) NSString *server;
@property (nonatomic,copy) NSString *cookie;
@property (nonatomic,copy) NSString *trailer;
@property (nonatomic,copy) NSString *transfer_encoding;
@property (nonatomic,copy) NSString *vary;
@property (nonatomic,copy) NSString *via;
@property (nonatomic,copy) NSString *waring;
@property (nonatomic,copy) NSString *www_authenticate;
@property (nonatomic,copy) NSString *max_age;

@property (nonatomic ,copy) NSString *urlString;

@property (nonatomic,strong) NSData *bodyData;

@property (atomic,readonly,assign) int socketFD;

@property (nonatomic,assign) id<ICESocketHttpResponseDelegate> delegate;

- (void)listenWithSocketFS:(int )socketFD runloop:(NSRunLoop *)runloop;

@end
