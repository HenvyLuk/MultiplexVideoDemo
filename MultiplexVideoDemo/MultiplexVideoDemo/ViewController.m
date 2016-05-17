//
//  ViewController.m
//  videoDemo
//
//  Created by csh on 16/5/10.
//  Copyright © 2016年 csh. All rights reserved.
//

#import "ViewController.h"
#import <MediaPlayer/MediaPlayer.h>
#import <CoreMedia/CoreMedia.h>
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()<UIGestureRecognizerDelegate>
@property(nonatomic,strong)AVPlayer *player1;
@property(nonatomic,strong)AVPlayer *player2;
@property(nonatomic,assign)BOOL isPlaying;
@property(nonatomic,strong)AVPlayerItem *item1;
@property (weak, nonatomic) IBOutlet UIButton *playOrPauseBtn;
@property(nonatomic,strong)AVPlayerItem *item2;

@property (nonatomic,assign)AVPlayerLayer *layer1;
@property (weak, nonatomic) IBOutlet UISlider *topSlider;
@property (weak, nonatomic) IBOutlet UISlider *bottomSlider;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;
@property (nonatomic,assign)AVPlayerLayer *layer2;
@property (weak, nonatomic) IBOutlet UIButton *previousBtn;
@property (nonatomic,strong)NSTimer *playTime;
@property (nonatomic,assign)NSTimeInterval interval1;
@property (nonatomic,assign)NSTimeInterval interval2;
@property (weak, nonatomic) IBOutlet UIView *topCover;
@property (weak, nonatomic) IBOutlet UIView *bottomCover;
@property (nonatomic,assign) BOOL isSingleView;
@property (nonatomic,strong) UIView *controlView;
@property (nonatomic,assign) CGRect tempRect1;
@property (nonatomic,assign) CGRect tempRect2;
@property (weak, nonatomic) IBOutlet UIProgressView *topProView;
@property (weak, nonatomic) IBOutlet UIProgressView *botProView;
@property (nonatomic,strong)UISlider *currentSlider;
@property (nonatomic,strong)UIButton *backBtn;
@property (nonatomic,strong)NSMutableArray *viewArr;
@property (nonatomic,strong)NSTimer *topAndBottomViewHiddenTimer;
@property (nonatomic,assign)BOOL isTopAndBottomShowing;
@property (nonatomic,strong)NSString *isTopAndBottomShouldShow;
@end

#define W self.view.frame.size.width
#define H self.view.frame.size.height
#define ORIENTATION [UIDevice currentDevice].orientation
@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self createAvPlayer];
    [self addGesture];
    
    [self startPlay];
    _isSingleView = NO;
    
    //开始播放通知
    //[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(startPlay:) name:@"startPlay" object:nil];
    //播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    
    _tempRect1 = _topSlider.frame;
    _tempRect2 = _bottomSlider.frame;
    
}
#pragma mark - 计算缓冲进度
- (NSTimeInterval)availableDuration:(AVPlayer *)player {
    NSArray * ranges = [[player currentItem] loadedTimeRanges];
    CMTimeRange timeRange = [ranges.firstObject CMTimeRangeValue];// 获取缓冲区域
    CGFloat startSeconds = CMTimeGetSeconds(timeRange.start);
    CGFloat durationSeconds = CMTimeGetSeconds(timeRange.duration);
    NSTimeInterval result = startSeconds + durationSeconds;// 计算缓冲总进度
    return result;
}

#pragma mark - KVO
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context {
    if ([keyPath isEqualToString:@"isTopAndBottomShouldShow"]) {
        NSLog(@"isTopAndBottomShouldShow=%@",_isTopAndBottomShouldShow);
        if ([change[@"new"] isEqualToString:@"1"]) {
            [self topAndBottomViewWillDisAppear:nil];
        }
    }else if ([keyPath isEqualToString:@"loadedTimeRanges"]) {
        NSTimeInterval timeInterval1 = [self availableDuration:_player1];// 计算缓冲进度
        NSTimeInterval timeInterval2 = [self availableDuration:_player2];
        CMTime duration1 = _item1.duration;
        CMTime duration2 = _item2.duration;
        CGFloat totalDuration1 = CMTimeGetSeconds(duration1);
        CGFloat totalDuration2 = CMTimeGetSeconds(duration2);
        [_topProView setProgress:timeInterval1 / totalDuration1 animated:NO];
        [_botProView setProgress:timeInterval2 / totalDuration2 animated:NO];
    }
    
    
}

