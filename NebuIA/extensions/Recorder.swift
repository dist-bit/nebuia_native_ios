//
//  Recorder.swift
//  NebuIA
//
//  Created by Miguel Angel on 10/11/21.
//

import Foundation

extension SignerController {
    func canWrite() -> Bool {
        return isRecording
        && videoWriter != nil
        && videoWriter.status == .writing
    }
    
    func start() {
        guard !isRecording else { return }
        isRecording = true
        sessionAtSourceTime = nil
        videoWriter.startWriting()
    }
    
    func stop() {
          guard isRecording else { return }
          isRecording = false
          videoWriter.finishWriting { [weak self] in
              self?.sessionAtSourceTime = nil
              guard let url = self?.videoWriter.outputURL else { return }
              
              print(url)
              //let asset = AVURLAsset(url: url)
              //Do whatever you want with your asset here
          }
      }
}
