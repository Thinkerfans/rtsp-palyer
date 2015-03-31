//
//  ViewController.m
//  RTSP_Player
//
//  Created by apple on 15/3/18.
//  Copyright (c) 2015年 thinker. All rights reserved.
//

#import "ViewController.h"
#import "FFRtsp.h"
#import "OpenGLView20.h"

@interface ViewController()<TRSPProtocol>

@end

@implementation ViewController{
    FFRtsp * rtsp;
    OpenGLView20 * glView;
    UIDeviceOrientation orientation;
    CGFloat screenWidth;
    CGFloat screenHeight;
    NSLock *lock ;

}


const char * URL_720P = "rtsp://stream1.gzcbn.tv:1935/app_2/ls_1.stream?domain=gztv";
const char * URL_288P = "rtsp://218.204.223.237:554/live/1/66251FC11353191F/e7ooqwcfbqjoo80j.sdp";

- (IBAction)stop:(id)sender {
    [rtsp stop];
}

- (IBAction)play:(id)sender {
    //主线程执行
//    dispatch_async(dispatch_get_main_queue(),  ^{
//        [rtsp play];
//    });
    
    //非主线程执行
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [rtsp play];
        NSLog(@"thread %s , %@",__FUNCTION__,[NSThread currentThread]);

    });
}



- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSLog(@" thread %s , %@",__FUNCTION__,[NSThread currentThread]);

    // Do any additional setup after loading the view, typically from a nib.
    screenWidth = [[UIScreen mainScreen] bounds].size.width;
    screenHeight = [[UIScreen mainScreen] bounds].size.height;
    lock = [[NSLock alloc] init];

    
    rtsp = [[FFRtsp alloc]init];
    [rtsp setDelegate:self];
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didRotate:) name:UIApplicationDidChangeStatusBarOrientationNotification  object:nil];
    orientation = (UIDeviceOrientation)[UIApplication sharedApplication].statusBarOrientation;    //This is more reliable than (self.interfaceOrientation) and [[UIDevice currentDevice] orientation] (which may give a faceup type value)
    if (orientation == UIDeviceOrientationUnknown || orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown)
    {
        orientation = UIDeviceOrientationPortrait;
    }
    
    glView = [[OpenGLView20 alloc]init];
    [self initWindowViews];
    [self.view addSubview:glView];


    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [rtsp init_rtsp_contex:URL_288P];
    });
}

//-(NSUInteger)supportedInterfaceOrientations{
//    return UIInterfaceOrientationMaskAllButUpsideDown;  // 可以修改为任何方向
//}
//
//-(BOOL)shouldAutorotate{
//    return YES;
//}
//// iOS5.0
//-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
//    return UIInterfaceOrientationMaskAllButUpsideDown;  // 可以修改为任何方向
//}


-(void)didRotate:(NSNotification *)notification{
    
   UIDeviceOrientation newOrientation = [[UIDevice currentDevice] orientation];
    if (newOrientation != UIDeviceOrientationPortraitUpsideDown && newOrientation != UIDeviceOrientationUnknown && newOrientation != UIDeviceOrientationFaceUp && newOrientation != UIDeviceOrientationFaceDown && newOrientation != orientation){
        orientation =   newOrientation;
        [self initWindowViews];
    }
}

-(void)initWindowViews{
    if (orientation == UIDeviceOrientationLandscapeLeft || orientation == UIDeviceOrientationLandscapeRight) {
        [self setToLandscape];
    }else{
        [self setToPortrait];
    }
}

-(void)setToLandscape{
    [self.navigationController setNavigationBarHidden:YES];
    CGFloat width = screenWidth/0.75;
    [lock lock];
    [glView setFrame:CGRectMake((screenHeight-width)/2, 0, width, screenWidth)];
    [lock unlock];
    NSLog(@"didRotate landscape  : CGFloat x=%f, CGFloat y=%f, CGFloat width=%f, CGFloat height=%f ",(screenHeight-width)/2,0.0,width,screenWidth);
}

-(void)setToPortrait{
    [self.navigationController setNavigationBarHidden:NO];
    CGFloat height = screenWidth * 0.75;
    [lock lock];
    [glView setFrame:CGRectMake(0, (screenHeight-height)/2, screenWidth, height)];
    [lock unlock];
    NSLog(@"didRotate portrait  : CGFloat x=%f, CGFloat y=%f, CGFloat width=%f, CGFloat height=%f ",0.0,(screenWidth-height)/2,screenWidth,height);
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)yuvData:(char *)data width:(int)w height:(int)h{
    NSLog(@"thread %s , %@",__FUNCTION__,[NSThread currentThread]);

//    dispatch_async(dispatch_get_main_queue(),  ^{
    
        [glView displayYUV420pData:data width:w height:h];
    
//    });
}


@end
