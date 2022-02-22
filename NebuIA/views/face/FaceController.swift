//
//  FaceController.swift
//  NebuIA
//
//  Created by Miguel on 20/06/21.
//

import UIKit
import AVFoundation
import Cartography

import UIKit
import AVKit
import AVFoundation
import Cartography

public class FaceController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCaptureVideoDataOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var client: Client!
    var detector: DetectorWrapper!
    
    private var detecting: Bool = false
    private var complete: Bool = false
    
    private var faceCount: Int = 0
    private var faceComplete: Bool = false
    
    private var frontCount: Int = 0
    private var scanFront: Bool = false
    private var scanFrontComplete: Bool = false
    
    private var backCount: Int = 0
    private var scanBack: Bool = false
    private var scanBackComplete: Bool = false
    
    private var content_view_preview: UIView!
    private var content_view: UIView!
    
    private var title_label: UILabel!
    private var summary_label: UILabel!
    private var action_label: UILabel!
    
    private var loading_indicator: UIActivityIndicatorView!
    
    private var nebuia_logo: UIImageView!
    
    private var device: AVCaptureDevice!
    
    
    var onComplete: (() -> Void)?
    
    private func buildTitleLabel() {
        title_label = UILabel(frame: UIScreen.main.bounds)
        title_label.textAlignment = .center
        title_label.numberOfLines = 1
        title_label.textColor = .black
        title_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 16), weight: .bold)
        title_label.minimumScaleFactor = 10/UIFont.labelFontSize
        title_label.adjustsFontSizeToFitWidth = true
        title_label.text = "Prueba de vida"
    }
    
    private func buildActionLabel() {
        action_label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        action_label.textAlignment = .center
        action_label.numberOfLines = 1
        action_label.textColor = UIColor(rgb: 0x009ad7)
        action_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 11), weight: .regular)
        action_label.minimumScaleFactor = 10/UIFont.labelFontSize
        action_label.adjustsFontSizeToFitWidth = true
        action_label.text = "Esperando rostro"
    }
    
    private func buildSummaryLabel() {
        summary_label = UILabel(frame: UIScreen.main.bounds)
        summary_label.textAlignment = .center
        summary_label.numberOfLines = 3
        summary_label.minimumScaleFactor = 10/UIFont.labelFontSize
        summary_label.adjustsFontSizeToFitWidth = true
        summary_label.textColor = UIColor(rgb: 0x7d82a8)
        summary_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 12), weight: .regular)
        summary_label.text = "Por favor, coloca tu rostro en el recuadro y sigue las instrucciones de parte inferior"
    }
    
    private func buildLogoBottom() {
        let logo = UIImage(named: "nebuia_black.png")
        nebuia_logo = UIImageView(image: logo!)
    }
    
    
    private func buildLoadingindicator() {
        loading_indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        loading_indicator.color = .black
        loading_indicator.startAnimating()
    }
    
    private func hideLoadingShowSuccess() {
        UIView.transition(with: loading_indicator, duration: 0.4, options: .transitionCrossDissolve, animations: {() -> Void in
            self.loading_indicator.isHidden = true
        }, completion: { _ in })
    }
    
    func constraintsInit() {
        let botom: CGFloat = UIDevice.current.hasNotch ? 50 : 0
        constrain(title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, content_view_preview)
        { title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, content_view_preview in
            
            action_label.centerX == content_view.centerX
            loading_indicator.centerX == content_view.centerX
            
            nebuia_logo.centerX == content_view.centerX
            nebuia_logo.width == content_view.superview!.width / 3.6
            nebuia_logo.height == 20
            nebuia_logo.centerY == content_view.superview!.bottom - botom - 50
            
            title_label.centerX == content_view.centerX
            title_label.top == content_view.superview!.top + 40
            
            content_view_preview.centerX == content_view.centerX
            content_view_preview.top == content_view.superview!.top + 80
            content_view_preview.width == 322
            content_view_preview.height == 365
            
            
            summary_label.top == content_view_preview.bottom + 15
            summary_label.width == content_view.superview!.width / 1.2
            summary_label.centerX == content_view.centerX
            
            distribute(by: 20, vertically: action_label, loading_indicator, nebuia_logo)
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // camara
        content_view_preview = UIView(frame: UIScreen.main.bounds)
        content_view_preview.layer.cornerRadius = 20
        content_view_preview.clipsToBounds = true
        content_view_preview.layer.cornerRadius = 20
        content_view = UIView(frame: UIScreen.main.bounds)
        
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
        
        let root_view = UIView(frame: UIScreen.main.bounds)
        root_view.addSubview(content_view_preview)
        root_view.addSubview(content_view)
        
        self.view.addSubview(root_view)
        constraintsInit()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .medium
        
        
        guard let frontCamera = AVCaptureDevice.default(
            .builtInWideAngleCamera,
            for: AVMediaType.video,
            position: .front)
        else {
            print("Unable to access back camera!")
            return
        }
        
        do {
            //set focus
            if(frontCamera.isFocusModeSupported(.continuousAutoFocus)) {
                frontCamera.focusMode = AVCaptureDevice.FocusMode.autoFocus
                frontCamera.exposureMode = AVCaptureDevice.ExposureMode.autoExpose
            }
            
            let input = try AVCaptureDeviceInput(device: frontCamera)
            
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
        self.captureSession.stopRunning()
    }
    
    
    public override var shouldAutorotate : Bool {
        return false
    }
    
    private func decodePayload(data: Any) -> Bool {
        if let result = data as? Dictionary<String, AnyObject> {
            let payload = result["payload"] as? Dictionary<String, AnyObject>
            if(payload != nil) {
                let status = payload!["status"] as? Optional<Int>
                return status == 1
            }
        }
        return false
    }
    
    private func back() {
        DispatchQueue.main.async {
            Vibration.success.vibrate()
            self.hideLoadingShowSuccess()
            self.action_label.text = "Proceso terminado"
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.onComplete!()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if(!self.detecting) {
            self.detecting = true
            self.scan(sampleBuffer: sampleBuffer)
        }
        
    }
    
    private func scan(sampleBuffer: CMSampleBuffer) {
        let image = sampleBuffer.toUIImage()
        
        if !faceComplete {
            let boxes = detector.detectFace(image)
            
            if(boxes.count == 1) {
                client.faceScanner(image: image) { data, error in
                    let status = self.decodePayload(data: data ?? false)
                    if(status) {
                        DispatchQueue.main.async {
                            self.faceComplete = true
                            self.scanFront = true
                            self.setActionText(text: "Por favor muestra la parte frontal de tu identificación oficial INE/IFE", action: "Esperando parte frontal de tu ID")
                        }
                    }
                    //
                    self.detecting = false
                }
            } else {
                self.detecting = false
            }
        }
        
        if scanFront {
            let detections = detector.detectID(image)
            
            if(!detections.isEmpty) {
                self.filterdetection(detection: detections[0], image: image)
            }
            
            self.detecting = false
        }
        
        if scanBack {
            let detections = detector.detectID(image)
            
            if(!detections.isEmpty) {
                self.filterdetection(detection: detections[0], image: image)
            }
            
            self.detecting = false
        }
    }
    
    private func filterdetection(detection: Detection, image: UIImage) {
        if scanFront {
            if(detection.label == "mx_id_front") {
                frontCount += 1
                
                if frontCount > 40 {
                    setActionText(text: "Por favor muestra la parte trasera de tu identificación oficial INE/IFE", action: "Esperando parte trasera de tu ID")
                    scanFrontComplete = true;
                    scanFront = false;
                    scanBack = true
                }
                
            }
        }
        
        if scanBack {
            if(detection.label == "mx_id_back") {
                backCount += 1
                
                if backCount > 40 {
                    setActionText(text: "Proceso finalizado, espera por favor", action: "Proceso finalizado")
                    scanBackComplete = true;
                    scanBack = false;
                    self.back()
                }
            }
        }
    }
    
    private func setActionText(text: String, action: String) {
        DispatchQueue.main.async {
            self.summary_label.text = text
            self.action_label.text = action
            Vibration.success.vibrate()
        }
    }
    
}