- (void)startPlay{
    _isPlaying = YES;
    [_player1 play];
    [_player2 play];
    //进度条随播放进度移动
    _playTime = [NSTimer scheduledTimerWithTimeInterval:0.25f target:self selector:@selector(progressSliderMove:) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:_playTime
                              forMode:NSDefaultRunLoopMode];
    [_playTime fire];
    
    [_topSlider addTarget:self action:@selector(topSliderChange:) forControlEvents:UIControlEventValueChanged];
    [_bottomSlider addTarget:self action:@selector(bottomSliderChange:) forControlEvents:UIControlEventValueChanged];
    
    [_item1 addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
    [_item2 addObserver:self forKeyPath:@"loadedTimeRanges" options:NSKeyValueObservingOptionNew context:nil];
}

#pragma mark - 进度条
- (void)progressSliderMove:(id)sender {
    //进度条
    _topSlider.value = (CGFloat)CMTimeGetSeconds([_item1 currentTime]);
    _bottomSlider.value = (CGFloat)CMTimeGetSeconds([_item2 currentTime]);
}
- (void)topSliderChange:(id)sender {
    //NSLog(@"progressSliderChange1");
    CMTime cmTime1 = CMTimeMake(_topSlider.value, 1);
    [_player1 seekToTime:cmTime1];
    
}
- (void)bottomSliderChange:(id)sender {
    //NSLog(@"progressSliderChange2");
    CMTime cmTime2 = CMTimeMake(_bottomSlider.value, 1);
    [_player2 seekToTime:cmTime2];
}

- (IBAction)playOrPauseClick:(UIButton*)sender {
    _isPlaying = !_isPlaying;
    sender.selected = !sender.selected;
    if (_isPlaying) {
        [_player1 play];
        [_player2 play];
    }else{
        [_player1 pause];
        [_player2 pause];
        //[self topAndBottomViewWillDisAppear:nil];
    }
    
}
- (IBAction)previousClick:(id)sender {
    
}
- (IBAction)nextClick:(id)sender {
    
}
//http://data.vod.itc.cn/?prod=app&new=/10/66/eCGPkAewSVqy9P57hvB11D.mp4
//http://v.youku.com/v_show/id_XMTU1MzgwNzM5Ng==.html
- (void)createAvPlayer{
    NSURL *url1 = [[NSBundle mainBundle] URLForResource:@"1" withExtension:@"mp4"];
    NSURL *url2 = [[NSBundle mainBundle] URLForResource:@"2" withExtension:@"mp4"];
    NSURL *netPath = [NSURL URLWithString:@"http://data.vod.itc.cn/?prod=app&new=/10/66/eCGPkAewSVqy9P57hvB11D.mp4"];
    NSURL *rtsp = [NSURL URLWithString:@"rtmp://192.168.2.244/vod/test.mp4"];
    _item1 = [AVPlayerItem playerItemWithURL:netPath];
    _player1 = [AVPlayer playerWithPlayerItem:_item1];
    _item2 = [AVPlayerItem playerItemWithURL:netPath];
    _player2 = [AVPlayer playerWithPlayerItem:_item2];
    _layer1 = [AVPlayerLayer playerLayerWithPlayer:self.player1];
    _layer1.frame = CGRectMake(0, 40, W, W*.7);
    _layer1.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:_layer1];
    
    _layer2 = [AVPlayerLayer playerLayerWithPlayer:self.player2];
    _layer2.frame = CGRectMake(0, H-40-W*.7, W, W*.7);
    _layer2.videoGravity = AVLayerVideoGravityResizeAspect;
    [self.view.layer addSublayer:_layer2];
    
    //[self.player1 play];
    //[self.player2 play];
    [self timeFromUrl:url1 withSlider:_topSlider];
    [self timeFromUrl:url2 withSlider:_bottomSlider];
    
    
}
- (void)timeFromUrl:(NSURL *)url withSlider:(UISlider *)slider{
    NSDictionary *opts = [NSDictionary dictionaryWithObject:[NSNumber numberWithBool:NO]
                                                     forKey:AVURLAssetPreferPreciseDurationAndTimingKey];
    AVURLAsset *urlAsset = [AVURLAsset URLAssetWithURL:url options:opts];
    float second = 0;
    second = urlAsset.duration.value/urlAsset.duration.timescale;
    NSLog(@"movie duration : %f", second);
    slider.maximumValue = second;
}

