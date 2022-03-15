//
//  quality.cpp
//  NebuIA
//
//  Created by Miguel Angel on 05/03/22.
//

#include "quality.h"
#include "ncnn/ncnn/cpu.h"


Quality::Quality(NSString *modelName) {
    Net = new ncnn::Net();
    
    ncnn::Option opt;
    opt.lightmode = true;
    opt.blob_allocator = &blob_pool_allocator;
    opt.workspace_allocator = &workspace_pool_allocator;
    opt.use_packing_layout = true;
    
    Net->opt = opt;
    
    // init param
    NSString *paramPath = [[NSBundle mainBundle] pathForResource:modelName ofType:@"param"];
    NSString *binPath = [[NSBundle mainBundle] pathForResource:modelName ofType:@"bin"];
    int rp = Net->load_param([paramPath UTF8String]);
    int rm = Net->load_model([binPath UTF8String]);
    if (rp == 0 && rm == 0) {
        printf("net load param and model success!");
    } else {
        fprintf(stderr, "net load fail,param:%d model:%d", rp, rm);
    }
}

Quality::~Quality() {
    Net->clear();
    delete Net;
}


float
Quality::quality(UIImage *image) const {
    int width = image.size.width;
    int height = image.size.height;
    unsigned char* rgba = new unsigned char[width * height * 4];
    
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGContextRef contextRef = CGBitmapContextCreate(rgba, width, height, 8, width * 4, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(contextRef);
    
    
    ncnn::Mat in = ncnn::Mat::from_pixels_resize(rgba, ncnn::Mat::PIXEL_RGBA2RGB, width, height, 320, 320);
    const float mean_values[3] = {127.5f, 127.5f, 127.5f};
    const float norm_values[3] = {1.0 / 127.5, 1.0 / 127.5, 1.0 / 127.5};
    in.substract_mean_normalize(mean_values, norm_values);
    ncnn::Extractor ex = Net->create_extractor();
    ex.input("mobilenetv2_1.00_224_input_blob", in);
    
    ncnn::Mat out;
    ex.extract("dense_blob", out);
    delete[] rgba;
    return out[0];
}
