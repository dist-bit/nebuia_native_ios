//
//  Inference.cpp
//  NebuIA
//
//  Created by Miguel Angel on 09/11/21.
//

#include "inference.h"
#include "ncnn/ncnn/cpu.h"

static inline float intersection_area(const Object &a, const Object &b) {
    if (a.x > b.x + b.w || a.x + a.w < b.x || a.y > b.y + b.h || a.y + a.h < b.y) {
        return 0.f;
    }
    
    float inter_width = std::min(a.x + a.w, b.x + b.w) - std::max(a.x, b.x);
    float inter_height = std::min(a.y + a.h, b.y + b.h) - std::max(a.y, b.y);
    
    return inter_width * inter_height;
}

static void qsort_descent_inplace(std::vector<Object> &objects, int left, int right) {
    int i = left;
    int j = right;
    float p = objects[(left + right) / 2].prob;
    
    while (i <= j) {
        while (objects[i].prob > p)
            i++;
        
        while (objects[j].prob < p)
            j--;
        
        if (i <= j) {
            // swap
            std::swap(objects[i], objects[j]);
            
            i++;
            j--;
        }
    }
    
#pragma omp parallel sections
    {
#pragma omp section
        {
            if (left < j) qsort_descent_inplace(objects, left, j);
        }
#pragma omp section
        {
            if (i < right) qsort_descent_inplace(objects, i, right);
        }
    }
}

static void qsort_descent_inplace(std::vector<Object> &objects) {
    if (objects.empty())
        return;
    
    qsort_descent_inplace(objects, 0, objects.size() - 1);
}

static void nms_sorted_bboxes(const std::vector<Object> &objects, std::vector<int> &picked,
                              float nms_threshold) {
    picked.clear();
    
    const int n = objects.size();
    
    std::vector<float> areas(n);
    for (int i = 0; i < n; i++) {
        areas[i] = objects[i].w * objects[i].h;
    }
    
    for (int i = 0; i < n; i++) {
        const Object &a = objects[i];
        
        int keep = 1;
        for (int j : picked) {
            const Object &b = objects[j];
            
            // intersection over union
            float inter_area = intersection_area(a, b);
            float union_area = areas[i] + areas[j] - inter_area;
            // float IoU = inter_area / union_area
            if (inter_area / union_area > nms_threshold)
                keep = 0;
        }
        
        if (keep)
            picked.push_back(i);
    }
}

static inline float sigmoid(float x)
{
    return 1.0f / (1.0f + exp(-x));
}

static void generate_proposals(const ncnn::Mat& pred, int stride, const ncnn::Mat& in_pad, float prob_threshold, std::vector<Object>& objects, int items)
{
    int num_grid_x = pred.w;
    int num_grid_y = pred.h;
    
    const int num_class = items;
    const int reg_max_1 = (pred.c - num_class) / 4;
    
    for (int i = 0; i < num_grid_y; i++)
    {
        for (int j = 0; j < num_grid_x; j++)
        {
            int label = -1;
            float score = -FLT_MAX;
            for (int k = 0; k < num_class; k++)
            {
                float s = pred.channel(k).row(i)[j];
                if (s > score)
                {
                    label = k;
                    score = s;
                }
            }
            
            score = sigmoid(score);
            
            if (score >= prob_threshold)
            {
                ncnn::Mat bbox_pred(reg_max_1, 4);
                for (int k = 0; k < reg_max_1 * 4; k++)
                {
                    bbox_pred[k] = pred.channel(num_class + k).row(i)[j];
                }
                {
                    ncnn::Layer* softmax = ncnn::create_layer("Softmax");
                    
                    ncnn::ParamDict pd;
                    pd.set(0, 1); // axis
                    pd.set(1, 1);
                    softmax->load_param(pd);
                    
                    ncnn::Option opt;
                    opt.num_threads = ncnn::get_big_cpu_count();;
                    opt.use_packing_layout = false;
                    
                    softmax->create_pipeline(opt);
                    
                    softmax->forward_inplace(bbox_pred, opt);
                    
                    softmax->destroy_pipeline(opt);
                    
                    delete softmax;
                }
                
                float pred_ltrb[4];
                for (int k = 0; k < 4; k++)
                {
                    float dis = 0.f;
                    const float* dis_after_sm = bbox_pred.row(k);
                    for (int l = 0; l < reg_max_1; l++)
                    {
                        dis += l * dis_after_sm[l];
                    }
                    
                    pred_ltrb[k] = dis * stride;
                }
                
                float pb_cx = j * stride;
                float pb_cy = i * stride;
                
                float x0 = pb_cx - pred_ltrb[0];
                float y0 = pb_cy - pred_ltrb[1];
                float x1 = pb_cx + pred_ltrb[2];
                float y1 = pb_cy + pred_ltrb[3];
                
                Object obj{};
                obj.x = x0;
                obj.y = y0;
                obj.w = x1 - x0;
                obj.h = y1 - y0;
                obj.label = label;
                obj.prob = score;
                
                objects.push_back(obj);
            }
        }
    }
}

