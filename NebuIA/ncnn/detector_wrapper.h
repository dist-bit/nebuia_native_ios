//
//  DetectorWrapper.h
//  NebuIA
//
//  Created by Miguel Angel on 28/07/21.
//

#import <UIKit/UIKit.h>
#import "DetectionItem.h"
#import "id.h"
#import "face.h"
#import "inference.h"
#import "quality.h"


NS_ASSUME_NONNULL_BEGIN

@interface DetectorWrapper : NSObject
- (NSArray<DetectionItem *> *)detectID:(UIImage *)image;
- (NSArray<DetectionItem *> *)detectFingerprints:(UIImage *)image;
- (NSArray<DetectionItem *> *)detectFace:(UIImage *)image;
// utils
- (float)qualityFingerprint:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
