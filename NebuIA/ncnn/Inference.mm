//
//  Inference.cpp
//  NebuIA
//
//  Created by Miguel Angel on 09/11/21.
//

#include "Inference.h"
#include "ncnn/ncnn/cpu.h"

struct GridAndStride
{
    int grid0;
    int grid1;
    int stride;
};

class YoloV5Focus : public ncnn::Layer
{
public:
    YoloV5Focus()
    {
        one_blob_only = true;
    }

    int forward(const ncnn::Mat& bottom_blob, ncnn::Mat& top_blob, const ncnn::Option& opt) const override
    {
        int w = bottom_blob.w;
        int h = bottom_blob.h;
        int channels = bottom_blob.c;

        int outw = w / 2;
        int outh = h / 2;
        int outc = channels * 4;

        top_blob.create(outw, outh, outc, 4u, 1, opt.blob_allocator);
        if (top_blob.empty())
            return -100;

#pragma omp parallel for num_threads(opt.num_threads)
        for (int p = 0; p < outc; p++)
        {
            const float* ptr = bottom_blob.channel(p % channels).row((p / channels) % 2) + ((p / channels) / 2);
            float* outptr = top_blob.channel(p);

            for (int i = 0; i < outh; i++)
            {
                for (int j = 0; j < outw; j++)
                {
                    *outptr = *ptr;

                    outptr += 1;
                    ptr += 2;
                }

                ptr += w;
            }
        }

        return 0;
    }
};

DEFINE_LAYER_CREATOR(YoloV5Focus)

static inline float intersection_area(const Object &a, const Object &b) {
    if (a.x > b.x + b.w || a.x + a.w < b.x || a.y > b.y + b.h || a.y + a.h < b.y) {
        // no intersection
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

static void generate_grids_and_stride(const int target_size, std::vector<int> &strides,
                                      std::vector<GridAndStride> &grid_strides) {
    for (auto stride : strides) {
        int num_grid = target_size / stride;
        for (int g1 = 0; g1 < num_grid; g1++) {
            for (int g0 = 0; g0 < num_grid; g0++) {
                grid_strides.push_back((GridAndStride) {g0, g1, stride});
            }
        }
    }
}

static void
generate_proposals(std::vector<GridAndStride> grid_strides, const ncnn::Mat &feat_blob,
                         float prob_threshold, std::vector<Object> &objects) {

    const int num_class = feat_blob.w - 5;

    const int num_anchors = grid_strides.size();

    const float *feat_ptr = feat_blob.channel(0);
    for (int anchor_idx = 0; anchor_idx < num_anchors; anchor_idx++) {
        const auto grid0 = grid_strides[anchor_idx].grid0;
        const auto grid1 = grid_strides[anchor_idx].grid1;
        const auto stride = grid_strides[anchor_idx].stride;

        float x_center = (feat_ptr[0] + grid0) * stride;
        float y_center = (feat_ptr[1] + grid1) * stride;
        float w = exp(feat_ptr[2]) * stride;
        float h = exp(feat_ptr[3]) * stride;
        float x0 = x_center - w * 0.5f;
        float y0 = y_center - h * 0.5f;

        float box_objectness = feat_ptr[4];
        for (int class_idx = 0; class_idx < num_class; class_idx++) {
            float box_cls_score = feat_ptr[5 + class_idx];
            float box_prob = box_objectness * box_cls_score;
            if (box_prob > prob_threshold) {
                Object obj{};
                obj.x = x0;
                obj.y = y0;
                obj.w = w;
                obj.h = h;
                obj.label = class_idx;
                obj.prob = box_prob;

                objects.push_back(obj);
            }

        } // class loop
        feat_ptr += feat_blob.w;

    } // point anchor loop
}

Inference::Inference(NSString *modelName) {
    Net = new ncnn::Net();

    ncnn::Option opt;
    opt.lightmode = true;
    opt.num_threads = 2;
    opt.blob_allocator = &blob_pool_allocator;
    opt.workspace_allocator = &workspace_pool_allocator;
    opt.use_packing_layout = true;

    Net->opt = opt;
    Net->register_custom_layer("YoloV5Focus", YoloV5Focus_layer_creator);

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
Inference::detect(UIImage *image) const {
    int width = image.size.width;
    int height = image.size.height;
    unsigned char* rgba = new unsigned char[width * height * 4];
    CGColorSpaceRef colorSpace = CGImageGetColorSpace(image.CGImage);
    CGContextRef contextRef = CGBitmapContextCreate(rgba, width, height, 8, width * 4, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrderDefault);
    CGContextDrawImage(contextRef, CGRectMake(0, 0, width, height), image.CGImage);
    CGContextRelease(contextRef);

    // parameters which might change for different model
    const float prob_threshold = 0.65f;
    const float nms_threshold = 0.7f;
    std::vector<int> strides = {8, 16, 32}; // might have stride=64

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

    // pad to target_size rectangle
    int wpad = target_size - w;
    int hpad = target_size - h;
    ncnn::Mat in_pad;

    ncnn::copy_make_border(in, in_pad, 0, hpad, 0, wpad, ncnn::BORDER_CONSTANT, 114.f);

    std::vector<Object> objects;
    {

        ncnn::Extractor ex = Net->create_extractor();

        ex.input("images", in_pad);

        std::vector<Object> proposals;

        {
            ncnn::Mat out;
            ex.extract("output", out);

            std::vector<GridAndStride> grid_strides;
            generate_grids_and_stride(target_size, strides, grid_strides);
            generate_proposals(grid_strides, out, prob_threshold, proposals);

        }

        // sort all proposals by score from highest to lowest
        qsort_descent_inplace(proposals);

        // apply nms with nms_threshold
        std::vector<int> picked;
        nms_sorted_bboxes(proposals, picked, nms_threshold);

        int count = picked.size();

        objects.resize(count);
        for (int i = 0; i < count; i++) {
            objects[i] = proposals[picked[i]];

            // adjust offset to original unpadded
            float x0 = (objects[i].x) / scale;
            float y0 = (objects[i].y) / scale;
            float x1 = (objects[i].x + objects[i].w) / scale;
            float y1 = (objects[i].y + objects[i].h) / scale;

            // clip
            x0 = std::max(std::min(x0, (float) (width - 1)), 0.f);
            y0 = std::max(std::min(y0, (float) (height - 1)), 0.f);
            x1 = std::max(std::min(x1, (float) (width - 1)), 0.f);
            y1 = std::max(std::min(y1, (float) (height - 1)), 0.f);

            objects[i].x = x0;
            objects[i].y = y0;
            objects[i].w = x1;
            objects[i].h = y1;
        }
    }

    delete[] rgba;
    return objects;
}

