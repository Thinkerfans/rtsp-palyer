//
//  FFRtsp.h
//  RTSP_Player
//
//  Created by apple on 15/3/18.
//  Copyright (c) 2015年 thinker. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol TRSPProtocol <NSObject>
@required
-(void) yuvData: (char * )data width:(int) w height:(int) h;
@end

@interface FFRtsp : NSObject

@property(nonatomic ,retain) id<TRSPProtocol>delegate;

-(int)init_rtsp_contex:(const char *)url ;
-(void)play;
-(void)stop;
-(void)deinit_rtsp_context;


@end

