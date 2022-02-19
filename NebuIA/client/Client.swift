//
//  Client.swift
//  NebuIA
//
//  Created by Miguel on 21/06/21.
//

import UIKit
import SDWebImageWebPCoder

public class Client {
    //private var base: String = "https://api.nebuia.com/api/v1/services/"
    private var boundary = String(format: "----iOSURLSessionBoundary.%08x%08x", arc4random(), arc4random())
    
    var apiKey: String;
    var apiSecret: String;
    var code: String = "";
    var report: String = "";
    var base: String = "https://api.nebuia.com/api/v1/services/"
    
    init(publicKey: String, secretKey: String) {
        self.apiKey = publicKey
        self.apiSecret = secretKey
    }
    
    func setCode(passcode: String) {
        self.code = passcode
    }
    
    func createReport(completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)report")!
        var request = URLRequest(url: url)
        request.emptyPOST(apiKey: apiKey, apiSecret: apiSecret, code: code)
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func faceScanner(image: UIImage, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)face?report=\(report)")!
        var request = URLRequest(url: url)
        
        guard let imageData = SDImageWebPCoder.shared.encodedData(with: image, format: .webP, options: nil) else {
            return
        }
        
        var body = Data()
        body.imageBody(image: imageData, boundary: boundary, filename: "face")
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.file(apiKey: apiKey, apiSecret: apiSecret, code: code, boundary: boundary)
        let session = URLSession(configuration: .default)
        let task = session.uploadTask(with: request,from: body) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func getIDImage(side: SIDE, completion: @escaping (_ data: UIImage?, _ error: Error?)->()) {
        let url = URL(string: "\(base)docs/\(String(describing: side))?report=\(report)")!
        var request = URLRequest(url: url)
        request.get(apiKey: apiKey, apiSecret: apiSecret, code: code)
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let image = UIImage(data: data)
            completion(image, error)
        }
        task.resume()
    }
    
    func uploadID(front: UIImage, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)crop?report=\(report)")!
        var request = URLRequest(url: url)
        
        guard let imageData =  SDImageWebPCoder.shared.encodedData(with: front, format: .webP, options: nil) else {
            return
        }
        
        var body = Data()
        body.imageBody(image: imageData, boundary: boundary, filename: "front")
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.file(apiKey: apiKey, apiSecret: apiSecret, code: code, boundary: boundary)
        let session = URLSession(configuration: .default)
        
        let task = session.uploadTask(with: request,from: body) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func uploadID(front: UIImage, back: UIImage, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)id?report=\(report)")!
        var request = URLRequest(url: url)
        
        guard let frontData = SDImageWebPCoder.shared.encodedData(with: front, format: .webP, options: nil) else {
            return
        }
        
        guard let backData = SDImageWebPCoder.shared.encodedData(with: back, format: .webP, options: nil) else {
            return
        }
        
        var body = Data()
        // put images
        body.imageBody(image: frontData, boundary: boundary, filename: "front")
        body.imageBody(image: backData, boundary: boundary, filename: "back")
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.file(apiKey: apiKey, apiSecret: apiSecret, code: code, boundary: boundary)
        let session = URLSession(configuration: .default)
        
        let task = session.uploadTask(with: request,from: body) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func uploadAddressImage(image: UIImage, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)address?report=\(report)")!
        var request = URLRequest(url: url)
        guard let imageData = SDImageWebPCoder.shared.encodedData(with: image, format: .webP, options: nil) else {
            return
        }
        
        var body = Data()
        body.imageBody(image: imageData, boundary: boundary, filename: "document")
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.file(apiKey: apiKey, apiSecret: apiSecret, code: code, boundary: boundary)
        let session = URLSession(configuration: .default)
        
        let task = session.uploadTask(with: request,from: body) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func uploadAddressPDF(pdf: Data, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)address?report=\(report)")!
        var request = URLRequest(url: url)
        
        var body = Data()
        body.fileBody(image: pdf, boundary: boundary, filename: "document")
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.file(apiKey: apiKey, apiSecret: apiSecret, code: code, boundary: boundary)
        let session = URLSession(configuration: .default)
        
        let task = session.uploadTask(with: request,from: body) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func saveAddress(address: String, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)address?report=\(report)")!
        var request = URLRequest(url: url)
        request.put(apiKey: apiKey, apiSecret: apiSecret, code: code)
        
        let json: [String: Any] = ["address": [address]]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func fingerprints(image: UIImage, position: Int, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)fingerprints?report=\(report)")!
        var request = URLRequest(url: url)
        guard let imageData = SDImageWebPCoder.shared.encodedData(with: image, format: .webP, options: nil) else {
            return
        }
        
        var body = Data()
        body.valueBody(key: "hand", value: String(position), boundary: boundary)
        body.imageBody(image: imageData, boundary: boundary, filename: "image")
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.file(apiKey: apiKey, apiSecret: apiSecret, code: code, boundary: boundary)
        let session = URLSession(configuration: .default)
        let task = session.uploadTask(with: request,from: body) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func fingerprintNfiq(image: UIImage, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)nfiq?report=\(report)")!
        var request = URLRequest(url: url)
        guard let imageData = SDImageWebPCoder.shared.encodedData(with: image, format: .webP, options: nil) else {
            return
        }
        
        var body = Data()
        body.imageBody(image: imageData, boundary: boundary, filename: "front")
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.file(apiKey: apiKey, apiSecret: apiSecret, code: code, boundary: boundary)
        let session = URLSession(configuration: .default)
        let task = session.uploadTask(with: request,from: body) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func getFaceImage(completion: @escaping (_ data: UIImage?, _ error: Error?)->()) {
        let url = URL(string: "\(base)faces/?report=\(report)")!
        var request = URLRequest(url: url)
        request.get(apiKey: apiKey, apiSecret: apiSecret, code: code)
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let image = UIImage(data: data)
            completion(image, error)
        }
        task.resume()
    }
    
    func getReportSummary(completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)report/?report=\(report)")!
        var request = URLRequest(url: url)
        request.get(apiKey: apiKey, apiSecret: apiSecret, code: code)
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func getFingerprintWSQ(image: UIImage, completion: @escaping (_ data: Data?, _ error: Error?)->()) {
        let url = URL(string: "\(base)wsq?report=\(report)")!
        var request = URLRequest(url: url)
        guard let imageData = SDImageWebPCoder.shared.encodedData(with: image, format: .webP, options: nil) else {
            return
        }
        
        var body = Data()
        body.imageBody(image: imageData, boundary: boundary, filename: "front")
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        
        request.file(apiKey: apiKey, apiSecret: apiSecret, code: code, boundary: boundary)
        let session = URLSession(configuration: .default)
        let task = session.uploadTask(with: request,from: body) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }

            completion(data, error)
        }
        task.resume()
    }
    
    func saveEmail(email: String, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)email?report=\(report)")!
        var request = URLRequest(url: url)
        request.put(apiKey: apiKey, apiSecret: apiSecret, code: code)
        
        let json: [String: String] = ["email": email]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func savePhone(phone: String, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)phone?report=\(report)")!
        var request = URLRequest(url: url)
        request.put(apiKey: apiKey, apiSecret: apiSecret, code: code)
        
        let json: [String: String] = ["phone": phone]
        let jsonData = try? JSONSerialization.data(withJSONObject: json)
        request.httpBody = jsonData
        
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func sentEmailOTP(completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)otp/generate/email?report=\(report)")!
        var request = URLRequest(url: url)
        request.get(apiKey: apiKey, apiSecret: apiSecret, code: code)
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func sentPhoneOTP(completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)otp/generate/phone?report=\(report)")!
        var request = URLRequest(url: url)
        request.get(apiKey: apiKey, apiSecret: apiSecret, code: code)
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func validateEmailOTP(otp: String, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)otp/validate/email/\(otp)?report=\(report)")!
        var request = URLRequest(url: url)
        request.get(apiKey: apiKey, apiSecret: apiSecret, code: code)
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
    
    func validatePhoneOTP(otp: String, completion: @escaping (_ data: Any?, _ error: Error?)->()) {
        let url = URL(string: "\(base)otp/validate/phone/\(otp)?report=\(report)")!
        var request = URLRequest(url: url)
        request.get(apiKey: apiKey, apiSecret: apiSecret, code: code)
        let session = URLSession(configuration: .default)
        
        let task = session.dataTask(with: request) { data, response, error in
            guard let data = data,
                  error == nil else {
                completion(nil, error)
                return
            }
            let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            completion(json, error)
        }
        task.resume()
    }
}
