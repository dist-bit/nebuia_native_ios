//
//  NebuIA.swift
//  NebuIA
//
//  Created by Miguel on 25/06/21.
//

public class NebuIA {
    
    private var client: Client!
    private var code: String!
    private var report: String!
    
    private var ctr: UIViewController!
    private var document: Document = Document()
    private var address: Address = Address()
    private var detector = DetectorWrapper()
    
    
    public init(controller: UIViewController) {
        let publickey = Bundle.main.object(forInfoDictionaryKey: "NebuIAPublicKey") as! String
        let secretKey = Bundle.main.object(forInfoDictionaryKey: "NebuIASecretKey") as! String
        ctr = controller;
        client = Client(publicKey: publickey, secretKey: secretKey)
    }
    
    public func setCode(code: String)  {
        client.code = code
    }
    
    public func setClientURI(uri: String)  {
        client.base = uri
    }
    
    public func setReport(report: String) {
        client.report = report
    }
    
    public func createReport(completion: ((String) -> Void)? = nil) {
        client.createReport() { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let report = dict["payload"] as? String
                completion!(report!)
            }
        }
    }
    
    public func saveEmail(email: String, completion: ((Bool) -> Void)? = nil) {
        client.saveEmail(email: email) { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    public func savePhone(phone: String, completion: ((Bool) -> Void)? = nil) {
        client.savePhone(phone: phone) { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    public func generateEmailOTP(completion: ((Bool) -> Void)? = nil) {
        client.sentEmailOTP() { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    public func generatePhoneOTP(completion: ((Bool) -> Void)? = nil) {
        client.sentPhoneOTP() { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    // verify
    public func verifyPhoneOTP(otp: String, completion: ((Bool) -> Void)? = nil) {
        client.validatePhoneOTP(otp: otp) { data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                let response = dict["status"] as! Bool
                completion!(response)
            }
        }
    }
    
    public func verifyEmailOTP(otp: String, completion: ((Bool) -> Void)? = nil) {
        client.validatePhoneOTP(otp: otp) { data, error in
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
        faceController.client = client
        faceController.onComplete = completion
        ctr.present(faceController, animated: true, completion: nil)
    }
    
    public func signerVideo(text: [String], completion: ((String) -> Void)? = nil) {
        let videoController = VideoController()
        videoController.detector = detector
        videoController.client = client
        videoController.onCompleteVideo = completion
        videoController.textToRead = text
        ctr.present(videoController, animated: true, completion: nil)
    }
    
    public func idScanner(completion: (() -> Void)? = nil, error: (() -> Void)? = nil) {
        let idController = IDScannerController()
        idController.detector = detector
        idController.client = client
        idController.document = document
        idController.onComplete = completion
        idController.onError = error
        ctr.present(idController, animated: true, completion: nil)
    }
    
    public func takeAddress(completion: ((Dictionary<String, Any>) -> Void)? = nil, error: (() -> Void)? = nil) {
        let addressController = AddressScannerController()
        addressController.client = client
        addressController.address = address
        addressController.onComplete = completion
        addressController.onError = error
        ctr.present(addressController, animated: true, completion: nil)
    }
    
    public func saveAddress(address: String, completion: ((NSDictionary) -> Void)? = nil, onError: ((String) -> Void)? = nil) {
        client.saveAddress(address: address) { data, error in
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
    
    public func fingerprintScanner(hand: Int, completion: ((Finger, Finger, Finger, Finger) -> Void)? = nil) {
        let fingerprintController = FingerprintScannerController()
        fingerprintController.detector = detector
        fingerprintController.client = client
        fingerprintController.onCompleteFingerprint = completion
        fingerprintController.position = hand
        ctr.present(fingerprintController, animated: true, completion: nil)
    }
    
    public func getDocumentIDSide(side: SIDE, completion: ((UIImage) -> Void)? = nil) {
        client.getIDImage(side: side) { image, error in
            if image != nil {
                completion!(image!)
            }
        }
    }
    
    public func getDocumentFace(completion: ((UIImage) -> Void)? = nil) {
        client.getFaceImage() { image, error in
            if image != nil {
                completion!(image!)
            }
        }
    }
    
    public func getReportIDSummary(completion: ((Dictionary<String, Any>) -> Void)? = nil) {
        client.getReportSummary{ data, error in
            if data != nil {
                let dict = data as! Dictionary<String, Any>
                completion!(dict)
            }
        }
    }
    
    public func getFingerprintWSQ(image: UIImage, completion: ((Data) -> Void)? = nil) {
        client.getFingerprintWSQ(image: image) { data, error in
            if data != nil {
                completion!(data!)
            }
        }
    }
    
}
