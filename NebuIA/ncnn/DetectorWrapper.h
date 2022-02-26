//
//  DetectorWrapper.h
//  NebuIA
//
//  Created by Miguel Angel on 28/07/21.
//

#import <UIKit/UIKit.h>
#import "Detection.h"
#import "Id.h"
#import "Finger.h"
#import "Face.h"
#import "Inference.h"

NS_ASSUME_NONNULL_BEGIN

@interface DetectorWrapper : NSObject
- (NSArray<Detection *> *)detectID:(UIImage *)image;
- (NSArray<Detection *> *)detectFingerprints:(UIImage *)image;
- (NSArray<Detection *> *)detectFace:(UIImage *)image;
- (NSArray<Detection *> *)detectDocument:(UIImage *)image;
@end

NS_ASSUME_NONNULL_END
