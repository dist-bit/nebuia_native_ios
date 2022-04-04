//
//  NebuIA.swift
//  NebuIA
//
//  Created by Miguel on 25/06/21.
//


import UIKit
import AVFoundation
import Cartography
import CoreServices


@available(iOS 13.0, *)
public class NebuIA {
    
    static var client: Client!
    private var code: String!
    private var report: String!
    
    private var ctr: UIViewController!
    private var document: Document = Document()
    private var address: Address = Address()
    private var detector = DetectorWrapper()
    
    static var imagePicker: UIImagePickerController!
    
    public init(controller: UIViewController) {
        let publickey = Bundle.main.object(forInfoDictionaryKey: "NebuIAPublicKey") as! String
        let secretKey = Bundle.main.object(forInfoDictionaryKey: "NebuIASecretKey") as! String
        ctr = controller;
        NebuIA.client = Client(publicKey: publickey, secretKey: secretKey)
    }
    
    public func setCode(code: String)  {
        NebuIA.client.code = code
    }
    
    public func setClientURI(uri: String)  {
        NebuIA.client.base = uri
    }
    
    public func setReport(report: String) {
        NebuIA.client.report = report
    }
    
    public func createReport(completion: ((String) -> Void)? = nil) {
        NebuIA.client.createReport() { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let report = dict["payload"] as? String
                completion!(report!)
            }
        }
    }
    
    public func saveEmail(email: String, completion: ((Bool) -> Void)? = nil) {
        NebuIA.client.saveEmail(email: email) { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    public func savePhone(phone: String, completion: ((Bool) -> Void)? = nil) {
        NebuIA.client.savePhone(phone: phone) { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    public func generateEmailOTP(completion: ((Bool) -> Void)? = nil) {
        NebuIA.client.sentEmailOTP() { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    public func generatePhoneOTP(completion: ((Bool) -> Void)? = nil) {
        NebuIA.client.sentPhoneOTP() { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    // verify
    public func verifyPhoneOTP(otp: String, completion: ((Bool) -> Void)? = nil) {
        NebuIA.client.validatePhoneOTP(otp: otp) { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    public func verifyEmailOTP(otp: String, completion: ((Bool) -> Void)? = nil) {
        NebuIA.client.validatePhoneOTP(otp: otp) { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    public func faceProof(completion: (() -> Void)? = nil) {
        let faceController = FaceController()
        faceController.detector = detector
        faceController.onComplete = completion
        ctr.present(faceController, animated: true, completion: nil)
    }
    
    public func signerVideo(text: [String], completion: ((String) -> Void)? = nil) {
        let videoController = VideoController()
        videoController.detector = detector
        videoController.onCompleteVideo = completion
        videoController.textToRead = text
        ctr.present(videoController, animated: true, completion: nil)
    }
    
    public func idScanner(completion: (() -> Void)? = nil, error: (() -> Void)? = nil) {
        let idController = IDScannerController()
        idController.detector = detector
        idController.document = document
        idController.onComplete = completion
        idController.onError = error
        ctr.present(idController, animated: true, completion: nil)
    }
    
    
    static var completionAddress: ((Dictionary<String, Any>) -> Void)? = nil
    static var errorAddress: (() -> Void)? = nil
    public func takeAddress(completion: ((Dictionary<String, Any>) -> Void)? = nil, error: (() -> Void)? = nil) {
        
        NebuIA.completionAddress = completion
        NebuIA.errorAddress = error
        
        let optionMenu = UIAlertController(title: nil, message: "Selecciona una opción", preferredStyle: .actionSheet)
        let deleteAction = UIAlertAction(title: "Cargar PDF", style: .default, handler: { action in
            let picker = UIDocumentPickerViewController(documentTypes: [kUTTypePDF as String, kUTTypePNG as String, kUTTypeJPEG as String], in: .import)
            picker.delegate = self.ctr
            self.ctr.present(picker, animated: true, completion: nil)
        })
        let saveAction = UIAlertAction(title: "Capturar imagen desde cámara", style: .default, handler: { action in
            NebuIA.imagePicker =  UIImagePickerController()
            NebuIA.imagePicker.delegate = self.ctr
            NebuIA.imagePicker.sourceType = .camera
            self.ctr.present(NebuIA.imagePicker, animated: true, completion: nil)
            
        })
        
        let cancelAction = UIAlertAction(title: "Cancelar", style: .cancel)
        
        optionMenu.addAction(deleteAction)
        optionMenu.addAction(saveAction)
        optionMenu.addAction(cancelAction)
        ctr.present(optionMenu, animated: true, completion: nil)
    
    }

    
    public func saveAddress(address: String, completion: ((NSDictionary) -> Void)? = nil, onError: ((String) -> Void)? = nil) {
        NebuIA.client.saveAddress(address: address) { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["payload"]!
                if(response is NSDictionary) {
                    completion!(dict as NSDictionary)
                }
                else {
                    onError!(response as! String)
                }
            }
        }
    }
    
    public func fingerprintScanner(hand: Int, skipStep: Bool, qualityValue: Float, completion: ((Finger, Finger, Finger, Finger) -> Void)? = nil, skipWithFingers: ((Finger, Finger, Finger, Finger) -> Void)? = nil, skip: (() -> Void)? = nil) {
        let fingerprintController = FingerprintScannerController()
        fingerprintController.detector = detector
        fingerprintController.onSkipWithFingerprint = skipWithFingers
        fingerprintController.onCompleteFingerprint = completion
        fingerprintController.onSkip = skip
        fingerprintController.qualityValue = qualityValue
        fingerprintController.skipStep = skipStep
        fingerprintController.position = hand
        ctr.present(fingerprintController, animated: true, completion: nil)
    }
    
    public func getDocumentIDSide(side: SIDE, completion: ((UIImage) -> Void)? = nil) {
        NebuIA.client.getIDImage(side: side) { image, error in
            if image != nil {
                completion!(image!)
            }
        }
    }
    
    public func getDocumentFace(completion: ((UIImage) -> Void)? = nil) {
        NebuIA.client.getFaceImage() { image, error in
            if image != nil {
                completion!(image!)
            }
        }
    }
    
    public func getReportIDSummary(completion: ((Dictionary<String, Any>) -> Void)? = nil) {
        NebuIA.client.getReportSummary{ data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                completion!(dict)
            }
        }
    }
    
    public func getFingerprintWSQ(image: UIImage, completion: ((Data) -> Void)? = nil) {
        NebuIA.client.getFingerprintWSQ(image: image) { data, error in
            if data != nil {
                completion!(data!)
            }
        }
    }
    
}
