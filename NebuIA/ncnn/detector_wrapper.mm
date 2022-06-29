//
//  DetectorWrapper.m
//  NebuIA
//
//  Created by Miguel Angel on 28/07/21.
//

#import "detector_wrapper.h"

@interface DetectorWrapper()
@property Id *id;
@property Face *face;
//
@property Inference *IDInference;
@property Inference *FingerInference;
// utils
@property Quality *FingerQuality;
@end

//Inference *Id::inference = nullptr;

@implementation DetectorWrapper

- (instancetype)init {
    if (self = [super init]) {
        self.id = new Id();
        self.face = new Face();
        self.IDInference = new Inference(@"det0");
        self.FingerInference = new Inference(@"det3");
        self.FingerQuality = new Quality(@"det4");
    }
    return self;
}

- (NSArray<DetectionItem *> *)detectID:(UIImage *)image {

    NSMutableArray<DetectionItem *> *detections = [[NSMutableArray alloc] init];
    std::vector<Object> boxs;
    boxs = self.IDInference->detect(image, 3);
    for (int i = 0; i < boxs.size(); i++) {
        Object box = boxs[i];
        NSString *label = [NSString stringWithUTF8String:self.id->labels[box.label].c_str()];
        CGFloat score = (CGFloat)box.prob;
        CGFloat x1 = (CGFloat)box.x;
        CGFloat y1 = (CGFloat)box.y;
        CGFloat x2 = (CGFloat)box.w;
        CGFloat y2 = (CGFloat)box.h;
        DetectionItem * detection = [[DetectionItem alloc]initWithParams:label score:score x1:x1 y1:y1 x2:x2 y2:y2];
        [detections addObject:detection];
    }
    return detections;
}

- (NSArray<DetectionItem *> *)detectFingerprints:(UIImage *)image {

    NSMutableArray<DetectionItem *> *detections = [[NSMutableArray alloc] init];
    std::vector<Object> boxs;
    boxs = self.FingerInference->detect(image, 1);
    for (int i = 0; i < boxs.size(); i++) {
        Object box = boxs[i];
        NSString *label = [NSString stringWithUTF8String:"finger"];
        CGFloat score = (CGFloat)box.prob;
        CGFloat x1 = (CGFloat)box.x;
        CGFloat y1 = (CGFloat)box.y;
        CGFloat x2 = (CGFloat)box.w;
        CGFloat y2 = (CGFloat)box.h;
        DetectionItem * detection = [[DetectionItem alloc]initWithParams:label score:score x1:x1 y1:y1 x2:x2 y2:y2];
        [detections addObject:detection];
    }
    return detections;
}

- (NSArray<DetectionItem *> *)detectFace:(UIImage *)image {

    NSMutableArray<DetectionItem *> *detections = [[NSMutableArray alloc] init];
    std::vector<BoxInfo> boxs;
    boxs = self.face->detect(image);
    for (int i = 0; i < boxs.size(); i++) {
        BoxInfo box = boxs[i];
        NSString *label = [NSString stringWithUTF8String:"face"];
        CGFloat score = (CGFloat)box.score;
        CGFloat x1 = (CGFloat)box.x1;
        CGFloat y1 = (CGFloat)box.y1;
        CGFloat x2 = (CGFloat)box.x2;
        CGFloat y2 = (CGFloat)box.y2;
        DetectionItem * detection = [[DetectionItem alloc]initWithParams:label score:score x1:x1 y1:y1 x2:x2 y2:y2];
        [detections addObject:detection];
    }
    return detections;
}

- (float)qualityFingerprint:(UIImage *)image {
     float score = self.FingerQuality->quality(image);
     return score;
 }

@end