- (void)playEnd:(NSNotification *)info{
    NSLog(@"%@",[info object]);
    if ([[info object] isEqual:_item1]) {
        _interval1 = [[NSDate date] timeIntervalSince1970] * 1000;
        _topSlider.value = 0;
        [_player1 pause];
        [_player1 seekToTime:kCMTimeZero];
        if (_interval2 > 0) {
            _playOrPauseBtn.selected = YES;
            _isPlaying = NO;
            
        }
    }else if ([[info object] isEqual:_item2]){
        _interval2 = [[NSDate date] timeIntervalSince1970] * 1000;
        _bottomSlider.value = 0;
        [_player2 pause];
        [_player2 seekToTime:kCMTimeZero];
        if (_interval1 > 0) {
            _playOrPauseBtn.selected = YES;
            _isPlaying = NO;
            
        }
        
    }
    NSLog(@"playEnd");
}
//1463030834406.824219
//1463030869434.629883
-(void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    //    switch (interfaceOrientation) {
    //        caseUIInterfaceOrientationPortrait: //home健在下 break;
    //        caseUIInterfaceOrientationPortraitUpsideDown: //home健在上 break; caseUIInterfaceOrientationLandscapeLeft: //home健在左 break; caseUIInterfaceOrientationLandscapeRight: //home健在右 break; default: break; }方法五再屏幕旋转的时候记录下来屏幕的方向 着样做的画需要再窗后启动的时候让屏幕进行一次旋转，否则的画当程序启动的时候 屏幕的方向会有问题
    
    switch (toInterfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            [self adjustTempRectAndSaved];
            break;
        case UIInterfaceOrientationLandscapeRight:
            [self adjustTempRectAndSaved];
            [self hiddenWithBool:NO];
        case UIInterfaceOrientationLandscapeLeft:
            [self adjustTempRectAndSaved];
        case UIInterfaceOrientationPortraitUpsideDown:
            [self adjustTempRectAndSaved];
        default:
            break;
    }
    
}

- (void)adjustTempRectAndSaved{
    [self adjustLayerFrameWithLayer:_layer1 withLayer:_layer2];
    _tempRect1 = _topSlider.frame;
    _tempRect2 = _bottomSlider.frame;
}

- (void)adjustLayerFrameWithLayer:(AVPlayerLayer *)layer1 withLayer:(AVPlayerLayer *)layer2{
    if (ORIENTATION == UIInterfaceOrientationPortrait || ORIENTATION == UIInterfaceOrientationPortraitUpsideDown) {
        layer1.frame = CGRectMake(0, 40, W, W*.7);
        layer2.frame = CGRectMake(0, H-40-W*.7, W, W*.7);
        
    }if (ORIENTATION == UIInterfaceOrientationLandscapeRight || ORIENTATION == UIInterfaceOrientationLandscapeLeft) {
        layer1.frame = CGRectMake(20, 80, W*.45,H*.6 );
        layer2.frame = CGRectMake(W-20-W*.45, 80, W*.45,H*.6 );
        
    }
    
}

- (void)addGesture{
    //    UILongPressGestureRecognizer *longPress = [[UILongPressGestureRecognizer alloc]initWithTarget:self action:@selector(handlePress:)];
    //    longPress.delegate = self;
    //    longPress.minimumPressDuration = 1.0f;
    //    [self.nextBtn addGestureRecognizer:longPress];
    //    [self.previousBtn addGestureRecognizer:longPress];
    _topCover.userInteractionEnabled = YES;
    _bottomCover.userInteractionEnabled = YES;
    UITapGestureRecognizer *topTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(topLayerFullscreenbBtn)];
    [_topCover addGestureRecognizer:topTap];
    UITapGestureRecognizer *botTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(botLayerFullscreenbBtn)];
    [_bottomCover addGestureRecognizer:botTap];
}

