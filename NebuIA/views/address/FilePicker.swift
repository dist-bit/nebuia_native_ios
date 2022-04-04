//
//  FilePicker.swift
//  NebuIA
//
//  Created by Miguel Angel on 03/04/22.
//

@available(iOS 13.0, *)
extension UIViewController: UIDocumentPickerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
  
    private func dissmiss() {
        DispatchQueue.main.async {
            NebuIA.imagePicker.dismiss(animated: true, completion: nil)
        }
    }
    
    public func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]){
        NebuIA.imagePicker.dismiss(animated: true, completion: nil)
        guard let selectedImage = info[.originalImage] as? UIImage else {
            print("Image not found!")
            return
        }
        
        let address: Address = Address()
        address.setImage(data: selectedImage.imageResize(scaledToWidth: CGFloat(870)))
        let preview = AddressPreviewController()
        preview.address = address
        preview.dismiss = dissmiss
        preview.onCompleteBlock = NebuIA.completionAddress
        preview.onErrorBlock = NebuIA.errorAddress
        self.present(preview, animated: true, completion: nil)
    }
    
    public func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        guard let firstFileURL = urls.first else {
            return
        }
        
        let isSecuredURL = (firstFileURL.startAccessingSecurityScopedResource() == true)
        
        var blockSuccess = false
        var outputFileURL: URL? = nil
    
        let coordinator = NSFileCoordinator()
        var error: NSError? = nil
        coordinator.coordinate(readingItemAt: firstFileURL, options: [], error: &error) { (externalFileURL) -> Void in
            var tempURL = URL(fileURLWithPath: NSTemporaryDirectory())
            tempURL.appendPathComponent(externalFileURL.lastPathComponent)
            
            // Attempt copy
            do {
                if FileManager.default.fileExists(atPath: tempURL.path) {
                    try FileManager.default.removeItem(atPath: tempURL.path)
                }
                
                try FileManager.default.moveItem(atPath: externalFileURL.path, toPath: tempURL.path)
                
                blockSuccess = true
                outputFileURL = tempURL
            }
            catch {
                blockSuccess = false
            }
            
        }
        navigationController?.dismiss(animated: true, completion: nil)
        
        if error != nil {
            return
        }
        if !blockSuccess {
            return
        }
        
        if (isSecuredURL) {
            firstFileURL.stopAccessingSecurityScopedResource()
        }
        
        if let out = outputFileURL {
            let address: Address = Address()
            address.setPDF(data: out)
            let preview = AddressPreviewController()
            preview.address = address
            preview.onCompleteBlock = NebuIA.completionAddress
            preview.onErrorBlock = NebuIA.errorAddress
            self.present(preview, animated: true, completion: nil)
            
        }
    }
    
    
    public func documentMenu(didPickDocumentPicker documentPicker: UIDocumentPickerViewController) {
        documentPicker.delegate = self
        present(documentPicker, animated: true, completion: nil)
    }
    
    
    public func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        dismiss(animated: true, completion: nil)
    }
}
