//
//  FaceController.swift
//  NebuIA
//
//  Created by Miguel on 20/06/21.
//

import UIKit
import AVFoundation
import Cartography

public class IDScannerController: UIViewController,  AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private let photoOutput = AVCapturePhotoOutput()
    
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCaptureVideoDataOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var client: Client!
    var document: Document!
    var detector: DetectorWrapper!
    
    private var detecting: Bool = false
    private var complete: Bool = false
    
    private var camera_view: UIView!
    private var content_view: UIView!
    private var panel_bottom: UIView!
    private var separator: UIView!
    private var overlay_rectangle: UIView!
    
    private var back_button: UIButton!
    private var capture_button: UIButton!
    
    private var title_label: UILabel!
    private var summary_label: UILabel!
    
    private var nebuia_logo: UIImageView!
    
    var onComplete: (() -> Void)?
    var onError: (() -> Void)?
    
    private let upload: UploadIDController = UploadIDController()
    
    @IBAction func goBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func buildBackbutton() {
        back_button = UIButton(type: .system)
        
        back_button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        
        back_button.layer.cornerRadius =  back_button.frame.size.width/2
        back_button.clipsToBounds = true
        back_button.contentMode = UIView.ContentMode.scaleToFill
        
        back_button.backgroundColor =  UIColor(rgb: 0x2d2d2d)
        back_button.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let btnImage = UIImage(systemName: "chevron.backward")
            back_button.setImage(btnImage , for: .normal)
            back_button.tintColor = UIColor(rgb: 0x6a6a6a)
        }
        back_button.addTarget(self, action: #selector(goBack(_:)), for: .touchUpInside)
    }
    
    private func buildCaptureButton() {
        capture_button = UIButton(type: .system)
        
        capture_button.frame = CGRect(x: 100, y: 100, width: 60, height: 60)
        
        capture_button.layer.cornerRadius =  capture_button.frame.size.width/2
        capture_button.clipsToBounds = true
        capture_button.contentMode = UIView.ContentMode.scaleToFill
        
        capture_button.backgroundColor =  UIColor.white
        capture_button.translatesAutoresizingMaskIntoConstraints = false
        
        capture_button.layer.addGradientBorder(colors:[UIColor(rgb: 0x1c1c1c),UIColor(rgb: 0x1c1c1c)] , width: 12)
        capture_button.layer.addGradientBorder(colors:[UIColor(rgb: 0x3580fb),UIColor(rgb: 0x3580fb)] , width: 3)

        capture_button.addTarget(self, action: #selector(handleTakePhoto), for: .touchUpInside)
    }
    
    private func buildTitleLabel() {
        title_label = UILabel(frame: UIScreen.main.bounds)
        title_label.textAlignment = .center
        title_label.numberOfLines = 1
        title_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 16), weight: .bold)
        title_label.minimumScaleFactor = 10/UIFont.labelFontSize
        title_label.adjustsFontSizeToFitWidth = true
        title_label.text = "Documento de identidad"
    }
    
    private func buildSummaryLabel() {
        summary_label = UILabel(frame: UIScreen.main.bounds)
        summary_label.textAlignment = .left
        summary_label.numberOfLines = 2
        summary_label.minimumScaleFactor = 10/UIFont.labelFontSize
        summary_label.adjustsFontSizeToFitWidth = true
        summary_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 12), weight: .regular)
        setLabelOrientationID()
    }
    
    private func setLabelOrientationID() {
        if(document.document_side == Side.FRONT) {
            summary_label.text = "Coloca la parte frontal de tu documento\nde identidad en el área marcada"
        } else {
            summary_label.text = "Coloca la parte trasera de tu documento\nde identidad en el área marcada"
        }
    }
    
    private func buildLogoBottom() {
        let logo = UIImage(named: "nebuia_white.png")
        nebuia_logo = UIImageView(image: logo!)
    }
    
    private func buildBottomPanel() {
        panel_bottom = UIView(frame: UIScreen.main.bounds)
        panel_bottom.backgroundColor = UIColor(rgb: 0x1c1c1c)
        panel_bottom.clipsToBounds = true
        panel_bottom.layer.cornerRadius = 20
        panel_bottom.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    private func buildSeparator() {
        separator = UIView(frame:  CGRect(x: 0, y: 0, width: 40, height: 20))
        separator.backgroundColor = UIColor(rgb: 0x303030)
        separator.clipsToBounds = true
        separator.layer.cornerRadius = 3
    }
    
    private func initializeOverlay() {
        overlay_rectangle = UIView(frame: UIScreen.main.bounds)
        overlay_rectangle.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        
        let x = content_view.frame.width / 10
        
        let path = CGMutablePath()
        path.addRoundedRect(in: CGRect(x: x, y: overlay_rectangle.frame.height / 4, width: content_view.frame.width-(2*x), height: content_view.frame.height / 4.2), cornerWidth: 5, cornerHeight: 5)
        path.closeSubpath()
        
        let shape = CAShapeLayer()
        shape.path = path
        shape.lineWidth = 3.0
        shape.strokeColor = UIColor.white.cgColor
        shape.fillColor = UIColor.white.cgColor
        
        overlay_rectangle.layer.addSublayer(shape)
        
        path.addRect(CGRect(origin: .zero, size: overlay_rectangle.frame.size))
        
        let maskLayer = CAShapeLayer()
        maskLayer.backgroundColor = UIColor.black.cgColor
        maskLayer.path = path
        maskLayer.fillRule = CAShapeLayerFillRule.evenOdd
        
        overlay_rectangle.layer.mask = maskLayer
        overlay_rectangle.clipsToBounds = true
    }
    
    func constraintsInit() {
        let botom: CGFloat = UIDevice.current.hasNotch ? 50 : 0
        constrain(back_button!, title_label, content_view, summary_label, nebuia_logo, panel_bottom, separator, capture_button)
        { back_button, title_label, content_view, summary_label, nebuia_logo, panel_bottom, separator, capture_button in
        
            title_label.left == content_view.superview!.left + 25
            title_label.top == content_view.superview!.top + 25
            
            summary_label.top == title_label.top + 30
            summary_label.left == title_label.left
            
            panel_bottom.superview!.height == content_view.superview!.height / 3.3
            panel_bottom.superview!.bottom == content_view.superview!.bottom
            panel_bottom.superview!.width == content_view.superview!.width
            
            separator.width == 60
            separator.height == 4
            separator.centerX == content_view.centerX
            separator.top == panel_bottom.superview!.top + 10
            
            capture_button.centerX == content_view.centerX
            capture_button.top == separator.superview!.top + 55
            capture_button.width == 60
            capture_button.height == 60
            
            back_button.width == 50
            back_button.height == 50
            back_button.left == panel_bottom.superview!.left + 55
            back_button.top == capture_button.top + 5
            
            nebuia_logo.centerX == content_view.centerX
            nebuia_logo.width == content_view.superview!.width / 4.6
            nebuia_logo.height == 15
            nebuia_logo.centerY == content_view.superview!.bottom - botom - 50
            distribute(by: 15, vertically: nebuia_logo)
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // camara
        camera_view = UIView(frame: UIScreen.main.bounds)
        content_view = UIView(frame: UIScreen.main.bounds)
        panel_bottom = UIView(frame: UIScreen.main.bounds)
        
        // set up title layer
        buildTitleLabel()
        content_view.addSubview(title_label)
    
        
        // set up summary
        buildSummaryLabel()
        content_view.addSubview(summary_label)
        
        // panel bottom
        buildBottomPanel()
        content_view.addSubview(panel_bottom)
        
        // set up back button
        buildBackbutton()
        panel_bottom.addSubview(back_button)
        
        // set up capture button
        buildCaptureButton()
        panel_bottom.addSubview(capture_button)
        
        // set up logo
        buildLogoBottom()
        panel_bottom.addSubview(nebuia_logo)
        
        // build separator
        buildSeparator()
        panel_bottom.addSubview(separator)
        
        // init overlay camera
        initializeOverlay()
        
        let root_view = UIView(frame: UIScreen.main.bounds)
        root_view.addSubview(camera_view)
        root_view.addSubview(overlay_rectangle)
        root_view.addSubview(content_view)
        
        self.view.addSubview(root_view)
        constraintsInit()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
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
        
        camera_view.layer.addSublayer(videoPreviewLayer)
        DispatchQueue.global(qos: .userInitiated).async { //[weak self] in
            self.captureSession.startRunning()
            DispatchQueue.main.async {
                self.videoPreviewLayer.frame = self.camera_view.bounds
            }
        }
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        self.captureSession.stopRunning()
    }
    
    
    public override var shouldAutorotate : Bool {
        return false
    }
    
    private func onPreviewDissmis(previewController: PreviewDocumentIDController) {
        previewController.onDismmisBlock = {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                if(!self.complete) {
                    self.detecting = false
                }
            }
        }
    }
    
    private func onContinueDissmis(previewController: PreviewDocumentIDController) {
        previewController.onContinueBlock = {
            self.setLabelOrientationID()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                self.detecting = false
            }
        }
    }
    
    private func onCompleteDissmis(previewController: PreviewDocumentIDController) {
        previewController.onCompleteBlock = {
            DispatchQueue.main.async {
                self.onCompleteUpload()
                self.upload.document = self.document
                self.upload.client = self.client
                self.complete = true
                self.present(self.upload, animated: true, completion: nil)
            }
        }
    }
    
    private func onCompleteUpload() {
        upload.onCompleteBlock = {
            DispatchQueue.main.async {
                self.onComplete!()
                self.back()
            }
        }
        
        upload.onErrorBlock = {
            DispatchQueue.main.async {
                self.onError!()
                self.back()
            }
        }
    }
    
    private func cropdocument(image: UIImage, detection: Detection) {
        let crop = image.crop(rect: detection.rect())
        self.document.setImage(crop: crop, original: image)
        self.document.current_type = detection.label
        
        Vibration.success.vibrate()
        DispatchQueue.main.async {
            let preview: PreviewDocumentIDController = PreviewDocumentIDController()
            preview.document = self.document
            
            self.onPreviewDissmis(previewController: preview)
            self.onContinueDissmis(previewController: preview)
            self.onCompleteDissmis(previewController: preview)
            
            self.present(preview, animated: true, completion: nil)
        }
    }
    
    private func back() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    @objc private func handleTakePhoto() {
       detecting = true
    }
    

    private func filterdetection(detection: Detection, image: UIImage) {
        if(self.document.document_side == Side.FRONT) {
            if(detection.label == "mx_id_front" || detection.label == "mx_passport_front") {
                self.cropdocument(image: image, detection: detection)
            }
        } else if(self.document.document_side == Side.BACK) {
            if(detection.label == "mx_id_back") {
                self.cropdocument(image: image, detection: detection)
            }
        }
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        if(self.detecting) {
            self.detecting = false
            let image = sampleBuffer.toUIImage()
            let detections = detector.detectID(image)
          
            if(!detections.isEmpty) {
                self.filterdetection(detection: detections[0], image: image)
            }
        }
    }
}
