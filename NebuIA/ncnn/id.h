//
//  id.h
//  NebuIA
//
//  Created by Miguel Angel on 27/07/21.
//

#ifndef id_hpp
#define id_hpp
#if defined __cplusplus

#include "inference.h"

namespace yolocv {
    typedef struct {
        int width;
        int height;
    }YoloSize;
}

struct face_landmark
{
    float x[5];
    float y[5];
};

typedef struct BoxInfo {
    float x1;
    float y1;
    float x2;
    float y2;
    float score;
    int label;
    float area;
    face_landmark landmark;
    float regreCoord[4];
}BoxInfo;

class Id {
public:
    std::vector<std::string> labels{
                "mx_id_back", "mx_id_front", "mx_passport_front"};
};


#endif /* id_hpp */
#endif
