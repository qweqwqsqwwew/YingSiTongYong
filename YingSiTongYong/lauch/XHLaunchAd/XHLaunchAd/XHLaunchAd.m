//
//  XHLaunchAd.m
//  XHLaunchAdExample
//
//  Created by zhuxiaohui on 2016/6/13.
//  Copyright © 2016年 it7090.com. All rights reserved.
//  代码地址:https://github.com/CoderZhuXH/XHLaunchAd

#import "XHLaunchAd.h"
#import "XHLaunchAdView.h"
#import "XHLaunchAdCache.h"
#import "XHLaunchAdController.h"

typedef NS_ENUM(NSInteger, XHLaunchAdType) {
    XHLaunchAdTypeImage,
    XHLaunchAdTypeVideo
};

static NSInteger defaultWaitDataDuration = 3;
static  SourceType _sourceType = SourceTypeLaunchImage;
@interface XHLaunchAd()

@property(nonatomic,assign)XHLaunchAdType launchAdType;
@property(nonatomic,assign)NSInteger waitDataDuration;
@property(nonatomic,strong)XHLaunchVideoAdConfiguration * videoAdConfiguration;
@property(nonatomic,strong)XHLaunchAdVideoView * adVideoView;
@property(nonatomic,strong)UIWindow * window;
@property(nonatomic,copy)dispatch_source_t waitDataTimer;
@property(nonatomic,copy)dispatch_source_t skipTimer;
@property (nonatomic, assign) BOOL detailPageShowing;
@property (nonatomic, strong) UIButton *closeBut;
@property(nonatomic,assign) CGPoint clickPoint;
@end

@implementation XHLaunchAd

- (UIButton *)closeBut
{
    if (!_closeBut) {
        UIButton * theView = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
        theView.backgroundColor = [UIColor redColor];
        [theView addTarget:self action:@selector(closeButClick) forControlEvents:UIControlEventTouchUpInside];
        _closeBut = theView;
    }
    return _closeBut;
}

- (void)closeButClick{
    
    NSLog(@"fdsfsdfdfdfd");
    
    
}

+(void)setLaunchSourceType:(SourceType)sourceType{
    _sourceType = sourceType;
}
+(void)setWaitDataDuration:(NSInteger )waitDataDuration{
    XHLaunchAd *launchAd = [XHLaunchAd shareLaunchAd];
    launchAd.waitDataDuration = waitDataDuration;
}

+(XHLaunchAd *)videoAdWithVideoAdConfiguration:(XHLaunchVideoAdConfiguration *)videoAdconfiguration{
    return [XHLaunchAd videoAdWithVideoAdConfiguration:videoAdconfiguration delegate:nil];
}

+(XHLaunchAd *)videoAdWithVideoAdConfiguration:(XHLaunchVideoAdConfiguration *)videoAdconfiguration delegate:(nullable id)delegate{
    XHLaunchAd *launchAd = [XHLaunchAd shareLaunchAd];
    if(delegate) launchAd.delegate = delegate;
    launchAd.videoAdConfiguration = videoAdconfiguration;
    return launchAd;
}


+(void)removeAndAnimated:(BOOL)animated{
    [[XHLaunchAd shareLaunchAd] removeAndAnimated:animated];
}

+(BOOL)checkImageInCacheWithURL:(NSURL *)url{
    return [XHLaunchAdCache checkImageInCacheWithURL:url];
}

+(BOOL)checkVideoInCacheWithURL:(NSURL *)url{
    return [XHLaunchAdCache checkVideoInCacheWithURL:url];
}
+(void)clearDiskCache{
    [XHLaunchAdCache clearDiskCache];
}

+(void)clearDiskCacheWithImageUrlArray:(NSArray<NSURL *> *)imageUrlArray{
    [XHLaunchAdCache clearDiskCacheWithImageUrlArray:imageUrlArray];
}

+(void)clearDiskCacheExceptImageUrlArray:(NSArray<NSURL *> *)exceptImageUrlArray{
    [XHLaunchAdCache clearDiskCacheExceptImageUrlArray:exceptImageUrlArray];
}

+(void)clearDiskCacheWithVideoUrlArray:(NSArray<NSURL *> *)videoUrlArray{
    [XHLaunchAdCache clearDiskCacheWithVideoUrlArray:videoUrlArray];
}

+(void)clearDiskCacheExceptVideoUrlArray:(NSArray<NSURL *> *)exceptVideoUrlArray{
    [XHLaunchAdCache clearDiskCacheExceptVideoUrlArray:exceptVideoUrlArray];
}

