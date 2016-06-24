//
//  ViewController.m
//  NetworkLearnClient
//
//  Created by iceman on 16/5/27.
//  Copyright © 2016年 iceman. All rights reserved.
//

#import "ViewController.h"
#import "ICENetWorkManager.h"
#import "ICENetWorkCacheManager.h"

@interface ViewController () <ICENetWorkResponseDelegate>

@property (nonatomic ,strong) UIImageView *imageView1;
@property (nonatomic ,strong) UIImageView *imageView2;
@property (nonatomic ,strong) UIImageView *imageView3;
@property (nonatomic ,strong) UIImageView *imageView4;
@property (nonatomic ,strong) UIImageView *imageView5;
@property (nonatomic ,strong) UIImageView *imageView6;
@property (nonatomic ,strong) UIImageView *imageView7;
@property (nonatomic ,strong) UIImageView *imageView8;

@property (nonatomic ,strong) UILabel *label1;
@property (nonatomic ,strong) UILabel *label2;
@property (nonatomic ,strong) UILabel *label3;
@property (nonatomic ,strong) UILabel *label4;
@property (nonatomic ,strong) UILabel *label5;
@property (nonatomic ,strong) UIButton *clearButton;

@property (nonatomic ,strong) UITextView *textView;

@property (nonatomic ,strong) ICENetWorkManager *manager;

@end

@implementation ViewController

- (void)viewDidLoad{
    [super viewDidLoad];
    [self.view setBackgroundColor:[UIColor whiteColor]];
    
    _manager = [ICENetWorkManager shareICENetManager];
//    [_manager getUrl:@"10.64.38.102/image1" request:nil delegate:self];
    
    
    
        [_manager getUrl:@"image.tianjimedia.com/uploadImages/2015/129/56/J63MI042Z4P8.jpg" request:nil delegate:self];
    //    [manager getUrl:@"2001:2::aab1:3e15:c2ff:febe:b7b0/image" request:nil delegate:self];
    //    [manager getUrl:@"10.64.38.116/image" request:nil delegate:self];
    //    [manager getUrl:@"10.64.38.116/image1" request:nil delegate:self];
    
    //    [manager getUrl:@"10.64.38.116/image3" request:nil delegate:self];
    //        [manager getUrl:@"g.hiphotos.baidu.com/image/h%3D200/sign=4d3fabc3cbfc1e17e2bf8b317a91f67c/6c224f4a20a446230761b9b79c22720e0df3d7bf.jpg" request:nil delegate:self];
    
    //    [manager send:nil delegate:self url:@"d.hiphotos.baidu.com/image/h%3D200/sign=4241e02c86025aafcc3279cbcbecab8d/562c11dfa9ec8a13f075f10cf303918fa1ecc0eb.jpg"];
    //    [manager send:nil delegate:self url:@"g.hiphotos.baidu.com/image/h%3D200/sign=1870ec20a96eddc439e7b3fb09dab6a2/dbb44aed2e738bd4a59870f4a58b87d6267ff9be.jpg"];
    //    [manager send:nil delegate:self url:@"b.hiphotos.baidu.com/image/h%3D200/sign=18dbdb76ad014c08063b2fa53a79025b/023b5bb5c9ea15cec72cb6d6b2003af33b87b22b.jpg"];
    //
    //
    //    [manager send:nil delegate:self url:@"h.hiphotos.baidu.com/image/pic/item/08f790529822720e23efdb327fcb0a46f31fabd0.jpg"];
    //    [manager send:nil delegate:self url:@"pic51.nipic.com/file/20141027/11284670_094822707000_2.jpg"];
    //    [manager send:nil delegate:self url:@"g.hiphotos.baidu.com/image/pic/item/03087bf40ad162d9ec74553b14dfa9ec8a13cd7a.jpg"];
    //    [manager send:nil delegate:self url:@"e.hiphotos.baidu.com/image/h%3D200/sign=fe3e730c1a178a82d13c78a0c602737f/4e4a20a4462309f7ec4a24d2760e0cf3d6cad6cd.jpg"];
    
    
    _imageView1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 100, 100, 100)];
    [self.view addSubview:_imageView1];
    
    _imageView2 = [[UIImageView alloc] initWithFrame:CGRectMake(100, 100, 100, 100)];
    //    [_imageView2 setImageWithURL:[NSURL URLWithString:@"http://image.tianjimedia.com/uploadImages/2015/129/56/J63MI042Z4P8.jpg"]];
    [self.view addSubview:_imageView2];
    
    _imageView3 = [[UIImageView alloc] initWithFrame:CGRectMake(200, 100, 100, 100)];
    [self.view addSubview:_imageView3];
    
    _imageView4 = [[UIImageView alloc] initWithFrame:CGRectMake(300, 100, 100, 100)];
    [self.view addSubview:_imageView4];
    
    
    _imageView5 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 200, 100, 100)];
    [self.view addSubview:_imageView5];
    
    _imageView6 = [[UIImageView alloc] initWithFrame:CGRectMake(100, 200, 100, 100)];
    [self.view addSubview:_imageView6];
    
    _imageView7 = [[UIImageView alloc] initWithFrame:CGRectMake(200, 300, 100, 100)];
    [self.view addSubview:_imageView7];
    
    _imageView8 = [[UIImageView alloc] initWithFrame:CGRectMake(300, 300, 100, 100)];
    [self.view addSubview:_imageView8];
    
    
    _label1 = [[UILabel alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height/2 - 50, 50, 50)];
    [self.view addSubview:_label1];
    
    _label2 = [[UILabel alloc] initWithFrame:CGRectMake(100, [[UIScreen mainScreen] bounds].size.height/2 - 50, 50, 50)];
    [self.view addSubview:_label2];
    
    _label3 = [[UILabel alloc] initWithFrame:CGRectMake(150, [[UIScreen mainScreen] bounds].size.height/2 - 50, 50, 50)];
    [self.view addSubview:_label3];
    
    _label4 = [[UILabel alloc] initWithFrame:CGRectMake(200, [[UIScreen mainScreen] bounds].size.height/2 - 50, 50, 50)];
    [self.view addSubview:_label4];
    
    _label5 = [[UILabel alloc] initWithFrame:CGRectMake(250, [[UIScreen mainScreen] bounds].size.height/2 - 50, 50, 50)];
    [self.view addSubview:_label5];
    
    _textView = [[UITextView alloc] initWithFrame:CGRectMake(10,[[UIScreen mainScreen] bounds].size.height/2, [[UIScreen mainScreen] bounds].size.width-15, [[UIScreen mainScreen] bounds].size.height/2)];
    _textView.editable = NO;
    [self.view addSubview:_textView];
    
    _clearButton = [[UIButton alloc] initWithFrame:CGRectMake(([[UIScreen mainScreen] bounds].size.width-100)/2, 30, 100, 40)];
    [_clearButton setTitle:@"清理缓存" forState:UIControlStateNormal];
    [_clearButton setTitleColor:[UIColor purpleColor] forState:UIControlStateNormal];
    [_clearButton setTitleColor:[UIColor whiteColor] forState:UIControlStateHighlighted];
    [_clearButton setBackgroundColor:[UIColor colorWithWhite:0.5 alpha:0.1]];
    _clearButton.layer.cornerRadius = 5;
    _clearButton.layer.borderColor = [UIColor darkGrayColor].CGColor;
    
    [_clearButton addTarget:self action:@selector(clear) forControlEvents:UIControlEventTouchDown];
    [self.view addSubview:_clearButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NSLogRedirectNotificationHandle:)
                                                 name:NSFileHandleReadCompletionNotification
                                               object:nil]; // 注册通知
}