Inference::Inference(NSString *modelName) {
    Net = new ncnn::Net();
    
    ncnn::Option opt;
    ncnn::set_omp_num_threads(ncnn::get_big_cpu_count());
    opt.lightmode = true;
    opt.num_threads = ncnn::get_big_cpu_count();
    opt.blob_allocator = &blob_pool_allocator;
    opt.workspace_allocator = &workspace_pool_allocator;
    
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

Inference::~Inference() {
    Net->clear();
    delete Net;
}


std::vector<Object>
Inference::detect(UIImage *image, int items) const {
    int width = image.size.width;
    int height = image.size.height;
    unsigned char* rgba = new unsigned char[width * height * 4];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGContextRef contextRef = CGBitmapContextCreate(rgba, width, height, 8, width * 4, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(contextRef);

    const float prob_threshold = 0.75f;
    const float nms_threshold = 0.9f;
    
    auto w = width;
    auto h = height;
    float scale = 1.f;
    if (w > h) {
        scale = (float) target_size / w;
        w = target_size;
        h = h * scale;
    } else {
        scale = (float) target_size / h;
        h = target_size;
        w = w * scale;
    }
    
    ncnn::Mat in = ncnn::Mat::from_pixels_resize(rgba, ncnn::Mat::PIXEL_RGBA2BGR, width, height, w, h);
    
    int w_pad = (w + 31) / 32 * 32 - w;
    int h_pad = (h + 31) / 32 * 32 - h;
    ncnn::Mat in_pad;
    ncnn::copy_make_border(in, in_pad, h_pad / 2, h_pad - h_pad / 2, w_pad / 2, w_pad - w_pad / 2, ncnn::BORDER_CONSTANT, 0.f);
    
    in_pad.substract_mean_normalize(mean_values, norm_values);
    ncnn::Extractor ex = Net->create_extractor();
    
    ex.input("in0", in_pad);
    
    std::vector<Object> proposals;
    
    {
        ncnn::Mat pred;
        ex.extract("231", pred);
        
        std::vector<Object> objects8;
        generate_proposals(pred, 8, in_pad, prob_threshold, objects8, items);
        
        proposals.insert(proposals.end(), objects8.begin(), objects8.end());
        pred.release();
    }
    
    {
        ncnn::Mat pred;
        ex.extract("228", pred);
        
        std::vector<Object> objects16;
        generate_proposals(pred, 16, in_pad, prob_threshold, objects16, items);
        
        proposals.insert(proposals.end(), objects16.begin(), objects16.end());
        pred.release();
    }
    
    {
        ncnn::Mat pred;
        ex.extract("225", pred);
        
        std::vector<Object> objects32;
        generate_proposals(pred, 32, in_pad, prob_threshold, objects32, items);
        
        proposals.insert(proposals.end(), objects32.begin(), objects32.end());
        pred.release();
    }
    
    {
        ncnn::Mat pred;
        ex.extract("222", pred);
        
        std::vector<Object> objects64;
        generate_proposals(pred, 64, in_pad, prob_threshold, objects64, items);
        
        proposals.insert(proposals.end(), objects64.begin(), objects64.end());
        pred.release();
    }
    
    qsort_descent_inplace(proposals);
    std::vector<int> picked;
    nms_sorted_bboxes(proposals, picked, nms_threshold);
    int count = picked.size();
    
    proposals.resize(count);
    for (int i = 0; i < count; i++)
    {
        proposals[i] = proposals[picked[i]];
        
        float x0 = (proposals[i].x - (w_pad / 2)) / scale;
        float y0 = (proposals[i].y - (h_pad / 2)) / scale;
        float x1 = (proposals[i].x + proposals[i].w - (w_pad / 2)) / scale;
        float y1 = (proposals[i].y + proposals[i].h - (h_pad / 2)) / scale;
        
        x0 = std::max(std::min(x0, (float)(width - 1)), 0.f);
        y0 = std::max(std::min(y0, (float)(height - 1)), 0.f);
        x1 = std::max(std::min(x1, (float)(width - 1)), 0.f);
        y1 = std::max(std::min(y1, (float)(height - 1)), 0.f);
        
        proposals[i].x = x0;
        proposals[i].y = y0;
        proposals[i].w = x1;
        proposals[i].h = y1;
    }
    
    in.release();
    in_pad.release();
    
    delete[] rgba;
    return proposals;
}


