//
//  FingerprintPreview.swift
//  NebuIA
//
//  Created by Miguel on 28/06/21.
//

import UIKit
import AVFoundation
import Cartography

public class FingerprintPreviewController: UIViewController {
    
    var fingers: [Finger]!
    var client: Client!
    private var content_view: UIView!
    private var draw_detections: UIView!
    private var draw_detections_thin: UIView!
    
    private var status_button: UIButton!
    private var subtitle_label: UILabel!
    
    private var title_label: UILabel!
    private var summary_label: UILabel!
    
    private var image_preview_index: UIImageView!
    private var nfiq_preview_index: UILabel!
    
    private var image_preview_middle: UIImageView!
    private var nfiq_preview_middle: UILabel!
    
    private var image_preview_ring: UIImageView!
    private var nfiq_preview_ring: UILabel!
    
    private var image_preview_little: UIImageView!
    private var nfiq_preview_little: UILabel!
    
    private var nebuia_logo: UIImageView!
    
    private var continue_id: UIButton!
    //private var retake: UIButton!
    
    var onDismmisBlock : (() -> Void)?
    var onCompleteBlock : ((Finger, Finger, Finger, Finger) -> Void)?
    var onSkipBlock : ((Finger, Finger, Finger, Finger) -> Void)?
    var currentStep: Int = 1
    
    @IBAction func goBack(_ sender: UIButton) {
        self.back()
    }
    