+(float)diskCacheSize{
    return [XHLaunchAdCache diskCacheSize];
}

+(NSString *)xhLaunchAdCachePath{
    return [XHLaunchAdCache xhLaunchAdCachePath];
}

+(NSString *)cacheImageURLString{
    return [XHLaunchAdCache getCacheImageUrl];
}

+(NSString *)cacheVideoURLString{
    return [XHLaunchAdCache getCacheVideoUrl];
}

#pragma mark - 过期
/** 请使用removeAndAnimated: */
+(void)skipAction{
    [[XHLaunchAd shareLaunchAd] removeAndAnimated:YES];
}
/** 请使用setLaunchSourceType: */
+(void)setLaunchImagesSource:(LaunchImagesSource)launchImagesSource{
    switch (launchImagesSource) {
        case LaunchImagesSourceLaunchImage:
            _sourceType = SourceTypeLaunchImage;
            break;
        case LaunchImagesSourceLaunchScreen:
            _sourceType = SourceTypeLaunchScreen;
            break;
        default:
            break;
    }
}

#pragma mark - private
+(XHLaunchAd *)shareLaunchAd{
    static XHLaunchAd *instance = nil;
    static dispatch_once_t oneToken;
    dispatch_once(&oneToken,^{
        instance = [[XHLaunchAd alloc] init];
    });
    return instance;
}

- (instancetype)init{
    self = [super init];
    if (self) {
        [self setupLaunchAd];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self setupLaunchAdEnterForeground];
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            [self removeOnly];
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:XHLaunchAdDetailPageWillShowNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            _detailPageShowing = YES;
        }];
        [[NSNotificationCenter defaultCenter] addObserverForName:XHLaunchAdDetailPageShowFinishNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            _detailPageShowing = NO;
        }];
    }
    return self;
}

-(void)setupLaunchAdEnterForeground{
    switch (_launchAdType) {
        case XHLaunchAdTypeVideo:{
            if(!_videoAdConfiguration.showEnterForeground || _detailPageShowing) return;
            [self setupLaunchAd];
            [self setupVideoAdForConfiguration:_videoAdConfiguration];
        }
            break;
        default:
            break;
    }
}

-(void)setupLaunchAd{
    UIWindow *window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
    window.rootViewController = [XHLaunchAdController new];
    window.rootViewController.view.backgroundColor = [UIColor clearColor];
    window.rootViewController.view.userInteractionEnabled = NO;
    window.windowLevel = UIWindowLevelStatusBar + 1;
    window.hidden = NO;
    window.alpha = 1;
    _window = window;
    /** 添加launchImageView */
    [_window addSubview:[[XHLaunchImageView alloc] initWithSourceType:_sourceType]];
    
    [_window addSubview:self.closeBut];
}


