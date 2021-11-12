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
    
    public func faceProof(completion: (() -> Void)? = nil) {
        let faceController = FaceController()
        faceController.detector = detector
        faceController.client = client
        faceController.onComplete = completion
        ctr.present(faceController, animated: true, completion: nil)
    }
    
    public func signerVideo(completion: ((UIImage) -> Void)? = nil) {
        let signerController = SignerController()
        signerController.detector = detector
        signerController.client = client
        signerController.onCompleteSign = completion
        ctr.present(signerController, animated: true, completion: nil)
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
    
    public func fingerprintScanner(completion: ((UIImage, UIImage, UIImage, UIImage) -> Void)? = nil) {
        let fingerprintController = FingerprintScannerController()
        fingerprintController.detector = detector
        fingerprintController.client = client
        fingerprintController.onCompleteFingerprint = completion
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
