//
//  PreviewDocumentID.swift
//  NebuIA
//
//  Created by Miguel on 27/06/21.
//

import UIKit
import AVFoundation
import Cartography

public class PreviewDocumentIDController: UIViewController {
    
    var document: Document!
    private var content_view: UIView!
    
    private var title_label: UILabel!
    private var summary_label: UILabel!
    
    private var image_preview: UIImageView!
    private var nebuia_logo: UIImageView!
    
    private var continue_id: UIButton!
    private var close: UIButton!
    private var retake: UIButton!
    
    var onDismmisBlock : (() -> Void)?
    var onContinueBlock : (() -> Void)?
    var onCompleteBlock : (() -> Void)?
    
    @IBAction func goBack(_ sender: UIButton) {
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func continueID(_ sender: UIButton) {
        if(document.isComplete()) {
            onCompleteBlock!()
            self.dismiss(animated: true, completion: nil)
        } else {
            document.document_side = Side.BACK
            onContinueBlock!()
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    private func buildContinueButton() {
        continue_id = UIButton(type: .system)
        
        continue_id.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        continue_id.tintColor = UIColor.blue
        continue_id.layer.cornerRadius =  continue_id.frame.size.width/2
        continue_id.clipsToBounds = true
        continue_id.contentMode = UIView.ContentMode.scaleToFill
        
        continue_id.backgroundColor = UIColor(rgb: 0xa6cc3b)
        continue_id.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let btnImage = UIImage(systemName: "checkmark")
            continue_id.setImage(btnImage , for: .normal)
            continue_id.tintColor = .white
        }
        
        continue_id.addTarget(self, action: #selector(continueID(_:)), for: .touchUpInside)
    }
    
    private func buildRetakeButton() {
        retake = UIButton(type: .system)
        
        retake.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        retake.tintColor = UIColor.blue
        retake.contentMode = UIView.ContentMode.scaleToFill
        
        retake.layer.cornerRadius =  retake.frame.size.width/2
        retake.clipsToBounds = true
        retake.contentMode = UIView.ContentMode.scaleToFill
        
        retake.backgroundColor =  UIColor(rgb: 0x2d2d2d)
        retake.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let btnImage = UIImage(systemName: "arrow.triangle.2.circlepath")
            retake.setImage(btnImage , for: .normal)
            retake.tintColor = UIColor(rgb: 0x6a6a6a)
        }
        
      
        retake.translatesAutoresizingMaskIntoConstraints = false
        retake.addTarget(self, action: #selector(goBack(_:)), for: .touchUpInside)
    }
    
    private func buildCloseButton() {
        close = UIButton(type: .system)
        
        close.frame = CGRect(x: 0, y: 0, width: 50, height: 50)
        close.tintColor = UIColor.blue
        close.contentMode = UIView.ContentMode.scaleToFill
        
        close.layer.cornerRadius =  close.frame.size.width/2
        close.clipsToBounds = true
        close.contentMode = UIView.ContentMode.scaleToFill
        
        close.backgroundColor =  UIColor(rgb: 0x2d2d2d)
        close.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 13.0, *) {
            let btnImage = UIImage(systemName: "xmark")
            close.setImage(btnImage , for: .normal)
            close.tintColor = UIColor(rgb: 0x6a6a6a)
        }
        
      
        close.translatesAutoresizingMaskIntoConstraints = false
        close.addTarget(self, action: #selector(goBack(_:)), for: .touchUpInside)
    }
    
    private func buildTitleLabel() {
        title_label = UILabel(frame: UIScreen.main.bounds)
        title_label.textAlignment = .center
        title_label.numberOfLines = 1
        title_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 16), weight: .bold)
        title_label.minimumScaleFactor = 10/UIFont.labelFontSize
        title_label.adjustsFontSizeToFitWidth = true
        title_label.textColor = .white
        title_label.text = "Revisa tu documento"
    }
    
    private func buildSummaryLabel() {
        summary_label = UILabel(frame: UIScreen.main.bounds)
        summary_label.textAlignment = .center
        summary_label.numberOfLines = 2
        summary_label.minimumScaleFactor = 10/UIFont.labelFontSize
        summary_label.adjustsFontSizeToFitWidth = true
        summary_label.textColor = .white
        summary_label.font = UIFont.systemFont(ofSize: dynamicFontSizeForIphone(fontSize: 10), weight: .regular)
        summary_label.text = "Revisa que el texto de tu documento se vea completamente además de que sea claro y legible"
    }
    
    private func buildLogoBottom() {
        let logo = UIImage(named: "nebuia_white.png")
        nebuia_logo = UIImageView(image: logo!)
    }
    
    private func buildImagePreview() {
        if(document.document_side == Side.FRONT) {
            image_preview = UIImageView(image: document!.front_crop_image)
        } else {
            image_preview = UIImageView(image: document!.back_crop_image)
        }
        image_preview.layer.cornerRadius =  10
        image_preview.clipsToBounds = true
    }
    
    
    func constraintsInit() {
        let botom: CGFloat = UIDevice.current.hasNotch ? 50 : 0
        constrain(title_label, content_view, summary_label, nebuia_logo, image_preview, continue_id, retake, close)
        { title_label, content_view, summary_label, nebuia_logo, image_preview, continue_id, retake, close in
            
            image_preview.top == content_view.superview!.top + 80
            image_preview.centerX == content_view.centerX
            image_preview.height ==  content_view.superview!.height / 4
            image_preview.width == content_view.superview!.width - 100
            
            title_label.centerX == content_view.centerX
            title_label.top == image_preview.superview!.top + 40
            
            summary_label.centerX == content_view.centerX
            summary_label.width == image_preview.width
            
            continue_id.centerX == content_view.centerX
            continue_id.width == 50
            continue_id.height == 50
            
            close.left == content_view.superview!.left + 55
            close.top == continue_id.top
            close.width == 50
            close.height == 50
            
            retake.right == content_view.superview!.right - 55
            retake.top == continue_id.top
            retake.width == 50
            retake.height == 50
            
            nebuia_logo.centerX == content_view.centerX
            nebuia_logo.width == content_view.superview!.width / 4.6
            nebuia_logo.height == 15
            nebuia_logo.centerY == content_view.superview!.bottom - botom - 50
            distribute(by: 55, vertically: summary_label, continue_id, nebuia_logo)
        }
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = UIColor(rgb: 0x1c1c1c)
        
        // camera
        content_view = UIView(frame: UIScreen.main.bounds)
        
        // set up title layer
        buildTitleLabel()
        content_view.addSubview(title_label)
        
        // set up summary
        buildSummaryLabel()
        content_view.addSubview(summary_label)
        
        // set up continue button
        buildContinueButton()
        content_view.addSubview(continue_id)
        
        // set up continue button
        buildCloseButton()
        content_view.addSubview(close)
        
        // set up retake button
        buildRetakeButton()
        content_view.addSubview(retake)
        
        // set up logo
        buildLogoBottom()
        content_view.addSubview(nebuia_logo)
        
        // build preview document
        buildImagePreview()
        content_view.addSubview(image_preview)
        
        let root_view = UIView(frame: UIScreen.main.bounds)
        root_view.addSubview(content_view)
        
        self.view.addSubview(root_view)
        constraintsInit()
    }
    
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }
    
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        onDismmisBlock!()
    }
    
    
    public override var shouldAutorotate : Bool {
        return false
    }
    
    
    private func back() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            self.dismiss(animated: true, completion: nil)
        }
    }
}

