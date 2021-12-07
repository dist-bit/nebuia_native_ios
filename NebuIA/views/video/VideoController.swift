//
//  SignerController.swift
//  Cartography
//
//  Created by Miguel Angel on 10/11/21.
//

import UIKit
import AVKit
import AVFoundation
import Cartography

public class VideoController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate, AVCaptureAudioDataOutputSampleBufferDelegate {
    
    private var audioDevice: AVCaptureDevice!
    private var captureSession: AVCaptureSession!
    
    private var stillImageOutput: AVCaptureVideoDataOutput!
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer!
    
    
    fileprivate lazy var audioDataOutput = AVCaptureAudioDataOutput()
    fileprivate var videoWriterInput: AVAssetWriterInput!
    fileprivate var audioWriterInput: AVAssetWriterInput!
    var sessionAtSourceTime: CMTime?
    lazy var isRecording = false
    var videoWriter: AVAssetWriter!
    private var adaptor: AVAssetWriterInputPixelBufferAdaptor!
    
    var client: Client!
    var detector: DetectorWrapper!
    
    private var detecting: Bool = true
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
    
    private var text_to_read: UIView!
    private var text_to_read_label: UILabel!
    
    private var scan_id_button: UIButton!
    private var title_label: UILabel!
    private var summary_label: UILabel!
    private var action_label: UILabel!
    
    private var loading_indicator: UIActivityIndicatorView!
    
    private var nebuia_logo: UIImageView!
    
    private var device: AVCaptureDevice!
    
    private var detections_count: [Int] = []
    
    var onCompleteVideo : ((String) -> Void)?
    
    @IBAction func analyseID(_ sender: UIButton) {
        setActionText(text: "Por favor muestra la parte frontal de tu identificación oficial INE/IFE", action: "Esperando parte frontal de tu ID")
        text_to_read.isHidden = true
        scan_id_button.isHidden = true
        scanFront = true
    }
    
    private func buildBackbutton() {
        scan_id_button = UIButton(type: .system)
        
        scan_id_button.frame = CGRect(x: 100, y: 100, width: 50, height: 50)
        
        scan_id_button.layer.cornerRadius =  scan_id_button.frame.size.width/2
        scan_id_button.clipsToBounds = true
        scan_id_button.contentMode = UIView.ContentMode.scaleToFill
        
        scan_id_button.backgroundColor =  UIColor(rgb: 0xa5cd3a)
        scan_id_button.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let btnImage = UIImage(systemName: "checkmark")
            scan_id_button.setImage(btnImage , for: .normal)
            scan_id_button.tintColor = UIColor.white
        }
        scan_id_button.addTarget(self, action: #selector(analyseID(_:)), for: .touchUpInside)
        scan_id_button.isHidden = true
    }
    
