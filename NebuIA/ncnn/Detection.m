//
//  Detection.m
//  NebuIA
//
//  Created by Miguel Angel on 28/07/21.
//

#import "Detection.h"

@implementation Detection

-(id)initWithParams:(NSString *)label_
              score:(CGFloat)score_
                 x1:(CGFloat)x1_
                 y1:(CGFloat)y1_
                 x2:(CGFloat)x2_
                 y2:(CGFloat)y2_
{
     self = [super init];
     if (self) {
         self.score = score_;
         self.label = label_;
         self.x1 = x1_;
         self.y1 = y1_;
         self.x2 = x2_;
         self.y2 = y2_;
     }
     return self;
}

- (CGRect)rect {
    return CGRectMake(self.x1, self.y1, self.x2 - self.x1, self.y2 - self.y1);
}

@end


