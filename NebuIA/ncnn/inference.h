//
//  Inference.hpp
//  NebuIA
//
//  Created by Miguel Angel on 09/11/21.
//

#ifndef Inference_hpp
#define Inference_hpp
#if defined __cplusplus

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

    std::vector<Object> detect(UIImage *image, int items) const;

private:
    ncnn::Net *Net;
    int target_size = 320;
    const float mean_values[3] = {103.53f, 116.28f, 123.675f};
    const float norm_values[3] = {0.017429f, 0.017507f, 0.017125f};
    ncnn::UnlockedPoolAllocator blob_pool_allocator;
    ncnn::PoolAllocator workspace_pool_allocator;
};

#endif /* Inference_hpp */
#endif
