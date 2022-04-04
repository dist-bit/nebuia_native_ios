//
//  UploadIDController.swift
//  NebuIA
//
//  Created by Miguel on 27/06/21.
//

import UIKit
import AVFoundation
import Cartography

@available(iOS 13.0, *)
public class UploadIDController: UIViewController {
    
    var document: Document!
    private var content_view: UIView!
    
    private var status_button: UIButton!
    private var continue_id: UIButton!
    private var summary_label: UILabel!
    private var description_label: UILabel!
    
    private var title_label: UILabel!
    
    private var image_preview_front: UIImageView!
    private var image_preview_back: UIImageView!
    private var nebuia_logo: UIImageView!
    private var loading_indicator: UIActivityIndicatorView!
    
    private var status: Bool = false
    
    var onCompleteBlock : (() -> Void)?
    var onErrorBlock : (() -> Void)?
    
    @IBAction func goBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    private func buildTitleLabel() {
        title_label = UILabel(frame: UIScreen.main.bounds)
        title_label.textAlignment = .center
        title_label.numberOfLines = 1
        title_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 16), weight: .bold)
        title_label.minimumScaleFactor = 10/UIFont.labelFontSize
        title_label.adjustsFontSizeToFitWidth = true
        title_label.textColor = .black
        title_label.text = "Procesando documento"
    }
    
    private func buildStatusComponents() {
        status_button = UIButton(type: .system)
        
        status_button.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        status_button.tintColor = UIColor.blue
        status_button.layer.cornerRadius =  status_button.frame.size.width/2
        status_button.clipsToBounds = true
        status_button.contentMode = UIView.ContentMode.scaleToFill
        
        status_button.backgroundColor = UIColor(rgb: 0xa6cc3b)
        status_button.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let btnImage = UIImage(systemName: "checkmark")
            status_button.setImage(btnImage , for: .normal)
            status_button.tintColor = .white
        }
        
        description_label = UILabel(frame: UIScreen.main.bounds)
        description_label.textAlignment = .center
        description_label.numberOfLines = 2
        description_label.minimumScaleFactor = 10/UIFont.labelFontSize
        description_label.adjustsFontSizeToFitWidth = true
        description_label.textColor = UIColor(rgb: 0x7d82a8)
        description_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 11), weight: .regular)
        
        continue_id = UIButton(type: .system)
        
        continue_id.frame = CGRect(x: 0, y: 0, width: 135, height: 45)
        continue_id.tintColor = UIColor.blue
        continue_id.setTitle("Continuar", for: .normal)
        continue_id.layer.cornerRadius =  6
        continue_id.clipsToBounds = true
        continue_id.contentMode = UIView.ContentMode.scaleToFill
        
        continue_id.backgroundColor = .systemBlue
        continue_id.tintColor = .white
        continue_id.translatesAutoresizingMaskIntoConstraints = false
        continue_id.addTarget(self, action: #selector(complete), for: .touchUpInside)
        
        description_label.isHidden = true
        status_button.isHidden = true
        continue_id.isHidden = true
        //continue_id.addTarget(self, action: #selector(continueID(_:)), for: .touchUpInside)
    }
    
    private func buildSummaryLabel() {
        summary_label = UILabel(frame: UIScreen.main.bounds)
        summary_label.textAlignment = .center
        summary_label.numberOfLines = 2
        summary_label.minimumScaleFactor = 10/UIFont.labelFontSize
        summary_label.adjustsFontSizeToFitWidth = true
        summary_label.textColor = .black
        summary_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 11), weight: .regular)
        summary_label.text = "Por favor espera\nestamos subiendo tu documento"
    }
    
    private func buildLogoBottom() {
        let logo = UIImage(named: "nebuia_black.png")
        nebuia_logo = UIImageView(image: logo!)
    }
    
    private func buildImagePreview() {
        image_preview_front = UIImageView(image: document!.front_crop_image)
        if(document.back_crop_image != nil) {
            image_preview_back = UIImageView(image: document!.back_crop_image)
            image_preview_back.layer.cornerRadius =  10
            image_preview_back.clipsToBounds = true
        }
        image_preview_front.layer.cornerRadius =  10
        image_preview_front.clipsToBounds = true
    }
    
    private func buildLoadingindicator() {
        loading_indicator = UIActivityIndicatorView(frame: CGRect(x: 0, y: 0, width: 40, height: 40))
        loading_indicator.color = .gray
        loading_indicator.startAnimating()
    }
    
    func constraintsInit() {
        let botom: CGFloat = UIDevice.current.hasNotch ? 50 : 0
        constrain(title_label, content_view, summary_label, nebuia_logo, image_preview_front, image_preview_back, loading_indicator, status_button, description_label, continue_id)
        { title_label, content_view, summary_label, nebuia_logo, image_preview_front, image_preview_back, loading_indicator, status_button, description_label, continue_id in
            
            image_preview_front.top == content_view.superview!.top + 80
            image_preview_front.centerX == content_view.centerX
            image_preview_front.height ==  content_view.superview!.height / 4.3
            image_preview_front.width == content_view.superview!.width - 120
            
            image_preview_back.top == image_preview_front.bottom
            image_preview_back.centerX == content_view.centerX
            image_preview_back.height ==  image_preview_front.height
            image_preview_back.width == image_preview_front.width
            
            title_label.centerX == content_view.centerX
            title_label.top == image_preview_front.superview!.top + 40
            
            summary_label.centerX == content_view.centerX
            summary_label.width == image_preview_back.width
            
            description_label.top == summary_label.bottom + 5
            description_label.centerX == content_view.centerX
            description_label.width == image_preview_back.width
            
            loading_indicator.centerX == content_view.centerX
            loading_indicator.top == summary_label.bottom + 20
            
            status_button.top == content_view.centerY + 90
            status_button.centerX == content_view.centerX
            status_button.width == 50
            status_button.height == 50
            
            continue_id.centerX == content_view.centerX
            continue_id.top == description_label.bottom + 20
            continue_id.width == content_view.superview!.width / 1.8
            continue_id.height == 50
            
            nebuia_logo.centerX == content_view.centerX
            nebuia_logo.width == content_view.superview!.width / 4.6
            nebuia_logo.height == 15
            nebuia_logo.centerY == content_view.superview!.bottom - botom - 50
            
            distribute(by: 20, vertically: status_button, summary_label)
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        // camera
        content_view = UIView(frame: UIScreen.main.bounds)
        
        // set up title layer
        buildTitleLabel()
        content_view.addSubview(title_label)
        
        // set loading indicator
        buildLoadingindicator()
        content_view.addSubview(loading_indicator)
        
        // set up summary
        buildSummaryLabel()
        content_view.addSubview(summary_label)
        
        // set up logo
        buildLogoBottom()
        content_view.addSubview(nebuia_logo)
        
        // build preview document
        buildImagePreview()
        content_view.addSubview(image_preview_front)
        if(document.back_crop_image != nil) {
            content_view.addSubview(image_preview_back)
        }
        
        // build status components
        buildStatusComponents()
        content_view.addSubview(continue_id)
        content_view.addSubview(status_button)
        content_view.addSubview(description_label)
        
        let root_view = UIView(frame: UIScreen.main.bounds)
        root_view.addSubview(content_view)
        
        self.view.addSubview(root_view)
        constraintsInit()
    }
    
    private func hideLoadingShowSuccess() {
        UIView.transition(with: self.loading_indicator, duration: 0.4, options: .transitionCrossDissolve, animations: {() -> Void in
            self.loading_indicator.isHidden = true
        }, completion: { _ in })
    }
    
    private func decodeResult(status: Bool) {
        self.status = status
        DispatchQueue.main.async {
            self.hideLoadingShowSuccess()
            if(status) {
                Vibration.success.vibrate()
                self.summary_label.text = "Proceso terminado satisfactoriamente"
                self.description_label.text = "La subida de documentos se realizó correctamente,\npulsa continuar para seguir con el proceso"
            } else {
                Vibration.error.vibrate()
                self.status_button.backgroundColor = UIColor(rgb: 0xe74c3c)
                if #available(iOS 13.0, *) {
                    let btnImage = UIImage(systemName: "xmark")
                    self.status_button.setImage(btnImage , for: .normal)
                }
                self.description_label.text = "La subida de documentos no se pudo completar,\npor favor intentalo una vez mas"
                self.summary_label.text = "Error al procesar tus documentos"
            }
            
            self.continue_id.isHidden = false
            self.status_button.isHidden = false
            self.description_label.isHidden = false
        }
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        if(document.back_crop_image != nil) {
            NebuIA.client.uploadID(front: document.front_image!, back: document.back_image!) { data, error in
                if error != nil {
                    self.decodeResult(status: false)
                } else {
                    self.document.reset()
                    self.decodeResult(status: self.decodePayload(data: data!))
                }
            
            }
        } else {
            NebuIA.client.uploadID(front: document.front_image!) { data, error in
                if error != nil {
                    self.document.reset()
                    self.decodeResult(status: false)
                } else {
                    self.document.reset()
                    if(data != nil) {
                        self.decodeResult(status: self.decodePayload(data: data))
                    } else {
                        self.decodeResult(status: self.decodePayload(data: false))
                    }
                }
            }
        }
    }
    
    private func decodePayload(data: Any) -> Bool {
        if let result = data as? Dictionary<String, AnyObject> {
            let status = result["status"] as? Optional<Int>
            return status == 1
        }
        return false
    }
    
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
    
    public override var shouldAutorotate : Bool {
        return false
    }
    
    @IBAction private func complete() {
        self.dismiss(animated: true, completion: nil)
        if(status) {
            self.onCompleteBlock!()
        } else {
            self.onErrorBlock!()
        }
        
    }
    
}


