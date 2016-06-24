//
//  ICESocketHttpResponse.m
//  NetworkLearnClient
//
//  Created by iceman on 16/5/30.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import "ICESocketHttpResponse.h"

@interface ICESocketHttpResponse() <NSStreamDelegate>

@property (atomic, strong) NSMutableData *data;
@property (atomic, strong) NSInputStream *networkStream;
@property (atomic, assign, readwrite) int socketFD;
@property (atomic ,assign) int headerLenth;
@property (atomic, assign) int bodyLenth;
@property (nonatomic ,assign) int dataLength;
// 用非动态字典会有问题
@property (nonatomic ,strong) NSMutableDictionary *propertyDictionry;

@property (nonatomic ,copy) NSMutableString *responseString;

@property (nonatomic ,assign) BOOL hasFinish;

@end

@implementation ICESocketHttpResponse

- (id)init
{
    if (self = [super init]){
        _data = [[NSMutableData alloc] init];
        _propertyDictionry = [[NSMutableDictionary alloc] initWithDictionary:@{@"Accept-Ranges":@"setAccept_ranges:",@"Age":@"setAge:",@"Allow":@"setAllow:",
                               @"Cache-Control":@"setCache_control:",@"Content-Encoding":@"setContent_encoding:",
                               @"Content-Language":@"setAontent_language:",@"Content-Length":@"setContent_length:",
                               @"Content-Location":@"setContent_location:",@"Content-MD5":@"setContent_md5:",
                               @"Content-Range":@"setContent_range:",@"Content-Type":@"setContent_type:",@"Date":@"setDate:",
                               @"ETag":@"setEtag:",@"Expires":@"setExpires:",@"Last-Modified":@"setLast_modified:",
                               @"Location":@"setLocation:",@"Pragma":@"setPragma:",@"Retry-After":@"setRetry_after:",
                               @"Proxy-Authenticate":@"setProxy_aythenticate:",@"refresh":@"setRefresh:",
                               @"Server":@"setServer:",@"Set-Cookie":@"setCookie:",@"Trailer":@"setTrailer:",
                               @"Transfer-Encoding":@"setTransfer_encoding:",@"Vary":@"setVary:",@"Via":@"setVia:",
                               @"Warning":@"setWarning:",@"WWW-Authenticate":@"setWww_authenticate:",
                               @"Connection":@"setConnection:"
                                                                               }];
        
        _responseString = [[NSMutableString alloc] initWithString:@""];
        _bodyLenth = 0;
        _headerLenth = 0;
        _hasFinish = NO;
    }
    
    return self;
}

- (void)listenWithSocketFS:(int )socketFD runloop:(NSRunLoop *)runloop
{
    _socketFD = socketFD;
    [self initReceiveStream:runloop];
}

- (void)initReceiveStream:(NSRunLoop *)runloop
{
    
    CFReadStreamRef readStream;
    CFStreamCreatePairWithSocket(NULL, self.socketFD, &readStream, NULL);
    assert(readStream != NULL);
    
    self.networkStream = (NSInputStream *)CFBridgingRelease(readStream);
    //    CFRelease(readStream);
    
    [self.networkStream setProperty:(id)kCFBooleanTrue forKey:(NSString*)kCFStreamPropertyShouldCloseNativeSocket];
    
    self.networkStream.delegate = self;
    
    [self.networkStream scheduleInRunLoop:runloop forMode:NSDefaultRunLoopMode];
    
    [self.networkStream open];
}


