//
//  quality.hpp
//  NebuIA
//
//  Created by Miguel Angel on 05/03/22.
//

#ifndef Quality_hpp
#define Quality_hpp
#if defined __cplusplus

#include <ncnn/ncnn/net.h>
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIImage.h>

class Quality {
public:
    Quality(NSString *modelName);

    ~Quality();

    float quality(UIImage *image) const;

private:
    ncnn::Net *Net;
    ncnn::UnlockedPoolAllocator blob_pool_allocator;
    ncnn::PoolAllocator workspace_pool_allocator;
};

#endif /* Quality_hpp */
#endif
