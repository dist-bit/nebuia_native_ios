//
//  Finger.swift
//  NebuIA
//
//  Created by Miguel on 28/06/21.
//

import Foundation

public class Finger {
    var image: UIImage?
    var name: String?
    var nfiq: Int?
    init(image: UIImage, name: String, nfiq: Int) {
        self.image = image
        self.name = name
        self.nfiq = nfiq
    }
}

