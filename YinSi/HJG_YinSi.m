//
//  HJG_YinSi.m
//  YingSiTongYong
//
//  Created by developer on 2018/10/8.
//  Copyright © 2018 developer. All rights reserved.
//

#import "HJG_YinSi.h"
#import <UIKit/UIKit.h>

#define isFirstYinSi  @"isFirstYinSi"
@interface HJG_YinSi()

@property(nonatomic,strong)UIWindow * window;

@property (nonatomic, strong) UIView *frontView;

@property (nonatomic, strong) UIWebView *webV;

@property (nonatomic, strong) UIButton *closeBut;

@end
@implementation HJG_YinSi

- (UIWebView *)webV
{
    if (!_webV) {
        UIWebView * theView = [[UIWebView alloc] initWithFrame:CGRectMake(10, 70, [UIScreen mainScreen].bounds.size.width - 20, [UIScreen mainScreen].bounds.size.height - 200)];
        NSURL *associateBundleURL = [[NSBundle mainBundle] URLForResource:@"wangye" withExtension:@"bundle"];
        NSBundle *bundle = [NSBundle bundleWithURL:associateBundleURL];
        NSString *path = [bundle pathForResource:@"hjg_yinsi" ofType:@"html"];
        NSURL* url = [NSURL  fileURLWithPath:path];
        [theView loadRequest:[NSURLRequest requestWithURL:url]];
        [self.frontView addSubview:theView];
        _webV = theView;
    }
    return _webV;
}

- (UIView *)frontView
{
    if (!_frontView) {
        UIView * theView = [[UIView alloc] init];
        theView.backgroundColor = [UIColor whiteColor];
        theView.frame = CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height);
        _frontView = theView;
    }
    return _frontView;
}

- (UIButton *)closeBut
{
    if (!_closeBut) {
        UIButton * theView = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMidX(self.webV.frame)-50, CGRectGetMaxY(self.webV.frame) + 10, 100, 60)];
        [theView setTitle:@"同意" forState:UIControlStateNormal];
        theView.layer.cornerRadius= 30;
        theView.layer.borderColor = [UIColor blackColor].CGColor;
        theView.layer.borderWidth= 2;
        theView.clipsToBounds = YES;
        [theView setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        [theView addTarget:self action:@selector(closeButClick) forControlEvents:UIControlEventTouchUpInside];
        theView.backgroundColor = [UIColor whiteColor];
        _closeBut = theView;
    }
    return _closeBut;
}

- (void)closeButClick{
    
    [[NSUserDefaults standardUserDefaults] setObject:@"1" forKey:isFirstYinSi];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.frontView removeFromSuperview];
}

+(void)load{
    [self shareManager];
}

+(HJG_YinSi *)shareManager{
    static HJG_YinSi *instance = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken,^{
        instance = [[HJG_YinSi alloc] init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        //在UIApplicationDidFinishLaunching时初始化开屏广告,做到对业务层无干扰,当然你也可以直接在AppDelegate didFinishLaunchingWithOptions方法中初始化
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            if ([[[NSUserDefaults standardUserDefaults] objectForKey:isFirstYinSi] intValue] == 1) {}else{
                dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                    [self setupLaunchAd];
                });
            }
        }];
    }
    return self;
}

-(void)setupLaunchAd{
    _window = [UIApplication sharedApplication].keyWindow;
    [_window addSubview:self.frontView];
    [self.frontView addSubview:self.closeBut];
    [self webV];
}


@end
