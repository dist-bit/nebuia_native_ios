//
//  FingerprintScannerController.swift
//  NebuIA
//
//  Created by Miguel on 28/06/21.
//

import UIKit
import AVFoundation
import Cartography
import NicoProgress

@available(iOS 13.0, *)
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
    private var instructions_container: UIView!
    
    private var back_button: UIButton!
    private var title_label: UILabel!
    private var summary_label: UILabel!
    private var action_label: UILabel!
    
    private var scores_label: UILabel!
    
    private var loading_indicator: UIActivityIndicatorView!
    
    private var nebuia_logo: UIImageView!
    private var success_icon: UIImageView!
    
    private var device: AVCaptureDevice!
    
    //
    private var progress_bar: NicoProgressBar!
    private var progress_bar_container: UIView!
    private var counter = 0
    private var timer = Timer()
    private var timeLimit = false
    private var continue_id: UIButton!
    
    private var detections_count: [Int] = []
    
    var onCompleteFingerprint : ((Finger, Finger, Finger, Finger) -> Void)?
    var onSkip : (() -> Void)?
    
    @IBAction func goBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func skipStep(_ sender: UIButton) {
        self.onSkip!()
        DispatchQueue.main.async {
            self.back()
        }
    }
    
    private func buildBackbutton() {
        back_button = UIButton(type: .system)
        
        back_button.frame = CGRect(x: 100, y: 100, width: 45, height: 45)
        
        back_button.layer.cornerRadius =  back_button.frame.size.width/2
        back_button.clipsToBounds = true
        back_button.contentMode = UIView.ContentMode.scaleToFill
        
        back_button.backgroundColor =  UIColor(rgb: 0xffffff).withAlphaComponent(0.3)
        back_button.translatesAutoresizingMaskIntoConstraints = false
        
        let btnImage = UIImage(systemName: "chevron.backward")
        back_button.setImage(btnImage , for: .normal)
        back_button.tintColor = UIColor.white
        back_button.addTarget(self, action: #selector(goBack(_:)), for: .touchUpInside)
    }
    
    private func buildTitleLabel() {
        title_label = UILabel(frame: UIScreen.main.bounds)
        title_label.textAlignment = .center
        title_label.numberOfLines = 1
        title_label.textColor = .white
        title_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 16), weight: .bold)
        title_label.minimumScaleFactor = 10/UIFont.labelFontSize
        title_label.adjustsFontSizeToFitWidth = true
        title_label.text = "Huella dactilar"
    }
    
    private func buildActionLabel() {
        action_label = UILabel(frame: CGRect(x: 0, y: 0, width: 200, height: 21))
        action_label.textAlignment = .center
        action_label.numberOfLines = 1
        action_label.textColor = UIColor(rgb: 0xff2886de)
        action_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 11), weight: .regular)
        action_label.minimumScaleFactor = 10/UIFont.labelFontSize
        action_label.adjustsFontSizeToFitWidth = true
        action_label.text = "Esperando huella dactilar"
    }
    
    private func buildSummaryLabel() {
        summary_label = UILabel(frame: UIScreen.main.bounds)
        summary_label.textAlignment = .center
        summary_label.numberOfLines = 3
        summary_label.minimumScaleFactor = 14/UIFont.labelFontSize
        summary_label.adjustsFontSizeToFitWidth = true
        summary_label.textColor = UIColor.white
        summary_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 14), weight: .regular)
        summary_label.text = "Coloca tu mano sobre la cámara enfocando tus 4 dedos de tu mano hasta resaltar tus huellas dactilares lo más cerca posible"
    }
    
    private func buildScoresLabel() {
        scores_label = UILabel(frame: UIScreen.main.bounds)
        scores_label.textAlignment = .center
        scores_label.numberOfLines = 3
        scores_label.minimumScaleFactor = 10/UIFont.labelFontSize
        scores_label.adjustsFontSizeToFitWidth = true
        scores_label.textColor = UIColor.white
        scores_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 12), weight: .regular)
        scores_label.text = ""
    }
    
    private func buildLogoBottom() {
        let logo = UIImage(named: "nebuia_white.png")
        nebuia_logo = UIImageView(image: logo!)
    }
    
    private func buildSuccessIcon() {
        let check = UIImage(systemName: "checkmark.circle.fill")
        success_icon = UIImageView(image: check!)
        success_icon.tintColor = UIColor(rgb: 0x16a085)
        self.success_icon.isHidden = true
    }
    
    private func buildLoadingindicator() {
        loading_indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        loading_indicator.color = .white
        loading_indicator.startAnimating()
    }
    
    private func buildProgressBar() {
        progress_bar_container = UIView(frame: UIScreen.main.bounds)
        progress_bar = NicoProgressBar()
        progress_bar.transition(to: .determinate(percentage: 0.0))
        
        progress_bar.primaryColor = .green
        progress_bar.secondaryColor = .gray.withAlphaComponent(0.3)
        progress_bar_container.addSubview(progress_bar)
        
        NSLayoutConstraint(item: progress_bar!, attribute: .top, relatedBy: .equal, toItem: progress_bar_container, attribute: .top, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: progress_bar!, attribute: .bottom, relatedBy: .equal, toItem: progress_bar_container, attribute: .bottom, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: progress_bar!, attribute: .leading, relatedBy: .equal, toItem: progress_bar_container, attribute: .leading, multiplier: 1.0, constant: 0).isActive = true
        NSLayoutConstraint(item: progress_bar!, attribute: .trailing, relatedBy: .equal, toItem: progress_bar_container, attribute: .trailing, multiplier: 1.0, constant: 0).isActive = true
        
    }
    
    private func buildContinueButton() {
        continue_id = UIButton(type: .system)
        
        continue_id.frame = CGRect(x: 0, y: 0, width: 135, height: 45)
        continue_id.tintColor = UIColor.blue
        continue_id.setTitle("Saltar paso", for: .normal)
        continue_id.layer.cornerRadius =  6
        continue_id.clipsToBounds = true
        continue_id.contentMode = UIView.ContentMode.scaleToFill
        
        continue_id.backgroundColor = .systemBlue
        continue_id.tintColor = .white
        continue_id.isHidden = true
        continue_id.translatesAutoresizingMaskIntoConstraints = false
        continue_id.addTarget(self, action: #selector(skipStep(_:)), for: .touchUpInside)
    }
    
    private func buildInstructionsContainer() {
        instructions_container = UIButton(type: .system)
    
        instructions_container.layer.cornerRadius =  10
        instructions_container.clipsToBounds = true
        instructions_container.contentMode = UIView.ContentMode.scaleToFill
        
        instructions_container.backgroundColor = .black
    }
    
    private func hideLoadingShowSuccess() {
        UIView.transition(with: loading_indicator, duration: 0.4, options: .transitionCrossDissolve, animations: {() -> Void in
            self.loading_indicator.isHidden = true
            self.success_icon.isHidden = false
        }, completion: { _ in })
    }
    
    
    
    private func initializeOverlay() {
        // overlay_rectangle = UIView(frame: UIScreen.main.bounds)
        //detections_view = UIImageView(frame: UIScreen.main.bounds)
    }
    
    func constraintsInit() {
        let botom: CGFloat = UIDevice.current.hasNotch ? 50 : 0
        constrain(back_button!, title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, success_icon, content_view_preview, progress_bar_container)
        { back_button, title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, success_icon,  content_view_preview, progress_bar_container in
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
            nebuia_logo.width == content_view.superview!.width / 3.5
            nebuia_logo.height == 20
            nebuia_logo.centerY == content_view.superview!.bottom - botom - 80
            
            title_label.centerX == content_view.centerX
            title_label.top == content_view.superview!.top + 40
            
            content_view_preview.centerX == content_view.centerX
            content_view_preview.top == content_view.superview!.top
            content_view_preview.width == content_view.superview!.width
            content_view_preview.height == content_view.superview!.height
            
            
            summary_label.top == action_label.top - 75
            summary_label.width == content_view.superview!.width / 1.2
            summary_label.centerX == content_view.centerX
            
            progress_bar_container.width == content_view.superview!.width / 1.2
            progress_bar_container.height ==  5
            progress_bar_container.top == action_label.top - 100
            progress_bar_container.centerX == content_view.centerX
            
            distribute(by: 20, vertically: action_label, loading_indicator, nebuia_logo)
        }
        
        constrain(content_view, summary_label, scores_label, continue_id, instructions_container)
        { content_view, summary_label, scores_label, continue_id, instructions_container in

            instructions_container.top == content_view.bottom - 370
            instructions_container.height == 270
            instructions_container.width == content_view.superview!.width / 1.05
            instructions_container.centerX == content_view.centerX
            
            scores_label.top == instructions_container.top + 10
            scores_label.width == summary_label.width
            scores_label.centerX == summary_label.centerX
            
            continue_id.top == summary_label.bottom + 10
            continue_id.width == summary_label.width
            continue_id.centerX == summary_label.centerX
            continue_id.height == 50
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [self] in
            self.detecting = false
            self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.timerAction), userInfo: nil, repeats: true)
        
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            self.toggleTorch(on: true)
        }
        
        // camara
        content_view_preview = UIView(frame: UIScreen.main.bounds)
        content_view_preview.layer.cornerRadius = 10
        content_view_preview.clipsToBounds = true
        content_view = UIView(frame: UIScreen.main.bounds)
        
        // set up back button
        buildBackbutton()
        content_view.addSubview(back_button)
        
        // set up title layer
        buildTitleLabel()
        content_view.addSubview(title_label)
        
        
        buildInstructionsContainer()
        content_view.addSubview(instructions_container)
        
        // set up action label
        buildActionLabel()
        instructions_container.addSubview(action_label)
        
        // set up summary
        buildSummaryLabel()
        instructions_container.addSubview(summary_label)
        
        // set up summary
        buildScoresLabel()
        instructions_container.addSubview(scores_label)
        
        // set up logo
        buildLogoBottom()
        instructions_container.addSubview(nebuia_logo)
        
        // set loading indicator
        buildLoadingindicator()
        instructions_container.addSubview(loading_indicator)
        
        // set up success icon
        buildSuccessIcon()
        instructions_container.addSubview(success_icon)
        
        // set up progress bar
        buildProgressBar()
        instructions_container.addSubview(progress_bar_container)
        
        buildContinueButton()
        instructions_container.addSubview(continue_id)
        
        // init overlay camera
        initializeOverlay()
        
        let root_view = UIView(frame: UIScreen.main.bounds)
        root_view.addSubview(content_view_preview)
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
            let detections = detector.detectFingerprints(image) as [Detection]
            
            var scores = [Float]()
            var rects = [CGRect]()
            
            if(detections.count == 4) {
                for i in 0 ..< detections.count {
                    let detection = detections[i]
                    rects.append(detection.rect())
                    let crop = image.crop(rect: detection.rect())
                    let rotate = crop.rotate(radians: position == 0 ? -1.5708 : 1.5708)
                    let score = detector.qualityFingerprint(rotate!)
                    scores.append(score)
                    
                }
                
            }
            
            let size = scores.count
            
            if size == 4 {
                let percent = (scores[3]) * 100 / 5.0
                setPercent(value: percent)
                setScores(scores: scores)
            }
            
            if size == 4 && scores[3] >= 5.0 && scores[2] >= 3.0 {
                
            
                Vibration.success.vibrate()
                rects.removeAll()
                
                // show loading modal
                DispatchQueue.main.async {
                    self.showSpinner(onView: self.view)
                }
                
                // get image
                client.fingerprints(image: image, position: position, completion: { data, error in
                    self.setPercent(value: 0.0)
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
                                self.timer.invalidate()
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
                setPercent(value: 0.0)
            }
        }
    }
    
    public func setScores(scores: [Float]) {
        DispatchQueue.main.async {
            self.scores_label.text = "\(scores[0]) \(scores[1]) \(scores[2]) \(scores[3])"
        }
    }
    
    private func setPercent(value: Float) {
        DispatchQueue.main.async {
            if(value < 20) {
                self.progress_bar.primaryColor = .red
            } else if(value > 20 && value < 40) {
                self.progress_bar.primaryColor = .orange
            } else if(value > 40 && value < 70) {
                self.progress_bar.primaryColor = .yellow
            } else if(value > 70) {
                self.progress_bar.primaryColor = .green
            }
            self.progress_bar.transition(to: .determinate(percentage: CGFloat(value)))
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
    
    @objc func timerAction() {
           counter += 1
        if counter == 25 {
            DispatchQueue.main.async {
               // hide items
                Vibration.warning.vibrate()
                self.summary_label.text = "No hemos podido detectar tus huellas, asegurate de contar con las condiciones adecuadas."
            }
        }
        
        if counter == 50 {
            timeLimit = true
            self.timer.invalidate()
            DispatchQueue.main.async {
               // hide items
                self.progress_bar_container.isHidden = true
                self.scores_label.isHidden = true
                self.action_label.isHidden = true
                self.loading_indicator.isHidden = true
                self.continue_id.isHidden = false
                Vibration.error.vibrate()
                self.summary_label.text = "Parece que no puedes capturar tus huellas, puedes saltar este paso"
            }
        }
       }
    
}

