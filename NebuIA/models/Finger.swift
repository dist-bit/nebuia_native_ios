//
//  Finger.swift
//  NebuIA
//
//  Created by Miguel on 28/06/21.
//

import Foundation

public class Finger {
    public var image: UIImage?
    public var name: String?
    public var score: Int?
    init(image: UIImage, name: String, score: Int) {
        self.image = image
        self.name = name
        self.score = score
    }
}

