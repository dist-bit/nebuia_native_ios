//
//  FingerprintScannerController.swift
//  NebuIA
//
//  Created by Miguel on 28/06/21.
//

import UIKit
import AVFoundation
import Cartography

public class FingerprintScannerController: UIViewController,  AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCaptureVideoDataOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var client: Client!
    var detector: DetectorWrapper!
    var position: Int!
    
    private var detecting: Bool = true
    private var complete: Bool = false
    
    private var content_view_preview: UIView!
    private var content_view: UIView!
    
    private var overlay_rectangle: UIView!
    private var rects: UIImage!
    private var detections_view: UIImageView!
    
    private var back_button: UIButton!
    private var title_label: UILabel!
    private var summary_label: UILabel!
    private var action_label: UILabel!
    
    private var loading_indicator: UIActivityIndicatorView!
    
    private var nebuia_logo: UIImageView!
    private var success_icon: UIImageView!
    
    private var device: AVCaptureDevice!
    
    private var detections_count: [Int] = []
    
    var onCompleteFingerprint : ((Finger, Finger, Finger, Finger) -> Void)?
    
    @IBAction func goBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func buildBackbutton() {
        back_button = UIButton(type: .system)
        
        back_button.frame = CGRect(x: 100, y: 100, width: 45, height: 45)
        
        back_button.layer.cornerRadius =  back_button.frame.size.width/2
        back_button.clipsToBounds = true
        back_button.contentMode = UIView.ContentMode.scaleToFill
        
        back_button.backgroundColor =  UIColor(rgb: 0xffffff).withAlphaComponent(0.3)
        back_button.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let btnImage = UIImage(systemName: "chevron.backward")
            back_button.setImage(btnImage , for: .normal)
            back_button.tintColor = UIColor.white
        }
        back_button.addTarget(self, action: #selector(goBack(_:)), for: .touchUpInside)
    }
    
    private func buildTitleLabel() {
        title_label = UILabel(frame: UIScreen.main.bounds)
        title_label.textAlignment = .center
        title_label.numberOfLines = 1
        title_label.textColor = .black
        title_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 16), weight: .bold)
        title_label.minimumScaleFactor = 10/UIFont.labelFontSize
        title_label.adjustsFontSizeToFitWidth = true
        title_label.text = "Huella dactilar"
    }
    
    private func buildActionLabel() {
        action_label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        action_label.textAlignment = .center
        action_label.numberOfLines = 1
        action_label.textColor = UIColor(rgb: 0x009ad7)
        action_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 11), weight: .regular)
        action_label.minimumScaleFactor = 10/UIFont.labelFontSize
        action_label.adjustsFontSizeToFitWidth = true
        action_label.text = "Esperando huella dactilar"
    }
    
    private func buildSummaryLabel() {
        summary_label = UILabel(frame: UIScreen.main.bounds)
        summary_label.textAlignment = .center
        summary_label.numberOfLines = 3
        summary_label.minimumScaleFactor = 10/UIFont.labelFontSize
        summary_label.adjustsFontSizeToFitWidth = true
        summary_label.textColor = UIColor(rgb: 0x7d82a8)
        summary_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 12), weight: .regular)
        summary_label.text = "Coloca tu mano sobre la cámara enfocando tus 4 dedos de tu mano hasta resaltar tus huellas dactilares lo más cerca posible"
    }
    
    private func buildLogoBottom() {
        let logo = UIImage(named: "nebuia_black.png")
        nebuia_logo = UIImageView(image: logo!)
    }
    
    private func buildSuccessIcon() {
        if #available(iOS 13.0, *) {
            let check = UIImage(systemName: "checkmark.circle.fill")
            success_icon = UIImageView(image: check!)
            success_icon.tintColor = UIColor(rgb: 0x16a085)
            self.success_icon.isHidden = true
        }
    }
    
    private func buildLoadingindicator() {
        loading_indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        loading_indicator.color = .black
        loading_indicator.startAnimating()
    }
    
    private func hideLoadingShowSuccess() {
        UIView.transition(with: loading_indicator, duration: 0.4, options: .transitionCrossDissolve, animations: {() -> Void in
            self.loading_indicator.isHidden = true
            self.success_icon.isHidden = false
        }, completion: { _ in })
    }
    
    
    
    private func initializeOverlay() {
        overlay_rectangle = UIView(frame: UIScreen.main.bounds)
        detections_view = UIImageView(frame: UIScreen.main.bounds)
    }
    
    func constraintsInit() {
        let botom: CGFloat = UIDevice.current.hasNotch ? 50 : 0
        constrain(back_button!, title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, success_icon, detections_view, content_view_preview)
        { back_button, title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, success_icon, detections_view, content_view_preview in
            back_button.width == 45
            back_button.height == 45
            back_button.left == content_view.superview!.left + 25
            back_button.top == content_view.superview!.top + 20
            
            action_label.left == back_button.left
            action_label.centerX == content_view.centerX
            loading_indicator.centerX == content_view.centerX
            success_icon.centerX == content_view.centerX
            success_icon.top == action_label.bottom + 15
            
            nebuia_logo.centerX == content_view.centerX
            nebuia_logo.width == content_view.superview!.width / 3.6
            nebuia_logo.height == 20
            nebuia_logo.centerY == content_view.superview!.bottom - botom - 50
            
            title_label.centerX == content_view.centerX
            title_label.top == content_view.superview!.top + 40
            
            content_view_preview.centerX == content_view.centerX
            content_view_preview.top == content_view.superview!.top + 80
            content_view_preview.width == 320
            content_view_preview.height == 470
            
            detections_view.centerX == content_view.centerX
            detections_view.top == content_view_preview.top
            detections_view.width == content_view_preview.width
            detections_view.height == content_view_preview.height
            
            summary_label.top == action_label.top - 75
            summary_label.width == content_view.superview!.width / 1.2
            summary_label.centerX == content_view.centerX
            
            distribute(by: 20, vertically: action_label, loading_indicator, nebuia_logo)
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.detecting = false
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.toggleTorch(on: true)
        }
        
        // camara
        content_view_preview = UIView(frame: UIScreen.main.bounds)
        content_view_preview.layer.cornerRadius = 20
        content_view_preview.clipsToBounds = true
        content_view_preview.layer.cornerRadius = 20
        content_view = UIView(frame: UIScreen.main.bounds)
        
        // set up back button
        buildBackbutton()
        content_view.addSubview(back_button)
        
        // set up title layer
        buildTitleLabel()
        content_view.addSubview(title_label)
        
        // set up action label
        buildActionLabel()
        content_view.addSubview(action_label)
        
        // set up summary
        buildSummaryLabel()
        content_view.addSubview(summary_label)
        
        // set up logo
        buildLogoBottom()
        content_view.addSubview(nebuia_logo)
        
        // set loading indicator
        buildLoadingindicator()
        content_view.addSubview(loading_indicator)
        
        // set up success icon
        buildSuccessIcon()
        content_view.addSubview(success_icon)
        
        // init overlay camera
        initializeOverlay()
        
        let root_view = UIView(frame: UIScreen.main.bounds)
        root_view.addSubview(content_view_preview)
        root_view.addSubview(detections_view)
        root_view.addSubview(content_view)
        
        self.view.addSubview(root_view)
        constraintsInit()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        guard let camera = AVCaptureDevice.default(
                .builtInWideAngleCamera,
                for: AVMediaType.video,
                position: .back)
        else {
            print("Unable to access back camera!")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            self.device = camera
            
            try camera.lockForConfiguration()
            camera.isSubjectAreaChangeMonitoringEnabled = true
            camera.focusMode = AVCaptureDevice.FocusMode.continuousAutoFocus
            camera.exposureMode = AVCaptureDevice.ExposureMode.continuousAutoExposure
            camera.unlockForConfiguration()
            
            stillImageOutput = AVCaptureVideoDataOutput()
            stillImageOutput.videoSettings = [ kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA) ]
            
            let queue: DispatchQueue = DispatchQueue(label: "videocapturequeue", attributes: [])
            stillImageOutput.setSampleBufferDelegate(self, queue: queue)
            stillImageOutput.alwaysDiscardsLateVideoFrames = true
            
            if captureSession.canAddInput(input) && captureSession.canAddOutput(stillImageOutput) {
                captureSession.addInput(input)
                captureSession.addOutput(stillImageOutput)
                setupLivePreview()
            }
        }
        catch let error  {
            print("Error Unable to initialize back camera:  \(error.localizedDescription)")
        }
    }
    
    func setupLivePreview() {
        videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        videoPreviewLayer.videoGravity = .resizeAspectFill
        videoPreviewLayer.connection?.videoOrientation = .portrait
        videoPreviewLayer.frame = content_view_preview.bounds
        content_view_preview.layer.addSublayer(self.videoPreviewLayer)
        DispatchQueue.global(qos: .userInitiated).async {
            self.captureSession.startRunning()
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.toggleTorch(on: false)
        self.captureSession.stopRunning()
    }
    
    
    public override var shouldAutorotate : Bool {
        return false
    }
    
    private func decodePayloadOnCrop(data: Any) -> (UIImage?, String?) {
        if let result = data as? Dictionary<String, AnyObject> {
            let payload = result["payload"] as? Dictionary<String, AnyObject>
            if(payload != nil) {
                if let val = payload!["image"] {
                    let image = val as? String
                    let data = Data(base64Encoded: image!)
                    let type = payload!["type"] as? String
                    return (UIImage(data: data!), type)
                }
            }
        }
        return (nil, nil)
    }
    
    private func onPreviewDissmis() {
        if(!complete) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                self.toggleTorch(on: true)
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.detecting = false
            }
        }
    }
    
    private func onCompleteUpload(index: Finger, middle: Finger, ring: Finger, little: Finger) {
        self.complete = true
        self.onCompleteFingerprint!(index, middle, ring, little)
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.back()
        }
    }
    
    private func back() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if(!self.detecting) {
            self.detecting = true
            
            let image = sampleBuffer.toUIImage()
            let detections = detector.detectFingerprints(image)
            
            
            var rects = [CGRect]()
            
            if(detections.count >= 4) {
                
                rects.append(detections[0].rect())
                rects.append(detections[1].rect())
                rects.append(detections[2].rect())
                rects.append(detections[3].rect())
                
                
                if(rects.count == 4) {
                    detections_count.append(rects.count)
                } else {
                    rects.removeAll()
                    detections_count.removeAll()
                }
                
                if(detections_count.count >= 55) {
                    Vibration.success.vibrate()
                    detections_count.removeAll()
                    rects.removeAll()
                    
                    // show loading modal
                    DispatchQueue.main.async {
                        self.showSpinner(onView: self.view)
                    }
                    
                    // get image
                    client.fingerprints(image: image, position: position, completion: { data, error in
                        if error == nil {
                            let dict = data as! Dictionary<String, Any>
                            
                            if dict["status"] as! Bool {
                                let payload = dict["payload"] as! Dictionary<String, Any>
                                let result =  payload["fingers"] as! Array<Dictionary<String, Any>>
                                var fingers = [Finger]()
                                for item in result {
                                    fingers.append(
                                        Finger(
                                            image: self.getImageFromBase64(b64: item["image"] as! String),
                                            name: item["name"]! as! String,
                                            score: item["nfiq"]! as! Int
                                        )
                                    )
                                }
                                
                                DispatchQueue.main.async {
                                    self.removeSpinner()
                                    self.previewResult(fingers: fingers)
                                }
                            } else {
                                DispatchQueue.main.async {
                                    self.removeSpinner()
                                    self.detecting = false
                                }
                            }
                        } else {
                            DispatchQueue.main.async {
                                self.removeSpinner()
                                self.detecting = false
                            }
                        }
                    })
                } else {
                    self.detecting = false
                }
            } else {
                self.detecting = false
            }
            
            DispatchQueue.main.async {
                self.detections_view.image = self.drawOccurrencesOnImage(rects, UIImage.emptyImage(with: image.size)!)
            }
        }
    }
    
    private func getImageFromBase64(b64: String) -> UIImage {
        let dataDecoded : Data = Data(base64Encoded: b64, options: .ignoreUnknownCharacters)!
        return UIImage(data: dataDecoded)!
    }
    
    private func drawOccurrencesOnImage(_ occurrences: [CGRect], _ image: UIImage) -> UIImage? {
        let imageSize = image.size
        UIGraphicsBeginImageContext(imageSize)
        
        image.draw(at: CGPoint.zero)
        let ctx = UIGraphicsGetCurrentContext()
        
        for rect in occurrences {
            let clipPath = UIBezierPath(roundedRect: rect, cornerRadius: 30.0).cgPath
            ctx?.addPath(clipPath)
            ctx?.setFillColor(UIColor(rgb: 0x00FFFF, alpha: 0.3).cgColor)
            ctx?.closePath()
            ctx?.fillPath()
        }
        
        
        guard let drawnImage = UIGraphicsGetImageFromCurrentImageContext() else {
            print( "There was an issue, please try again")
            return nil
        }
        
        UIGraphicsEndImageContext()
        return drawnImage
    }
    
    private func previewResult(fingers: [Finger]) {
        toggleTorch(on: false)
        let preview: FingerprintPreviewController = FingerprintPreviewController()
        preview.onCompleteBlock = self.onCompleteUpload
        preview.onDismmisBlock = self.onPreviewDissmis
        preview.fingers =  fingers
        preview.client = self.client
        self.present(preview, animated: true, completion: nil)
    }
    
    func toggleTorch(on: Bool) {
        if device.hasTorch {
            do {
                try device.lockForConfiguration()
                if on == true {
                    device.torchMode = .on
                } else {
                    device.torchMode = .off
                }
                device.unlockForConfiguration()
            } catch {
                print("Torch could not be used")
            }
        } else {
            print("Torch is not available")
        }
    }
    
    private func convertBase64StringToImage (b64:String) -> UIImage {
        let imageData = Data.init(base64Encoded: b64, options: .init(rawValue: 0))
        let image = UIImage(data: imageData!)
        return image!
    }
    
}