    private func buildTitleLabel() {
        title_label = UILabel(frame: UIScreen.main.bounds)
        title_label.textAlignment = .center
        title_label.numberOfLines = 1
        title_label.textColor = .black
        title_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 16), weight: .bold)
        title_label.minimumScaleFactor = 10/UIFont.labelFontSize
        title_label.adjustsFontSizeToFitWidth = true
        title_label.text = "Video grabación"
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
    
    
    
    private func initializeOverlay() {
        text_to_read_label = UILabel(frame: UIScreen.main.bounds)
        text_to_read_label.textAlignment = .center
        text_to_read_label.numberOfLines = 4
        text_to_read_label.textColor = .white
        text_to_read_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 14), weight: .regular)
        text_to_read_label.minimumScaleFactor = 12/UIFont.labelFontSize
        text_to_read_label.adjustsFontSizeToFitWidth = true
        text_to_read_label.text = "Yo Mauricio Lopez Piedra declaro que estoy adquiriendo con pleno conocimiento un credito personal por la canidad de $ 96,000 pesos y plazo indicado en los documentos firmados"
        
        text_to_read = UIView(frame: UIScreen.main.bounds)
        text_to_read.backgroundColor = UIColor(rgb: 0x232a58)
        text_to_read.clipsToBounds = true
        text_to_read.layer.cornerRadius = 20
        text_to_read.isHidden = true
        
    }
    
    func constraintsInit() {
        let botom: CGFloat = UIDevice.current.hasNotch ? 50 : 0
        constrain(scan_id_button, title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, content_view_preview, text_to_read, text_to_read_label)
        { scan_id_button, title_label, content_view, action_label, summary_label, nebuia_logo, loading_indicator, content_view_preview, text_to_read, text_to_read_label in
            
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
            content_view_preview.height == 335
            
            
            summary_label.top == content_view_preview.bottom + 15
            summary_label.width == content_view.superview!.width / 1.2
            summary_label.centerX == content_view.centerX
            
            text_to_read.centerX == content_view.centerX
            text_to_read.top ==  summary_label.bottom + 25
            text_to_read.width == content_view_preview.width + 10
            text_to_read.height == 130
            
            text_to_read_label.centerX == text_to_read.centerX
            text_to_read_label.centerY == text_to_read.centerY - 10
            text_to_read_label.width == text_to_read.width - 40
            
            scan_id_button.width == 50
            scan_id_button.height == 50
            scan_id_button.centerX == content_view.centerX
            scan_id_button.top ==  text_to_read.bottom - 20
            
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
        
        // init overlay camera
        initializeOverlay()
        content_view.addSubview(text_to_read)
        text_to_read.addSubview(text_to_read_label)
        
        // set up back button
        buildBackbutton()
        content_view.addSubview(scan_id_button)
        
        let root_view = UIView(frame: UIScreen.main.bounds)
        root_view.addSubview(content_view_preview)
        root_view.addSubview(content_view)
        
        self.view.addSubview(root_view)
        constraintsInit()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        captureSession = AVCaptureSession()
        captureSession.sessionPreset = .hd1280x720
        
        
        let session = AVCaptureDevice.DiscoverySession.init(
            deviceTypes: [ .builtInWideAngleCamera,.builtInMicrophone], mediaType: AVMediaType.video, position: AVCaptureDevice.Position.front)
        
        let cameras = (session.devices.compactMap{$0})
        
        
        var camera: AVCaptureDevice!
        for device in cameras {
            if device.position == .front {
                camera = device
            }
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            self.device = camera
            
            try camera.lockForConfiguration()
            camera.isSubjectAreaChangeMonitoringEnabled = true
            
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
                
            }
            
            //Setup your microphone
            let audioDevice = AVCaptureDevice.default(for: AVMediaType.audio)
            
            // Add microphone to your session
            let audioInput = try AVCaptureDeviceInput(device: audioDevice!)
            if captureSession.canAddInput(audioInput) {
                captureSession.addInput(audioInput)
            }
            
            //Define your audio output
            if captureSession.canAddOutput(audioDataOutput) {
                audioDataOutput.setSampleBufferDelegate(self, queue: queue)
                captureSession.addOutput(audioDataOutput)
            }
            
            captureSession.commitConfiguration()
            setupWriter()
            setupLivePreview()
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
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
                self.detecting = false
            }
        }
    }
    
    private func back() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    public func captureOutput(_ captureOutput: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard CMSampleBufferDataIsReady(sampleBuffer) else { return }
        
        let writable = canWrite()
        
        if writable,
           sessionAtSourceTime == nil {
            //Start writing
            sessionAtSourceTime = CMSampleBufferGetPresentationTimeStamp(sampleBuffer)
            videoWriter.startSession(atSourceTime: sessionAtSourceTime!)
        }
        
        if captureOutput == stillImageOutput {
            
            self.scan(sampleBuffer: sampleBuffer)
            
            if writable, videoWriterInput.isReadyForMoreMediaData && self.isRecording {
                videoWriterInput.append(sampleBuffer)
            }
        } else if writable,
                  captureOutput == audioDataOutput,
                  audioWriterInput.isReadyForMoreMediaData && self.isRecording {
            //Write audio buffer
            audioWriterInput.append(sampleBuffer)
        }
        
        
        
    }
    
    private func scan(sampleBuffer: CMSampleBuffer) {
        let image = sampleBuffer.toUIImage()
        
        if !faceComplete {
            let boxes = detector.detectFace(image)
            
            if(boxes.count == 1) {
                faceCount += 1
                if faceCount > 40 {
                    DispatchQueue.main.async {
                        self.start()
                        self.text_to_read.isHidden = false
                        self.scan_id_button.isHidden = false
                        self.faceComplete = true
                    }
                    
                    setActionText(text: "Por favor lee claramente el siguiente texto, una vez terminado pulsa el botón verde", action: "Esperando lectura")
                }
            }
        }
        
        if scanFront {
            let detections = detector.detectID(image)
            
            if(!detections.isEmpty) {
                self.filterdetection(detection: detections[0], image: image)
            }
        }
        
        if scanBack {
            let detections = detector.detectID(image)
            
            if(!detections.isEmpty) {
                self.filterdetection(detection: detections[0], image: image)
            }
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
                    setActionText(text: "Proceso finalizado, espera por favot", action: "Proceso finalizado")
                    scanBackComplete = true;
                    scanBack = false;
                   
                    self.stop { data in
                        self.onCompleteVideo!(data!)
                        self.back()
                    }
                    
                    
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
    
    private func setupWriter() {
        
        do {
            let fileManager = FileManager.default
            let urls = fileManager.urls(for: .documentDirectory, in: .userDomainMask)
            guard let documentDirectory: URL = urls.first else {
                fatalError("documentDir Error")
            }
            
            let videoOutputURL = documentDirectory.appendingPathComponent("OutputVideo.mp4")
            
            if FileManager.default.fileExists(atPath: videoOutputURL.path) {
                do {
                    try FileManager.default.removeItem(atPath: videoOutputURL.path)
                } catch {
                    fatalError("Unable to delete file: \(error) : \(#function).")
                }
            }
            
            
            videoWriter = try AVAssetWriter(url: videoOutputURL, fileType: AVFileType.mp4)
    
            videoWriterInput = AVAssetWriterInput(mediaType: AVMediaType.video, outputSettings: [
                AVVideoCodecKey: AVVideoCodecType.h264,
                AVVideoWidthKey: 1280,
                AVVideoHeightKey: 720,
                AVVideoCompressionPropertiesKey: [
                    AVVideoAverageBitRateKey: 2300000,
                ],
            ])
            
            videoWriterInput.transform = getVideoTransform()
            videoWriterInput.expectsMediaDataInRealTime = true //Make sure we are exporting data at realtime
            if videoWriter.canAdd(videoWriterInput) {
                videoWriter.add(videoWriterInput)
            }
            
            //Add audio input
            audioWriterInput = AVAssetWriterInput(mediaType: AVMediaType.audio, outputSettings: [
                AVFormatIDKey: kAudioFormatMPEG4AAC,
                AVNumberOfChannelsKey: 1,
                AVSampleRateKey: 44100,
                AVEncoderBitRateKey: 64000,
            ])
            
            audioWriterInput.expectsMediaDataInRealTime = true
            if videoWriter.canAdd(audioWriterInput) {
                videoWriter.add(audioWriterInput)
            }

        }
        catch let error {
            debugPrint(error.localizedDescription)
        }
    }
    
    private func getVideoTransform() -> CGAffineTransform {
        return CGAffineTransform(rotationAngle: .pi/2)
    }
    
}


