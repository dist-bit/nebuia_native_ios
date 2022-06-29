//
//  Detection.h
//  NebuIA
//
//  Created by Miguel Angel on 28/07/21.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface DetectionItem : NSObject

@property (strong, nonatomic) NSString *label;
@property (assign, nonatomic) CGFloat score;
@property (assign, nonatomic) CGFloat x1;
@property (assign, nonatomic) CGFloat y1;
@property (assign, nonatomic) CGFloat x2;
@property (assign, nonatomic) CGFloat y2;

- (id) initWithParams:(NSString *)label_
                score:(CGFloat)score_
                   x1:(CGFloat)x1_
                   y1:(CGFloat)y1_
                   x2:(CGFloat)x2_
                   y2:(CGFloat)y2_;

- (CGRect) rect;
@end

NS_ASSUME_NONNULL_END
