//
//  FaceController.swift
//  NebuIA
//
//  Created by Miguel on 20/06/21.
//

import UIKit
import AVFoundation
import Cartography

public class FaceController: UIViewController,  AVCaptureVideoDataOutputSampleBufferDelegate {
    
    private var captureSession: AVCaptureSession!
    private var stillImageOutput: AVCaptureVideoDataOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    var client: Client!
    var detector: DetectorWrapper!
    
    private var detecting: Bool = false
    
    private var camera_view: UIView!
    private var content_view: UIView!
    
    private var back_button: UIButton!
    private var title_label: UILabel!
    private var summary_label: UILabel!
    private var action_label: UILabel!
    
    private var loading_indicator: UIActivityIndicatorView!
    
    private var nebuia_logo: UIImageView!
    private var success_icon: UIImageView!
    
    var onComplete: (() -> Void)?
    
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
        title_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 16), weight: .bold)
        title_label.minimumScaleFactor = 10/UIFont.labelFontSize
        title_label.adjustsFontSizeToFitWidth = true
        title_label.text = "Reconocimiento facial"
    }
    
    private func buildActionLabel() {
        action_label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        action_label.textAlignment = .center
        action_label.numberOfLines = 1
        action_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 10), weight: .regular)
        action_label.minimumScaleFactor = 10/UIFont.labelFontSize
        action_label.adjustsFontSizeToFitWidth = true
        action_label.text = "Realizando prueba de vida"
    }
    
    private func buildSummaryLabel() {
        summary_label = UILabel(frame: UIScreen.main.bounds)
        summary_label.textAlignment = .left
        summary_label.numberOfLines = 2
        summary_label.minimumScaleFactor = 10/UIFont.labelFontSize
        summary_label.adjustsFontSizeToFitWidth = true
        summary_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 12), weight: .regular)
        summary_label.text = "Realizaremos la prueba de vida\nColoca tu rostro en el centro de la pantalla"
    }
    
    private func buildLogoBottom() {
        let logo = UIImage(named: "nebuia_white.png")
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
        loading_indicator.startAnimating()
    }
    
    private func hideLoadingShowSuccess() {
        UIView.transition(with: loading_indicator, duration: 0.4, options: .transitionCrossDissolve, animations: {() -> Void in
            self.loading_indicator.isHidden = true
            self.success_icon.isHidden = false
        }, completion: { _ in })
    }
    
    func constraintsInit() {
        let botom: CGFloat = UIDevice.current.hasNotch ? 50 : 0
        constrain(back_button!, title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, success_icon)
        { back_button, title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, success_icon in
            back_button.width == 45
            back_button.height == 45
            back_button.left == content_view.superview!.left + 25
            back_button.top == content_view.superview!.top + 20
            title_label.left == back_button.left
            title_label.top == back_button.bottom + 20
            summary_label.top == title_label.top + 30
            summary_label.left == back_button.left
            action_label.left == back_button.left
            action_label.centerX == content_view.centerX
            loading_indicator.centerX == content_view.centerX
            success_icon.centerX == content_view.centerX
            success_icon.top == action_label.bottom + 15
            nebuia_logo.centerX == content_view.centerX
            nebuia_logo.width == content_view.superview!.width / 4.6
            nebuia_logo.height == 17
            nebuia_logo.centerY == content_view.superview!.bottom - botom - 50
            distribute(by: 15, vertically: action_label, loading_indicator, nebuia_logo)
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        // camara
        camera_view = UIView(frame: UIScreen.main.bounds)
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
        
        
        let root_view = UIView(frame: UIScreen.main.bounds)
        root_view.addSubview(camera_view)
        root_view.addSubview(content_view)
        
        self.view.addSubview(root_view)
        constraintsInit()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .photo
        
        
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
            
            let image = sampleBuffer.toUIImage()
            let boxes = detector.detectFace(image)
        
            if(boxes.count == 1) {
                client.faceScanner(image: image) { data, error in
                    let status = self.decodePayload(data: data ?? false)
                    self.detecting = status
                    if(status) {
                        self.back()
                    }
                }
            } else {
                self.detecting = false
            }
        }
    }
}
