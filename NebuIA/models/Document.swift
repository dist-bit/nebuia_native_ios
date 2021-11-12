//
//  model.swift
//  NebuIA
//
//  Created by Miguel on 27/06/21.
//

import Foundation

enum Side {
    case FRONT
    case BACK
}

public class Document {
    var front_crop_image: UIImage?
    var back_crop_image: UIImage?
    
    var front_image: UIImage?
    var back_image: UIImage?
    
    var document_side: Side = Side.FRONT
    
    var current_type: String?
    
    public func isComplete() -> Bool {
        if(current_type == "mx_passport_front") {
            return front_crop_image != nil
        } else {
            return front_crop_image != nil && back_crop_image != nil
        }
    }
    
    public func setImage(crop: UIImage, original: UIImage)  {
        if(document_side == Side.FRONT) {
            front_crop_image = crop
            front_image = original
        } else {
            back_crop_image = crop
            back_image = original
        }
    }
    
    public func reset() {
        document_side = Side.FRONT
        front_crop_image = nil
        front_image = nil
        back_crop_image = nil
        back_image = nil
    }
}
