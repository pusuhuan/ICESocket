//
//  ICENetWorkManger+Cache.m
//  NetworkLearnClient
//
//  Created by iceman on 16/6/3.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import "ICENetWorkCacheManager.h"

@interface ICENetWorkCacheManager()

@property (nonatomic ,strong) NSMutableDictionary *responseChcheDic;

@end


@implementation ICENetWorkCacheManager

- (NSData *)dataWithMethodGetURL:(NSString *)urlString
{
    return nil;
}

- (void)cache:(ICESocketHttpResponse *)response
{
#warning 细化，考虑缓存下载一半
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    [formatter setDateFormat:@"EEE, dd MM yyyy HH:mm:ss Z"];
    response.date = [formatter stringFromDate:[NSDate date]];
    [self.responseChcheDic setObject:response forKey:response.urlString];
    [[NSUserDefaults standardUserDefaults] setObject:[NSKeyedArchiver archivedDataWithRootObject:_responseChcheDic] forKey:@"responseDic"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
//    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
//    NSString *docDir = [paths objectAtIndex:0];
//    [[NSFileManager defaultManager] createFileAtPath:[docDir stringByAppendingPathComponent:@"123"]  contents:response.bodyData attributes:nil];
    
}

-(NSData *)getCacheBody:(ICESocketHttpResponse *)response
{
    return ((ICESocketHttpResponse*)[_responseChcheDic objectForKey:response.urlString]).bodyData;
}

//缓存规则解析,仅针对http1.1
-(ICESocketHttpResponse *)getCacheWithRequest:(ICESocketHttpRequest **)request
{
    NSLog(@"-----------开始检查缓存----------");
    ICESocketHttpResponse *response = [self.responseChcheDic objectForKey:(*request).url];
    
    if(response.cache_control){
        if ([response.cache_control isEqualToString:@"no-cache"])
        {
            (*request).if_none_match = response.etag;
            (*request).if_modified_since = response.last_modified;
            NSLog(@"cache-control = \"no-cache\"");
            if (response.etag) {
                NSLog(@"Etag : %@",response.etag);
            }
            if (response.last_modified) {
                NSLog(@"Last-Modified : %@",response.last_modified);
            }
            return nil;
        }
        else if([response.cache_control isEqualToString:@"no-store"])
        {
            NSLog(@"cache-control = \"no-store\"");
            return nil;
        }
        else if ([response.cache_control isEqualToString:@"private"] ||[response.cache_control containsString:@"max-age"] || [response.cache_control isEqualToString:@"public"])
        {
            NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
            [formatter setDateFormat:@"EEE, dd MM yyyy HH:mm:ss Z"];
            //NSString转NSDate
            NSDate *date=[formatter dateFromString:response.date];
            NSDate *nowDate = [NSDate date];
            
            NSArray *array = [response.cache_control componentsSeparatedByString:@","];
            if (array.count > 0) {
                for (NSString *string in array) {
                    if ([string containsString:@"max-age"]) {
                        NSArray *tempArray = [string componentsSeparatedByString:@"="];
                        if (tempArray.count > 1) {
                            response.max_age = tempArray[1];
                        }
                    }
                }
            }
            
//            if (!response.max_age) {
//                NSRange range = [response.cache_control rangeOfString:@"max-age="];
//                if (response.cache_control.length > range.length && range.length!= 0) {
//                    response.max_age = [response.cache_control substringFromIndex:range.location+range.length];
//                }
//            }
            
            if (nowDate.timeIntervalSince1970 < [date dateByAddingTimeInterval:[response.max_age intValue]].timeIntervalSince1970){
                return response;
            }else{
                (*request).if_none_match = response.etag;
                (*request).if_modified_since = response.last_modified;
            }
            
            NSLog(@"cache-control = response.cache_control");
            if (response.etag) {
                NSLog(@"Etag : %@",response.etag);
            }
            if (response.last_modified) {
                NSLog(@"Last-Modified : %@",response.last_modified);
            }
            
            return nil;
        }
        else if ([response.cache_control isEqualToString:@"min-fresh"])
        {
            return nil;
        }
        else if ([response.cache_control isEqualToString:@"max-stale"])
        {
            return nil;
        }
    }
    else if (response.expires)
    {
        NSDate *nowDate = [NSDate date];
        NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
//        formatter.timeStyle = NSDateFormatterFullStyle;
//        formatter.dateStyle = NSDateFormatterFullStyle;
//        [formatter setDateFormat:@"yyyy-MM-dd HH:mm:ss"];
        [formatter setDateFormat:@"EEE, dd MM yyyy HH:mm:ss Z"];
        NSDate *date=[formatter dateFromString:response.expires];
        if (date.timeIntervalSince1970 > nowDate.timeIntervalSince1970){
            return  response;
        }
    }
    
    return nil;
}


- (NSMutableDictionary *)responseChcheDic
{
    if (!_responseChcheDic){
        _responseChcheDic = [[NSMutableDictionary alloc] init];
        NSData * data = [[NSUserDefaults standardUserDefaults] objectForKey:@"responseDic"];
        [_responseChcheDic setValuesForKeysWithDictionary:[NSKeyedUnarchiver unarchiveObjectWithData:data]];
    }
    
    return _responseChcheDic;
}

//得到用户信息
-(ICESocketHttpRequest *)getUserinfo
{
    //    NSString *documents = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    //    NSString *path = [documents stringByAppendingPathComponent:@"user.archiver"];//拓展名可以自己随便取
    //    User *user = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    //    return user;
    return nil;
}

+ (void)clearCache
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:@"responseDic"];
}

@end
