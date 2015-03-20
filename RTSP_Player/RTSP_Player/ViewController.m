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
    });
}



- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    glView = [[OpenGLView20 alloc]initWithFrame:CGRectMake(0, 100, 320, 240)];
    [self.view addSubview:glView];
    
    rtsp = [[FFRtsp alloc]init];
    [rtsp setDelegate:self];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [rtsp init_rtsp_contex:URL_288P];
    });
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(void)yuvData:(char *)data width:(int)w height:(int)h{
    
//    dispatch_async(dispatch_get_main_queue(),  ^{
    
        [glView displayYUV420pData:data width:w height:h];
        
//    });
}


@end
