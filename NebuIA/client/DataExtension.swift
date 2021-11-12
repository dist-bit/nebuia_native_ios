//
//  DataExtension.swift
//  NebuIA
//
//  Created by Miguel on 21/06/21.
//

extension Data {
    mutating func imageBody(image: Data,  boundary: String, filename: String) {
        self.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        self.append("Content-Disposition: form-data; name=\(filename); filename=\(filename).jpeg\r\n".data(using: .utf8)!)
        self.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        self.append(image)
        //self.httpBody = body
    }
    
    mutating func fileBody(image: Data,  boundary: String, filename: String) {
        self.append("\r\n--\(boundary)\r\n".data(using: .utf8)!)
        self.append("Content-Disposition: form-data; name=\(filename); filename=\(filename).pdf\r\n".data(using: .utf8)!)
        self.append("Content-Type: application/pdf\r\n\r\n".data(using: .utf8)!)
        self.append(image)
        //self.httpBody = body
    }
}
