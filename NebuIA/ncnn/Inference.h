//
//  Inference.hpp
//  NebuIA
//
//  Created by Miguel Angel on 09/11/21.
//

#ifndef Inference_hpp
#define Inference_hpp
#if defined __cplusplus

#include <stdio.h>
#include <ncnn/ncnn/net.h>
#include <ncnn/ncnn/layer.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIImage.h>

struct Object
{
    float x;
    float y;
    float w;
    float h;
    int label;
    float prob;
};

class Inference {
public:
    Inference(NSString *modelName);

    ~Inference();

    std::vector<Object> detect(UIImage *image) const;

private:
    ncnn::Net *Net;
    int target_size = 416;
    ncnn::UnlockedPoolAllocator blob_pool_allocator;
    ncnn::PoolAllocator workspace_pool_allocator;
};

#endif /* Inference_hpp */
#endif