- (CABasicAnimation *)addAnimation:(NSString *)keyPath withFromValue:(NSValue *)fromValue withToValue:(NSValue *)toValue{
    CABasicAnimation *animation = [CABasicAnimation animationWithKeyPath:keyPath];
    animation.fromValue =  fromValue;
    animation.toValue = toValue;
    animation.fillMode = kCAFillModeForwards;
    animation.duration = 0.5;
    return animation;
}

- (void)animationClassWithOffSet:(NSString *)offSet withFlySet:(NSString *)flySet withOffPlayer:(AVPlayerLayer *)offPlayer withDownPlayer:(AVPlayerLayer *)downPlayer withOffSlider:(UISlider *)offSlider withDownSlider:(UISlider *)downSlider withOffProView:(UIProgressView *)offProView withDownProView:(UIProgressView *)downProView{
    
    CABasicAnimation *cushion = [self addAnimation:@"position" withFromValue:[NSValue valueWithCGPoint:offPlayer.position] withToValue:[NSValue valueWithCGPoint:CGPointMake(offPlayer.position.x + [offSet intValue], offPlayer.position.y + [offSet intValue])]];
    
    [offPlayer addAnimation:cushion forKey:nil];
    
    CABasicAnimation *flyOut = [self addAnimation:@"position" withFromValue:[NSValue valueWithCGPoint:offPlayer.position] withToValue:[NSValue valueWithCGPoint:CGPointMake(offPlayer.position.x+ [flySet intValue], offPlayer.position.y + [flySet intValue])]];
    
    CABasicAnimation *rotate = [self addAnimation:@"transform.scale" withFromValue:[NSNumber numberWithFloat:1.0] withToValue:[NSNumber numberWithFloat:0]];
    
    CABasicAnimation *down = [self addAnimation:@"position.y" withFromValue:@(downPlayer.position.y) withToValue:@(self.view.center.y)];
    //        down.removedOnCompletion = NO;
    //        down.fillMode = kCAFillModeForwards;
    
    CAAnimationGroup *groupAnnimation = [CAAnimationGroup animation];
    groupAnnimation.duration = 1;
    groupAnnimation.animations = @[rotate, flyOut];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500ull *NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
        [offPlayer addAnimation:groupAnnimation forKey:nil];
        [offSlider.layer addAnimation:groupAnnimation forKey:nil];
        [offProView.layer addAnimation:groupAnnimation forKey:nil];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 500ull *NSEC_PER_MSEC), dispatch_get_main_queue(), ^{
            offPlayer.frame = CGRectZero;
            //offSlider.frame = CGRectZero;
            downPlayer.frame = [UIScreen mainScreen].bounds;
            [downPlayer addAnimation:down forKey:nil];
        });
    });
    
}
- (void)topLayerFullscreenbBtn{
    [self animationClassWithOffSet:@"-40" withFlySet:@"500" withOffPlayer:_layer2 withDownPlayer:_layer1 withOffSlider:_bottomSlider withDownSlider:_topSlider withOffProView:_botProView withDownProView:_topProView];
    _isSingleView = YES;
    [self addControViewWith:_topSlider withProView:_topProView];
    _currentSlider = _topSlider;
    
}

- (void)botLayerFullscreenbBtn{
    [self animationClassWithOffSet:@"40" withFlySet:@"-500" withOffPlayer:_layer1 withDownPlayer:_layer2 withOffSlider:_topSlider withDownSlider:_bottomSlider withOffProView:_topProView withDownProView:_botProView];
    _isSingleView = YES;
    [self addControViewWith:_bottomSlider withProView:_botProView];
    _currentSlider = _bottomSlider;
}