/**视频*/
-(void)setupVideoAdForConfiguration:(XHLaunchVideoAdConfiguration *)configuration{
    
    return;
    if(_window ==nil) return;
    [self removeSubViewsExceptLaunchAdImageView];
    if(!_adVideoView){
        _adVideoView = [[XHLaunchAdVideoView alloc] init];
    }
    [_window addSubview:_adVideoView];
    /** frame */
    if(configuration.frame.size.width>0&&configuration.frame.size.height>0) _adVideoView.frame = configuration.frame;
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    if(configuration.scalingMode) _adVideoView.videoScalingMode = configuration.scalingMode;
#pragma clang diagnostic pop
    if(configuration.videoGravity) _adVideoView.videoGravity = configuration.videoGravity;
    _adVideoView.videoCycleOnce = configuration.videoCycleOnce;
    if(configuration.videoCycleOnce){
        [[NSNotificationCenter defaultCenter] addObserverForName:AVPlayerItemDidPlayToEndTimeNotification object:nil queue:nil usingBlock:^(NSNotification * _Nonnull note) {
            XHLaunchAdLog(@"video不循环,播放完成");
            [[NSNotificationCenter defaultCenter] postNotificationName:XHLaunchAdVideoCycleOnceFinishNotification object:nil userInfo:@{@"videoNameOrURLString":configuration.videoNameOrURLString}];
        }];
    }
    /** video 数据源 */
    if(configuration.videoNameOrURLString.length && XHISURLString(configuration.videoNameOrURLString)){
        [XHLaunchAdCache async_saveVideoUrl:configuration.videoNameOrURLString];
        NSURL *pathURL = [XHLaunchAdCache getCacheVideoWithURL:[NSURL URLWithString:configuration.videoNameOrURLString]];
        if(pathURL){
            if ([self.delegate respondsToSelector:@selector(xhLaunchAd:videoDownLoadFinish:)]) {
                [self.delegate xhLaunchAd:self videoDownLoadFinish:pathURL];
            }
            _adVideoView.contentURL = pathURL;
            _adVideoView.muted = configuration.muted;
            [_adVideoView.videoPlayer.player play];
        }else{}
    }else{
        if(configuration.videoNameOrURLString.length){
            NSURL *pathURL = nil;
            NSURL *cachePathURL = [[NSURL alloc] initFileURLWithPath:[XHLaunchAdCache videoPathWithFileName:configuration.videoNameOrURLString]];
            //若本地视频未在沙盒缓存文件夹中
            if (![XHLaunchAdCache checkVideoInCacheWithFileName:configuration.videoNameOrURLString]) {
                /***如果不在沙盒文件夹中则将其复制一份到沙盒缓存文件夹中/下次直接取缓存文件夹文件,加快文件查找速度 */
                NSURL *bundleURL = [[NSBundle mainBundle] URLForResource:configuration.videoNameOrURLString withExtension:nil];
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [[NSFileManager defaultManager] copyItemAtURL:bundleURL toURL:cachePathURL error:nil];
                });
                pathURL = bundleURL;
            }else{
                pathURL = cachePathURL;
            }
            
            if(pathURL){
                if ([self.delegate respondsToSelector:@selector(xhLaunchAd:videoDownLoadFinish:)]) {
                    [self.delegate xhLaunchAd:self videoDownLoadFinish:pathURL];
                }
                _adVideoView.contentURL = pathURL;
                _adVideoView.muted = configuration.muted;
                [_adVideoView.videoPlayer.player play];
                
            }else{
                XHLaunchAdLog(@"Error:广告视频未找到,请检查名称是否有误!");
            }
        }else{
            XHLaunchAdLog(@"未设置广告视频");
        }
    }
    /** customView */
    if(configuration.subViews.count>0) [self addSubViews:configuration.subViews];
    XHWeakSelf
    _adVideoView.click = ^(CGPoint point) {
        [weakSelf clickAndPoint:point];
    };
}

#pragma mark - add subViews
-(void)addSubViews:(NSArray *)subViews{
    [subViews enumerateObjectsUsingBlock:^(UIView *view, NSUInteger idx, BOOL *stop) {
        [_window addSubview:view];
    }];
}

-(void)setVideoAdConfiguration:(XHLaunchVideoAdConfiguration *)videoAdConfiguration{
    _videoAdConfiguration = videoAdConfiguration;
    _launchAdType = XHLaunchAdTypeVideo;
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(CGFLOAT_MIN * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self setupVideoAdForConfiguration:videoAdConfiguration];
    });
}

-(void)setWaitDataDuration:(NSInteger)waitDataDuration{
    _waitDataDuration = waitDataDuration;
    /** 数据等待 */
    [self startWaitDataDispathTiemr];
}

#pragma mark - Action
-(void)skipButtonClick{
    [self removeAndAnimated:YES];
}

-(void)removeAndAnimated:(BOOL)animated{
    if(animated){
        [self removeAndAnimate];
    }else{
        [self remove];
    }
}

-(void)clickAndPoint:(CGPoint)point{
    self.clickPoint = point;
    XHLaunchAdConfiguration * configuration = [self commonConfiguration];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    if ([self.delegate respondsToSelector:@selector(xhLaunchAd:clickAndOpenURLString:)]) {
        [self.delegate xhLaunchAd:self clickAndOpenURLString:configuration.openURLString];
        [self removeAndAnimateDefault];
    }
    if ([self.delegate respondsToSelector:@selector(xhLaunchAd:clickAndOpenURLString:clickPoint:)]) {
        [self.delegate xhLaunchAd:self clickAndOpenURLString:configuration.openURLString clickPoint:point];
        [self removeAndAnimateDefault];
    }
#pragma clang diagnostic pop
    if ([self.delegate respondsToSelector:@selector(xhLaunchAd:clickAndOpenModel:clickPoint:)]) {
        [self.delegate xhLaunchAd:self clickAndOpenModel:configuration.openModel clickPoint:point];
                [self removeAndAnimateDefault];
    }
}

-(XHLaunchAdConfiguration *)commonConfiguration{
    XHLaunchAdConfiguration *configuration = nil;
    switch (_launchAdType) {
        case XHLaunchAdTypeVideo:
            configuration = _videoAdConfiguration;
            break;
        default:
            break;
    }
    return configuration;
}

