//
//  FFRtsp.m
//  RTSP_Player
//
//  Created by apple on 15/3/18.
//  Copyright (c) 2015年 thinker. All rights reserved.
//

#import "FFRtsp.h"
#include "libavcodec/avcodec.h"
#include "libavformat/avformat.h"
#include "libswscale/swscale.h"

@interface FFRtsp()
@end

@implementation FFRtsp{
    
    AVFormatContext * formatCtx  ;
    AVCodecContext * codecCtx ;
    struct SwsContext *img_convert_ctx;
    char * yuvBuffer;
    int vStreamIndex ;
    BOOL isPlaying;
}


static void log_callback(void* ptr, int level, const char* fmt, va_list vl)
{
    vfprintf(stdout, fmt, vl);
}


-(int) init_rtsp_video_context {
    AVCodec *pCodec = NULL;
    int ret = -1;
    codecCtx = formatCtx->streams[vStreamIndex]->codec;
     NSLog(@"video resolution is [%d x %d]", codecCtx->width, codecCtx->height);
     pCodec = avcodec_find_decoder(codecCtx->codec_id);
     NSLog(@" avcodec_find_decoder  %p",pCodec);
    
    if (!pCodec) {
        NSLog(@"error avcodec_find_decoder ");
        return ret;
    }
    
    ret = avcodec_open2(codecCtx, pCodec, NULL);
    if ( ret < 0) {
         NSLog(@"error avcodec_open2 =%d",ret);
        return ret;
    }
    
    yuvBuffer = (char *) av_malloc(
                                   codecCtx->width * codecCtx->height * 3 / 2
                                   * sizeof(uint8_t));
    return ret;
}

-(int)init_rtsp_contex:(const char *)url {
    int ret;
    
    av_register_all();
    av_log_set_level(AV_LOG_DEBUG);
    av_log_set_callback(log_callback);
    avformat_network_init();
    AVDictionary* options = NULL;
    av_dict_set(&options, "rtsp_transport", "tcp", 0);
    ret = avformat_open_input(&formatCtx, url, NULL, &options);
//    ret = avformat_open_input(&formatCtx, url, NULL, NULL);
    
    NSLog(@" avformat_open_input ret= %d", ret);
    if (ret < 0) {
        NSLog(@" avformat_open_input error= %d", ret);
        return  ret ;
    }
    ret = avformat_find_stream_info(formatCtx,  NULL);
    NSLog(@" avformat_find_stream_info ret= %d", ret);
    if (ret < 0) {
        NSLog(@" avformat_find_stream_info error= %d", ret);
        return  ret;
    }
    
    for (int i = 0; i < formatCtx->nb_streams; i++) {
        if (formatCtx->streams[i]->codec->codec_type == AVMEDIA_TYPE_VIDEO) {
            vStreamIndex = i;
            NSLog(@"find video stream = %d", i);
            ret = [self init_rtsp_video_context];
            if(ret < 0){
                return ret;
            }
        } else if (formatCtx->streams[i]->codec->codec_type
                   == AVMEDIA_TYPE_AUDIO) {
            NSLog(@"find audio stream = %d", i);
        }
    }
    NSLog(@"init ok ");

    return ret;
}

-(void)play{
    if (isPlaying) {
        NSLog(@"video stream index error");
        return;
    }
    isPlaying = TRUE;
    
    int frameFinished = 0;
    AVPacket packet;
    AVFrame *pFrame,*pFrameYUV;
    
    pFrame = av_frame_alloc();
    pFrameYUV = av_frame_alloc();
    int numBytes = avpicture_get_size(PIX_FMT_RGB24, codecCtx->width,
                                      codecCtx->height);
    uint8_t * buffer = (uint8_t *) av_malloc(numBytes * sizeof(uint8_t));
    avpicture_fill((AVPicture *) pFrame, buffer, PIX_FMT_RGB24,
                   codecCtx->width, codecCtx->height);
    numBytes = avpicture_get_size(PIX_FMT_YUV420P, codecCtx->width, codecCtx->height);
    uint8_t * out_buffer = (uint8_t *) av_malloc(numBytes * sizeof(uint8_t));
    avpicture_fill((AVPicture *) pFrameYUV, out_buffer, PIX_FMT_YUV420P,
                   codecCtx->width, codecCtx->height);
    NSLog(@" read start ,pFram=%p, pFrameYuv=%p",pFrame,pFrameYUV);
    
    double start, end;
    
    while (isPlaying && av_read_frame(formatCtx, &packet) >= 0) {
        
        if (packet.stream_index == vStreamIndex) {
            
            start =  CFAbsoluteTimeGetCurrent()*1000;
            avcodec_decode_video2(codecCtx, pFrame, &frameFinished,
                                  &packet);
            end = CFAbsoluteTimeGetCurrent()*1000;
            NSLog(@"decode[%d X %d] use  time =%f millisecond ", codecCtx->width,codecCtx->height,(end-start));
            
            if (frameFinished) {
                
                if (!img_convert_ctx) {
                    img_convert_ctx = sws_getContext(codecCtx->width,
                                                     codecCtx->height, codecCtx->pix_fmt,
                                                     codecCtx->width, codecCtx->height,
                                                     PIX_FMT_YUV420P, SWS_FAST_BILINEAR, NULL, NULL, NULL);
                }
                
                sws_scale(img_convert_ctx,
                          (const uint8_t* const *) pFrame->data, pFrame->linesize,
                          0, codecCtx->height, pFrameYUV->data,
                          pFrameYUV->linesize);
                
                int size = (codecCtx->width) * (codecCtx->height);

                memcpy(yuvBuffer, pFrameYUV->data[0], size);
                memcpy(yuvBuffer + size, pFrameYUV->data[1], size / 4);
                memcpy(yuvBuffer + size + size / 4, pFrameYUV->data[2],
                       size / 4);
                
                if (self.delegate && [self.delegate respondsToSelector:@selector(yuvData:width:height:)])
                {
                    [self.delegate yuvData:yuvBuffer width:codecCtx->width height:codecCtx->height];
                }
            }
        }
        
    } //while
    
    av_free_packet(&packet);
    if(pFrame){
        av_frame_free(&pFrame);
    }
    if(pFrameYUV){
        av_frame_free(&pFrameYUV);
    }
    
}

-(void)stop{
    isPlaying = FALSE;
}

-(void)deinit_rtsp_context{
    
    if (codecCtx) {
        avcodec_close(codecCtx);
        codecCtx = NULL;
    }
    
    if (formatCtx) {
        avformat_close_input(&formatCtx);
        formatCtx = NULL;
    }
    
    if (yuvBuffer) {
        av_free(&yuvBuffer);
        yuvBuffer = NULL;
    }
}

@end