- (void)hiddenWithBool:(BOOL)YN{
    _playOrPauseBtn.hidden =YN;
    _previousBtn.hidden = YN;
    _nextBtn.hidden = YN;
    _topSlider.hidden = YN;
    _bottomSlider.hidden = YN;
    _botProView.hidden = YN;
    _topProView.hidden = YN;
    
}

- (void)addControViewWith:(UISlider *)slider withProView:(UIProgressView *)proView{
    if (ORIENTATION == UIInterfaceOrientationLandscapeRight || ORIENTATION == UIInterfaceOrientationLandscapeLeft) {
        if (!_controlView) {
            // [_controlView becomeFirstResponder];
            [self hiddenWithBool:NO];
            _controlView = [[UIView alloc]initWithFrame:CGRectMake(0, 0, W, H)];
            _controlView.backgroundColor = [UIColor clearColor];
            [self.view addSubview:_controlView];
        }
        
        _backBtn = [[UIButton alloc]initWithFrame:CGRectMake(10, 10, 50, 50)];
        [_backBtn setImage:[UIImage imageNamed:@"back"] forState:UIControlStateNormal];
        [_controlView addSubview:_backBtn];
        [_backBtn addTarget:self action:@selector(backBtnClick) forControlEvents:UIControlEventTouchUpInside];
        
        
        UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tapScreen:)];
        [_controlView addGestureRecognizer:tap];
        
        NSArray *views = @[_playOrPauseBtn,_nextBtn,_previousBtn,proView,slider];
        [views enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            [_controlView addSubview:obj];
        }];
        
        [self performSelector:@selector(switchSliderWith:) withObject:[NSArray arrayWithObjects:slider,proView, nil] afterDelay:0.5];
        _viewArr = [NSMutableArray arrayWithArray:views];
        [_viewArr addObject:_backBtn];
        
        _isTopAndBottomShouldShow = @"2";
        [self addObserver:self forKeyPath:@"isTopAndBottomShouldShow" options:NSKeyValueObservingOptionNew context:nil];
        [self topAndBottomViewWillDisAppear:nil];
        _isTopAndBottomShowing = YES;
        //[self tapScreen];
        
        
        
        if ([slider isEqual:_topSlider]) {
            _botProView.hidden = YES;
            _bottomSlider.hidden = YES;
            _topSlider.hidden = NO;
        }else{
            _topProView.hidden = YES;
            _bottomSlider.hidden = NO;
            _topSlider.hidden = YES;
        }
        
        
    }if (ORIENTATION == UIInterfaceOrientationPortrait || ORIENTATION == UIInterfaceOrientationPortraitUpsideDown) {
        [self hiddenWithBool:YES];
        self.view.userInteractionEnabled = YES;
        [self addSwipeGesture];
        
    }
}


#pragma mark - 手势识别
//点击屏幕
- (void)tapScreen:(id)sender {
    if (_isTopAndBottomShowing) { //正在显示上下View
        [_topAndBottomViewHiddenTimer invalidate];
        [self topAndBottomViewDisAppear:nil];
    }
    else {  //没有显示上下View
        [_topAndBottomViewHiddenTimer invalidate];
        [self topAndBottomViewDidAppear:nil];
    }
}
//隐藏
- (void)topAndBottomViewWillDisAppear:(id)sender {
    [_topAndBottomViewHiddenTimer invalidate];
    _topAndBottomViewHiddenTimer = [NSTimer scheduledTimerWithTimeInterval:3.0f target:self selector:@selector(topAndBottomViewDisAppear:) userInfo:nil repeats:NO];
    [[NSRunLoop mainRunLoop] addTimer:_topAndBottomViewHiddenTimer forMode:NSDefaultRunLoopMode];
}

