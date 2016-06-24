//
//  ICENetWorkManager.h
//  NetworkLearnServe
//
//  Created by iceman on 16/5/27.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import <Foundation/Foundation.h>


@class ICESocketHttpRequest;
@protocol ICENetWorkResponseDelegate <NSObject>

- (void)iceSocketNetworkImageFinish:(NSData *)responseData error:(NSError *)error;
- (void)iceSocketNetworkTextFinish:(NSData *)responseData error:(NSError *)error;

@end

@interface ICENetWorkManager : NSObject


+ (ICENetWorkManager *)shareICENetManager;

/*
 ** @param reuquest 为空时采用默认参数
 */
- (void)getUrl:(NSString *)urlString request:(ICESocketHttpRequest *)request delegate:(id <ICENetWorkResponseDelegate>)delegate;

- (void)postUrl:(NSString *)urlString bodyData:(NSData *)bodyData request:(ICESocketHttpRequest *)request delegate:(id <ICENetWorkResponseDelegate>)delegate;



@end