    @IBAction func continueFinger(_ sender: UIButton) {
        self.onCompleteBlock!(fingers[0], fingers[1], fingers[2], fingers[3])
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func skipFinger(_ sender: UIButton) {
        self.onSkipBlock!(fingers[0], fingers[1], fingers[2], fingers[3])
        self.dismiss(animated: true, completion: nil)
    }
    
    private func buildContinueButton() {
        continue_id = UIButton(type: .system)
        
        continue_id.frame = CGRect(x: 0, y: 0, width: 135, height: 45)
        continue_id.tintColor = UIColor.blue
        continue_id.layer.cornerRadius =  6
        continue_id.clipsToBounds = true
        continue_id.contentMode = UIView.ContentMode.scaleToFill
        
        continue_id.backgroundColor = .systemBlue
        continue_id.tintColor = .white
        continue_id.translatesAutoresizingMaskIntoConstraints = false
        
        if fingers[0].score! > 45 {
            continue_id.setTitle("Continuar", for: .normal)
            continue_id.addTarget(self, action: #selector(continueFinger(_:)), for: .touchUpInside)
        } else {
            if currentStep == 4 {
                continue_id.setTitle("Saltar paso", for: .normal)
            } else {
                continue_id.setTitle("Capturar nuevamente", for: .normal)
            }
            continue_id.addTarget(self, action: #selector(skipFinger(_:)), for: .touchUpInside)
        }
    }
    
    /* private func buildRetakeButton() {
        retake = UIButton(type: .system)
        
        retake.frame = CGRect(x: 0, y: 0, width: 135, height: 45)
        retake.tintColor = UIColor.blue
        retake.setTitle("Capturar nuevamente", for: .normal)
        retake.layer.cornerRadius =  6
        retake.clipsToBounds = true
        retake.contentMode = UIView.ContentMode.scaleToFill
        
        retake.backgroundColor = .white
        retake.tintColor = .systemBlue
        retake.translatesAutoresizingMaskIntoConstraints = false
        retake.addTarget(self, action: #selector(goBack(_:)), for: .touchUpInside)
        
        
        retake.isHidden = fingers[0].score! > 45
        
    } */
    
    private func buildTitleLabel() {
        title_label = UILabel(frame: UIScreen.main.bounds)
        title_label.textAlignment = .center
        title_label.numberOfLines = 1
        title_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 16), weight: .bold)
        title_label.minimumScaleFactor = 10/UIFont.labelFontSize
        title_label.adjustsFontSizeToFitWidth = true
        title_label.textColor = .black
        title_label.text = "Revisa tus huellas"
    }
    
    private func buildSummaryLabel() {
        summary_label = UILabel(frame: UIScreen.main.bounds)
        summary_label.textAlignment = .center
        summary_label.numberOfLines = 2
        summary_label.minimumScaleFactor = 10/UIFont.labelFontSize
        summary_label.adjustsFontSizeToFitWidth = true
        summary_label.textColor =  UIColor(rgb: 0x7d82a8)
        summary_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 10), weight: .regular)
        summary_label.text = fingers[0].score! > 45 ? "Tus huellas dactilares fueron capuradas correctamente, puedes continuar con el proceso" : "Tus huellas no alcanzan una calificación satisfactoria, deberás realizar el proceso nuevamente"
    }
    
    private func buildLogoBottom() {
        let logo = UIImage(named: "nebuia_black.png")
        nebuia_logo = UIImageView(image: logo!)
    }
    
    private func buildImageIndex() {
        image_preview_index = UIImageView()
        image_preview_index.clipsToBounds = true
        nfiq_preview_index = UILabel(frame: UIScreen.main.bounds)
        
        self.image_preview_index.image = fingers[0].image!.imageWithInsets(insets: UIEdgeInsets(top: 30, left: 35, bottom: 30, right: 35))

        
        self.nfiq_preview_index.textAlignment = .center
        self.nfiq_preview_index.numberOfLines = 1
        self.nfiq_preview_index.minimumScaleFactor = 10/UIFont.labelFontSize
        self.nfiq_preview_index.adjustsFontSizeToFitWidth = true
        self.nfiq_preview_index.textColor = .black
        self.nfiq_preview_index.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 8), weight: .regular)
        self.nfiq_preview_index.text = "NFIQ \(String(describing:  fingers[0].score!))"

    }
    
    private func buildImageMiddle() {
        image_preview_middle = UIImageView()
        image_preview_middle.layer.cornerRadius =  10
        image_preview_middle.clipsToBounds = true
        nfiq_preview_middle = UILabel(frame: UIScreen.main.bounds)
        
        self.image_preview_middle.image = fingers[1].image!.imageWithInsets(insets: UIEdgeInsets(top: 30, left: 35, bottom: 30, right: 35))
        
        self.nfiq_preview_middle.textAlignment = .center
        self.nfiq_preview_middle.numberOfLines = 1
        self.nfiq_preview_middle.minimumScaleFactor = 10/UIFont.labelFontSize
        self.nfiq_preview_middle.adjustsFontSizeToFitWidth = true
        self.nfiq_preview_middle.textColor = .black
        self.nfiq_preview_middle.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 8), weight: .regular)
        self.nfiq_preview_middle.text = "NFIQ \(String(describing: fingers[1].score!))"
    }
    
    private func buildImageRing() {
        image_preview_ring = UIImageView()
        image_preview_ring.layer.cornerRadius =  10
        image_preview_ring.clipsToBounds = true
        nfiq_preview_ring = UILabel(frame: UIScreen.main.bounds)
        
        self.image_preview_ring.image = fingers[2].image!.imageWithInsets(insets: UIEdgeInsets(top: 30, left: 35, bottom: 30, right: 35))
        
        self.nfiq_preview_ring.textAlignment = .center
        self.nfiq_preview_ring.numberOfLines = 1
        self.nfiq_preview_ring.minimumScaleFactor = 10/UIFont.labelFontSize
        self.nfiq_preview_ring.adjustsFontSizeToFitWidth = true
        self.nfiq_preview_ring.textColor = .black
        self.nfiq_preview_ring.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 8), weight: .regular)
        self.nfiq_preview_ring.text = "NFIQ \(String(describing: fingers[2].score!))"
    
    }
    
    private func buildImageLittle() {
        image_preview_little = UIImageView()
        image_preview_little.layer.cornerRadius =  10
        image_preview_little.clipsToBounds = true
        nfiq_preview_little = UILabel(frame: UIScreen.main.bounds)
        
        self.image_preview_little.image = fingers[3].image!.imageWithInsets(insets: UIEdgeInsets(top: 30, left: 35, bottom: 30, right: 35))
        
        self.nfiq_preview_little.textAlignment = .center
        self.nfiq_preview_little.numberOfLines = 1
        self.nfiq_preview_little.minimumScaleFactor = 10/UIFont.labelFontSize
        self.nfiq_preview_little.adjustsFontSizeToFitWidth = true
        self.nfiq_preview_little.textColor = .black
        self.nfiq_preview_little.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 8), weight: .regular)
        self.nfiq_preview_little.text = "NFIQ \(String(describing: fingers[3].score!))"
    }
    
    private func buildStatusComponents() {
        status_button = UIButton(type: .system)
        
        status_button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        status_button.tintColor = UIColor.blue
        status_button.layer.cornerRadius =  status_button.frame.size.width/2
        status_button.clipsToBounds = true
        status_button.contentMode = UIView.ContentMode.scaleToFill
        
        status_button.backgroundColor = fingers[0].score! > 45 ? UIColor(rgb: 0xa6cc3b) : UIColor(rgb: 0xFF6666)
        status_button.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let btnImage: UIImage
            if fingers[0].score! > 45 {
                btnImage = UIImage(systemName: "checkmark")!
            } else {
                btnImage = UIImage(systemName: "xmark")!
            }
            status_button.setImage(btnImage , for: .normal)
            status_button.tintColor = .white
        }
        
        subtitle_label = UILabel(frame: UIScreen.main.bounds)
        subtitle_label.textAlignment = .center
        subtitle_label.numberOfLines = 2
        subtitle_label.minimumScaleFactor = 10/UIFont.labelFontSize
        subtitle_label.adjustsFontSizeToFitWidth = true
        subtitle_label.textColor = .black
        subtitle_label.text = "Tus huellas han sido capturadas"
        subtitle_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 12), weight: .semibold)
    }
    
    
    func constraintsInit() {
        let botom: CGFloat = UIDevice.current.hasNotch ? 50 : 0
        constrain(title_label, content_view, summary_label, nebuia_logo, continue_id, /*retake,*/status_button, subtitle_label)
        { title_label, content_view, summary_label, nebuia_logo, continue_id, /*retake,*/ status_button, subtitle_label in
            
            title_label.centerX == content_view.centerX
            title_label.top == content_view.superview!.top + 30
            
            status_button.top == content_view.superview!.top + 420
            status_button.centerX == content_view.centerX
            status_button.width == 50
            status_button.height == 50
            
            subtitle_label.centerX == content_view.centerX
            subtitle_label.top == status_button.bottom + 20
            subtitle_label.width == content_view.width / 1.3
            
            summary_label.centerX == content_view.centerX
            summary_label.top == subtitle_label.bottom + 10
            summary_label.width == content_view.width / 1.4
            
            continue_id.centerX == content_view.centerX
            continue_id.top == summary_label.bottom + 30
            continue_id.width == content_view.superview!.width / 1.8
            continue_id.height == 50
            
            //retake.centerX == content_view.centerX
            //retake.top == continue_id.bottom + 10
            //retake.width == continue_id.width
            //retake.height == 50
            
            nebuia_logo.centerX == content_view.centerX
            nebuia_logo.width == content_view.superview!.width / 4.6
            nebuia_logo.height == 17
            nebuia_logo.centerY == content_view.superview!.bottom - botom - 50
            distribute(by: 15, vertically: nebuia_logo)
        }
        
        constrain(content_view, image_preview_index, image_preview_middle, image_preview_ring, image_preview_little, draw_detections, nfiq_preview_index, nfiq_preview_middle, nfiq_preview_ring, nfiq_preview_little)
        { content_view, image_preview_index, image_preview_middle, image_preview_ring, image_preview_little, draw_detections, nfiq_preview_index, nfiq_preview_middle, nfiq_preview_ring, nfiq_preview_little in
            
            draw_detections.centerX == content_view.superview!.centerX
            
            image_preview_index.left == draw_detections.superview!.centerX / 2.3
            image_preview_index.top == content_view.superview!.top + 80
            image_preview_index.height ==  110
            image_preview_index.width == 110
            
            nfiq_preview_index.left ==  image_preview_index.left + 40
            nfiq_preview_index.top == image_preview_index.bottom + 10
            
            image_preview_middle.top == image_preview_index.top
            image_preview_middle.height ==  110
            image_preview_middle.width == 110
            image_preview_middle.left == image_preview_index.right + 10
            
            nfiq_preview_middle.left ==  image_preview_middle.left + 40
            nfiq_preview_middle.top == image_preview_middle.bottom + 10
            
            image_preview_ring.left == draw_detections.superview!.centerX / 2.3
            image_preview_ring.top == image_preview_index.bottom + 30
            image_preview_ring.height ==  110
            image_preview_ring.width == 110
            
            nfiq_preview_ring.left ==  image_preview_ring.left + 40
            nfiq_preview_ring.top == image_preview_ring.bottom + 10
            
            image_preview_little.top == image_preview_index.bottom + 30
            image_preview_little.height ==  110
            image_preview_little.width == 110
            image_preview_little.left == image_preview_ring.right + 10
            
            nfiq_preview_little.left ==  image_preview_little.left + 40
            nfiq_preview_little.top == image_preview_little.bottom + 10
        }
    }
    
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // camera
        content_view = UIView(frame: UIScreen.main.bounds)
        draw_detections = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 120))
        draw_detections_thin = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 120))
        
        // set up title layer
        buildTitleLabel()
        content_view.addSubview(title_label)
        
        // set up summary
        buildSummaryLabel()
        content_view.addSubview(summary_label)
        
        // set up continue button
        buildContinueButton()
        content_view.addSubview(continue_id)
        
        // set up retake button
        //buildRetakeButton()
        //content_view.addSubview(retake)
        
        // set up logo
        buildLogoBottom()
        content_view.addSubview(nebuia_logo)
        
        buildStatusComponents()
        content_view.addSubview(status_button)
        content_view.addSubview(subtitle_label)
        
        // build preview document
        buildImageIndex()
        draw_detections.addSubview(image_preview_index)
        draw_detections.addSubview(nfiq_preview_index)
        
        buildImageMiddle()
        draw_detections.addSubview(image_preview_middle)
        draw_detections.addSubview(nfiq_preview_middle)
        
        buildImageRing()
        draw_detections.addSubview(image_preview_ring)
        draw_detections.addSubview(nfiq_preview_ring)
        
        buildImageLittle()
        draw_detections.addSubview(image_preview_little)
        draw_detections.addSubview(nfiq_preview_little)
        
        content_view.addSubview(draw_detections)
        content_view.addSubview(draw_detections_thin)
        
        let root_view = UIView(frame: UIScreen.main.bounds)
        root_view.addSubview(content_view)
        
        self.view.addSubview(root_view)
        constraintsInit()
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDismmisBlock!()
    }
    
    
    public override var shouldAutorotate : Bool {
        return false
    }
    
    private func back() {
        DispatchQueue.main.async {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    lazy var alertController: UIAlertController = {
        let alert = UIAlertController(title: "Espera", message: "\n\n", preferredStyle: .alert)
        alert.view.tintColor = .black
        let loading = UIActivityIndicatorView(frame: CGRect(x: 110, y: 35, width: 50, height: 50))
        loading.hidesWhenStopped = true
        loading.style = .gray
        loading.startAnimating();
        alert.view.addSubview(loading)
        return alert
    }()
    
    lazy var errorController: UIAlertController = {
        let alert = UIAlertController(title: "Hey", message: "This is  one Alert", preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "Working!!", style: UIAlertAction.Style.default, handler: { void in
            self.back()
        }))
        return alert
    }()
    
    
}