- (void)topAndBottomViewDisAppear:(id)sender {
    __weak typeof(self) selfweak = self;
    [UIView animateWithDuration:0.2f delay:0 options:UIViewAnimationOptionCurveLinear animations:^{
        [_viewArr enumerateObjectsUsingBlock:^(UIView* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.hidden = YES;
        }];
    } completion:^(BOOL finished) {
        _isTopAndBottomShowing = NO;
        [selfweak setValue:@"2" forKey:@"isTopAndBottomShouldShow"];
    }];
    
}
//显示
- (void)topAndBottomViewDidAppear:(id)sender {
    [_topAndBottomViewHiddenTimer invalidate];
    __weak typeof(self) selfweak = self;
    [UIView animateWithDuration:0.2 animations:^{
        [_viewArr enumerateObjectsUsingBlock:^(UIView* obj, NSUInteger idx, BOOL * _Nonnull stop) {
            obj.hidden = NO;
        }];
    } completion:^(BOOL finished) {
        _isTopAndBottomShowing = YES;
        [selfweak setValue:@"1" forKey:@"isTopAndBottomShouldShow"];
    }];
    
}
- (void)addSwipeGesture{
    UISwipeGestureRecognizer *upRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [upRecognizer setDirection:(UISwipeGestureRecognizerDirectionUp)];
    [self.view addGestureRecognizer:upRecognizer];
    
    UISwipeGestureRecognizer *downRecognizer = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(handleSwipeFrom:)];
    [downRecognizer setDirection:(UISwipeGestureRecognizerDirectionDown)];
    [self.view addGestureRecognizer:downRecognizer];
}

-(void)handleSwipeFrom:(UISwipeGestureRecognizer *)recognizer{
    if(recognizer.direction==UISwipeGestureRecognizerDirectionDown) {
        NSLog(@"swipe down");
        [self backBtnClick];
        
    }
    if(recognizer.direction==UISwipeGestureRecognizerDirectionUp) {
        NSLog(@"swipe up");
        [self backBtnClick];
    }
    
}
- (void)switchSliderWith:(NSArray *)array{
    [UIView animateWithDuration:1.0 animations:^{
        [[array objectAtIndex:0] setFrame:CGRectMake(0, H-10, W, 1)];
        
    }];
    [[array objectAtIndex:1] setFrame:CGRectMake(0, H-10, W, 1)];
    
}
- (void)switchFrameWithFrame1:(CGRect )frame1 withFrame2:(CGRect )frame{
    
}
- (void)backBtnClick{
    [_viewArr enumerateObjectsUsingBlock:^(UIView* obj, NSUInteger idx, BOOL * _Nonnull stop) {
        obj.hidden = NO;
    }];
    [self adjustLayerFrameWithLayer:_layer1 withLayer:_layer2];
    
    //[_controlView removeFromSuperview];
    //_controlView.userInteractionEnabled = NO;
    // [_controlView resignFirstResponder];
    [_topSlider setFrame:_tempRect1];
    [_bottomSlider setFrame:_tempRect2];
    [_topProView setFrame:CGRectMake(_tempRect1.origin.x, _tempRect1.origin.y + 17, _tempRect1.size.width, _tempRect1.size.height)];
    [_botProView setFrame:CGRectMake(_tempRect2.origin.x, _tempRect2.origin.y + 17, _tempRect2.size.width, _tempRect2.size.height)];
    [self hiddenWithBool:NO];
    
    [self.view bringSubviewToFront:_topCover];
    [self.view bringSubviewToFront:_bottomCover];
    
    
    //[self removeObserver:self forKeyPath:@"isTopAndBottomShouldShow"];
    [_topAndBottomViewHiddenTimer invalidate];
    _controlView = nil;
    [_backBtn removeFromSuperview];
}


- (void)handlePress:(UILongPressGestureRecognizer *)gesture{
    if (gesture.state == UIGestureRecognizerStateBegan) {
        NSLog(@"UIGestureRecognizerStateBegan");
    }if (gesture.state == UIGestureRecognizerStateChanged) {
        NSLog(@"UIGestureRecognizerStateChanged");
    }if (gesture.state == UIGestureRecognizerStateEnded) {
        NSLog(@"UIGestureRecognizerStateEnded");
    }
}
#pragma mark - 系统相关
- (BOOL)prefersStatusBarHidden{
    return YES;
}
- (BOOL) shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {
    return (toInterfaceOrientation == UIInterfaceOrientationLandscapeRight);
}

- (void)pauseClick{
    
    
}

- (void)nextClick{
    NSLog(@"nextClick");
}
- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
@end