- (void)iceSocketNetworkImageFinish:(NSData *)responseData error:(NSError *)error
{
    static int x= 0;
    
    NSLog(@"%ld",responseData.length);
    
    
    if (x == 0) {
        UIImage *image = [UIImage imageWithData:responseData];
        NSData *data = UIImagePNGRepresentation(image);
        
        _imageView1.image = [UIImage imageWithData:data];
    }else if (x == 1){
        UIImage *image = [UIImage imageWithData:responseData];
        _imageView2.image = image;
    }else if (x == 2){
        UIImage *image = [UIImage imageWithData:responseData];
        _imageView3.image = image;
    }else if (x == 3){
        UIImage *image = [UIImage imageWithData:responseData];
        _imageView4.image = image;
    }else if (x == 4){
        UIImage *image = [UIImage imageWithData:responseData];
        _imageView5.image = image;
    }else if (x == 5){
        UIImage *image = [UIImage imageWithData:responseData];
        _imageView6.image = image;
    }else if (x == 6){
        UIImage *image = [UIImage imageWithData:responseData];
        _imageView7.image = image;
    }else if (x == 7){
        UIImage *image = [UIImage imageWithData:responseData];
        _imageView8.image = image;
    }
    
    x++;
    
}

- (void)iceSocketNetworkTextFinish:(NSData *)responseData error:(NSError *)error
{
    static int y = 0;
    
    if (y == 0) {
        _label1.text = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    }else if (y == 1){
        _label2.text = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    }else if (y == 2){
        _label3.text = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    }else if (y == 3){
        _label4.text = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    }else if (y == 4){
        _label5.text = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    }
}


- (void)clear
{
    [ICENetWorkCacheManager clearCache];
}

- (void)NSLogRedirectNotificationHandle:(NSNotification *)nf{ // 通知方法
    NSData *data = [[nf userInfo] objectForKey:NSFileHandleNotificationDataItem];
    NSString *str = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    
    self.textView.text = [NSString stringWithFormat:@"%@\n\n%@",self.textView.text, str];// logTextView 就是要将日志输出的视图（UITextView）
    NSRange range;
    range.location = [self.textView.text length] - 1;
    range.length = 0;
    [self.textView scrollRangeToVisible:range];
    [[nf object] readInBackgroundAndNotify];
}


@end
