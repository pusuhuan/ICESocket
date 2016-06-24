//
//  ICESocketHttp.m
//  NetworkLearnClient
//
//  Created by iceman on 16/5/30.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import "ICESocketOperation.h"
#import "ICESocketHttpResponse.h"


@interface ICESocketOperation()

@end

@implementation ICESocketOperation

- (instancetype)init
{
    self = [super init];
    if (self){
        _runloop = [NSRunLoop currentRunLoop];
    }
    return self;
}



- (void)start
{

    [super start];
    [_runloop run];
    
//    runloop apple doc say can't use super start , but if not use ,it can't change isExecuting property to YES.
//    so we use it
}

- (void)main
{
    static int x = 0;
    [_runloop run];
//    while (YES) {
//        x++;
//        NSLog(@"%d",x);
//    }
}



@end