#pragma mark - NSStreamDelegate
- (void)stream:(NSStream *)aStream handleEvent:(NSStreamEvent)eventCode
{
    if (self.socketFD < 0) {
        return;
    }
    switch (eventCode) {
        case NSStreamEventOpenCompleted:
        {
            NSLog(@"接收管道初始化成功");
        }
            break;
        case NSStreamEventHasBytesAvailable:
        {
            NSInteger readBytes;
#warning 最好不要使用1000这种，使用1024整倍数。
            NSInteger bufferLength = 1000;
            uint8_t buffer[bufferLength];
            
            readBytes = [self.networkStream read:buffer maxLength:sizeof(buffer)];
            
            NSLog(@"读取到新数据 socked : %d ,字节数 %d",self.socketFD,(int)readBytes);
        
            if (readBytes == -1) {
                NSLog(@"socket 读取到EOF");
            }else if (readBytes == 0){
                NSLog(@"socket 读取完成");
            }else{
                NSData *datas = [[NSData alloc] initWithBytes:buffer length:readBytes];
                [_responseString appendString:[[NSString alloc] initWithData:datas encoding:NSASCIIStringEncoding]];
                [self.data appendBytes:buffer length:readBytes];
#warning 先做头部解析，bodydata 最好在外面读。
                if (_bodyLenth == 0){
                    
                    NSString *parten = @"\r\nContent-Length:([0-9]*)";
                    
                    NSRegularExpression *reg = [NSRegularExpression regularExpressionWithPattern:parten options:NSRegularExpressionCaseInsensitive error:nil];
                    
                    NSRange range = [reg rangeOfFirstMatchInString:_responseString options:NSMatchingReportCompletion range:NSMakeRange(0, [_responseString length])];
                    
                    if (range.length > 0) {
                        range.length-=4;
                        range.location+=17;
                        if(_responseString.length > range.location + range.length){
                            NSString *tempString = [_responseString substringWithRange:range];
                            _bodyLenth = [tempString intValue];
                        }
                    }
                }
                
                if(_headerLenth == 0) {
                    
                    NSData *crlfData = [@"\r\n\r\n" dataUsingEncoding:NSASCIIStringEncoding];
                    NSRange rang;
                    rang.location = 0;
                    rang.length = self.data.length;
                    rang = [self.data rangeOfData:crlfData options:NSDataSearchBackwards range:rang];
                    if (rang.length > 0) {
                        _headerLenth = (int)rang.location + 4;
                    }
                    
                    //location  位置 从 0开始的
                }
                
                if(_headerLenth > 0 && self.data.length >= (_bodyLenth + _headerLenth)){
                    NSLog(@"%@",self.responseString);
                    _hasFinish = YES;
                    NSRange range;
                    range.length = self.bodyLenth;
                    range.location = self.data.length - range.length;
                    self.bodyData = [self.data subdataWithRange:range];
                    [self ParseHeader];
                    break;
                }
            }
        }
            break;
            
        case NSStreamEventHasSpaceAvailable:
        {
            //this event trigger by output stream
            assert(NO);
        }
            break;
            
        case NSStreamEventErrorOccurred:
        {
            if (!_hasFinish){
                NSLog(@"流数据无法读取");
            }
        }
            break;
        case NSStreamEventEndEncountered:
        {
            NSLog(@"请求完成，但是没有收到connect结束");
            if (!_hasFinish){
                NSLog(@"%@",self.responseString);
                [self ParseHeadAndBody];
            }
        }
            break;
        default:
            assert(NO);
            break;
    }
}


#pragma mark -- parse
- (void)ParseHeader
{
    NSRange range;
    range.length = self.headerLenth;
    range.location = 0;
    NSString *responseString = [[NSString alloc] initWithData:[self.data subdataWithRange:range] encoding:NSASCIIStringEncoding];
    NSArray *parseArray = [responseString componentsSeparatedByString:@"\r\n"];
    
    NSString *tempString = nil;
    NSArray *array = nil;
    NSString *value = nil;
    NSString *key = nil;
    
    for (int n = 0;n < parseArray.count;n++){
        tempString = parseArray[n];
        if (n == 0) {
            //第一行，状态码
            array = [tempString componentsSeparatedByString:@" "];
            if (array.count > 1) {
                tempString = array[1];
                if ([tempString integerValue] > 0) {
                    self.returnCode = tempString;
                }
                
                if (array.count > 2) {
                    tempString = array[2];
                    self.returnPhrase = tempString;
                }
            }
        }else{
            
            array = [tempString componentsSeparatedByString:@": "];
            if (array.count >= 2) {
                key = array[0];
                value = array[1];
            }
            
            if (tempString.length == 0){
                [self.delegate iceSocketHttpFinishResponse:self];
                break;
            }else{
                NSString *methodString = _propertyDictionry[key];
                if (methodString) {
                    SEL selector = NSSelectorFromString(methodString);
                    IMP imp = [self methodForSelector:selector];
                    void (*funtion)(id,SEL,NSString *)=(void *)imp;
                    funtion(self,selector,value);
                }
            }
        }
        
    }
}