-(void)startWaitDataDispathTiemr{
    __block NSInteger duration = defaultWaitDataDuration;
    if(_waitDataDuration) duration = _waitDataDuration;
    _waitDataTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    NSTimeInterval period = 1.0;
    dispatch_source_set_timer(_waitDataTimer, dispatch_walltime(NULL, 0), period * NSEC_PER_SEC, 0);
    dispatch_source_set_event_handler(_waitDataTimer, ^{
        if(duration==0){
            DISPATCH_SOURCE_CANCEL_SAFE(_waitDataTimer);
            dispatch_async(dispatch_get_main_queue(), ^{
                [[NSNotificationCenter defaultCenter] postNotificationName:XHLaunchAdWaitDataDurationArriveNotification object:nil];
                [self remove];
                return ;
            });
        }
        duration--;
    });
    dispatch_resume(_waitDataTimer);
}

//[self removeAndAnimate]

-(void)removeAndAnimate{
    
    XHLaunchAdConfiguration * configuration = [self commonConfiguration];
    CGFloat duration = showFinishAnimateTimeDefault;
    if(configuration.showFinishAnimateTime>0) duration = configuration.showFinishAnimateTime;
    switch (configuration.showFinishAnimate) {
        case ShowFinishAnimateNone:{
            [self remove];
        }
            break;
        case ShowFinishAnimateFadein:{
            [self removeAndAnimateDefault];
        }
            break;
        case ShowFinishAnimateLite:{
            [UIView transitionWithView:_window duration:duration options:UIViewAnimationOptionCurveEaseOut animations:^{
                _window.transform = CGAffineTransformMakeScale(1.5, 1.5);
                _window.alpha = 0;
            } completion:^(BOOL finished) {
                [self remove];
            }];
        }
            break;
        case ShowFinishAnimateFlipFromLeft:{
            [UIView transitionWithView:_window duration:duration options:UIViewAnimationOptionTransitionFlipFromLeft animations:^{
                _window.alpha = 0;
            } completion:^(BOOL finished) {
                [self remove];
            }];
        }
            break;
        case ShowFinishAnimateFlipFromBottom:{
            [UIView transitionWithView:_window duration:duration options:UIViewAnimationOptionTransitionFlipFromBottom animations:^{
                _window.alpha = 0;
            } completion:^(BOOL finished) {
                [self remove];
            }];
        }
            break;
        case ShowFinishAnimateCurlUp:{
            [UIView transitionWithView:_window duration:duration options:UIViewAnimationOptionTransitionCurlUp animations:^{
                _window.alpha = 0;
            } completion:^(BOOL finished) {
                [self remove];
            }];
        }
            break;
        default:{
            [self removeAndAnimateDefault];
        }
            break;
    }
}

-(void)removeAndAnimateDefault{
    XHLaunchAdConfiguration * configuration = [self commonConfiguration];
    CGFloat duration = showFinishAnimateTimeDefault;
    if(configuration.showFinishAnimateTime>0) duration = configuration.showFinishAnimateTime;
    [UIView transitionWithView:_window duration:duration options:UIViewAnimationOptionTransitionNone animations:^{
        _window.alpha = 0;
    } completion:^(BOOL finished) {
        [self remove];
    }];
}
-(void)removeOnly{
    DISPATCH_SOURCE_CANCEL_SAFE(_waitDataTimer)
    DISPATCH_SOURCE_CANCEL_SAFE(_skipTimer)
    if(_launchAdType==XHLaunchAdTypeVideo){
        if(_adVideoView){
            [_adVideoView stopVideoPlayer];
            REMOVE_FROM_SUPERVIEW_SAFE(_adVideoView)
        }
    }
    if(_window){
        [_window.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            REMOVE_FROM_SUPERVIEW_SAFE(obj)
        }];
        _window.hidden = YES;
        _window = nil;
    }
}

-(void)remove{
    [self removeOnly];
#pragma clang diagnostic push
#pragma clang diagnostic ignored"-Wdeprecated-declarations"
    if ([self.delegate respondsToSelector:@selector(xhLaunchShowFinish:)]) {
        [self.delegate xhLaunchShowFinish:self];
    }
#pragma clang diagnostic pop
    if ([self.delegate respondsToSelector:@selector(xhLaunchAdShowFinish:)]) {
        [self.delegate xhLaunchAdShowFinish:self];
    }
}

-(void)removeSubViewsExceptLaunchAdImageView{
    [_window.subviews enumerateObjectsUsingBlock:^(__kindof UIView * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if(![obj isKindOfClass:[XHLaunchImageView class]]){
            REMOVE_FROM_SUPERVIEW_SAFE(obj)
        }
    }];
}
-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
