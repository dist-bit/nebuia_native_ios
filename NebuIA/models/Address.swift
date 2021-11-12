//
//  Address.swift
//  NebuIA
//
//  Created by Miguel Angel on 09/11/21.
//

import Foundation

public class Address {
    var image: UIImage?
    var pdf: URL?
   
    public func setPDF(data: URL) {
        pdf = data
        image = nil
    }
    
    public func setImage(data: UIImage) {
        image = data
        pdf = nil
    }
    
    public func reset() {
        image = nil
        pdf = nil
    }
  
}

