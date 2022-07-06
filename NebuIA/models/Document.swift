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
    
    var front_image: UIImage?
    var back_image: UIImage?
    
    var document_side: Side = Side.FRONT
    
    var current_type: String?
    
    public func isComplete() -> Bool {
        if(current_type == "mx_passport_front") {
            return front_image != nil
        } else {
            return front_image != nil && back_image != nil
        }
    }
    
    public func setImage(crop: UIImage)  {
        if(document_side == Side.FRONT) {
            front_image = crop
        } else {
            back_image = crop
        }
    }
    
    public func reset() {
        document_side = Side.FRONT
        front_image = nil
        back_image = nil
    }
}