- (void)ParseHeadAndBody
{
    NSString *responseString = [[NSString alloc] initWithData:self.data encoding:NSASCIIStringEncoding];
    NSArray *parseArray = [responseString componentsSeparatedByString:@"\r\n"];
    
    NSString *tempString = nil;
    NSArray *array = nil;
    NSString *value = nil;
    NSString *key = nil;
    
    for (int n = 0;n < parseArray.count;n++){
        tempString = parseArray[n];
        if (n == 0) {
            //第一行，状态码
            array = [tempString componentsSeparatedByString:@" "];
            if (array.count > 1) {
                   tempString = array[1];
                if ([tempString integerValue] > 0) {
                    self.returnCode = tempString;
                }
                
                if (array.count > 2) {
                    tempString = array[2];
                    self.returnPhrase = tempString;
                }
                
            }
        }else{
            
            array = [tempString componentsSeparatedByString:@": "];
            if (array.count >= 2) {
                key = array[0];
                value = array[1];
            }
            
            if (tempString.length == 0){
                //如果是倒数第二个元素，那么最后的就是body，把self.bodydata赋值
                if (n+2 <= parseArray.count) {
                    tempString = parseArray[n+1];
                    for (int x = n+2; x < parseArray.count; x++){
                        tempString = [tempString stringByAppendingFormat:@"\r\n%@",parseArray[x]];
                    }
                    NSRange range;
                    range.length = [self.content_length integerValue];
                    range.location = self.data.length - range.length;
                    self.bodyData = [self.data subdataWithRange:range];
                    
//                    self.bodyData = [tempString dataUsingEncoding:NSUTF8StringEncoding];
                    [self.delegate iceSocketHttpFinishResponse:self];
                }else{
                    continue;
                }
            }else{
                NSString *methodString = _propertyDictionry[key];
                if (methodString) {
                    SEL selector = NSSelectorFromString(methodString);
                    IMP imp = [self methodForSelector:selector];
                    void (*funtion)(id,SEL,NSString *)=(void *)imp;
                    funtion(self,selector,value);
                }
            }
        }
        
    }
}
#pragma mark -- codeing

- (void)encodeWithCoder:(NSCoder *)aCoder {
    
    [aCoder encodeObject:self.cache_control forKey:@"Cache-Control"];
    [aCoder encodeObject:self.cookie        forKey:@"Set-Cookie"];
    [aCoder encodeObject:self.expires       forKey:@"Expires"];
    [aCoder encodeObject:self.etag          forKey:@"ETag"];
    [aCoder encodeObject:self.last_modified forKey:@"Last-Modified"];
    [aCoder encodeObject:self.bodyData      forKey:@"bodyData"];
    [aCoder encodeObject:self.date          forKey:@"Date"];
    [aCoder encodeObject:self.urlString     forKey:@"Url"];
    [aCoder encodeObject:self.content_type  forKey:@"Content-Type"];
    
}

- (id)initWithCoder:(NSCoder *)aDecoder {
    
    self.urlString = [aDecoder decodeObjectForKey:@"Url"];
    self.cache_control = [aDecoder decodeObjectForKey:@"Cache-Control"];
    self.cookie      = [aDecoder decodeObjectForKey:@"Set-Cookie"];
    self.expires = [aDecoder decodeObjectForKey:@"Expires"];
    self.last_modified = [aDecoder decodeObjectForKey:@"Last-Modified"];
    self.etag = [aDecoder decodeObjectForKey:@"ETag"];
    self.bodyData = [aDecoder decodeObjectForKey:@"bodyData"];
    self.date = [aDecoder decodeObjectForKey:@"Date"];
    self.content_type = [aDecoder decodeObjectForKey:@"Content-Type"];  
    return self;
}

@end
