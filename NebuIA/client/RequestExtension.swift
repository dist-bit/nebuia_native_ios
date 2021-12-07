//
//  RequestExtension.swift
//  NebuIA
//
//  Created by Miguel on 21/06/21.
//

extension URLRequest {
    mutating func file(apiKey: String, apiSecret: String, code: String, boundary: String) {
        self.httpMethod = "POST"
        self.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        self.setValue(
            apiKey,
            forHTTPHeaderField: "api_key"
        )
        self.setValue(
            apiSecret,
            forHTTPHeaderField: "api_secret"
        )
        self.setValue(
            code,
            forHTTPHeaderField: "time_key"
        )
    }
    
    mutating func get(apiKey: String, apiSecret: String, code: String) {
        self.httpMethod = "GET"
        self.addValue("application/json", forHTTPHeaderField: "Accept")
        self.setValue(
            apiKey,
            forHTTPHeaderField: "api_key"
        )
        self.setValue(
            apiSecret,
            forHTTPHeaderField: "api_secret"
        )
        self.setValue(
            code,
            forHTTPHeaderField: "time_key"
        )
    }
    
    mutating func put(apiKey: String, apiSecret: String, code: String) {
        self.httpMethod = "PUT"
        self.addValue("application/json", forHTTPHeaderField: "Content-Type")
        self.addValue("application/json", forHTTPHeaderField: "Accept")
        self.setValue(
            apiKey,
            forHTTPHeaderField: "api_key"
        )
        self.setValue(
            apiSecret,
            forHTTPHeaderField: "api_secret"
        )
        self.setValue(
            code,
            forHTTPHeaderField: "time_key"
        )
        
        
    }
    
    mutating func emptyPOST(apiKey: String, apiSecret: String, code: String) {
        self.httpMethod = "POST"
        self.setValue(
            apiKey,
            forHTTPHeaderField: "api_key"
        )
        self.setValue(
            apiSecret,
            forHTTPHeaderField: "api_secret"
        )
        self.setValue(
            code,
            forHTTPHeaderField: "time_key"
        )
    }
    
}

