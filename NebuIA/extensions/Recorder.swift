//
//  Recorder.swift
//  NebuIA
//
//  Created by Miguel Angel on 10/11/21.
//

import Foundation

@available(iOS 13.0, *)
extension VideoController {
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
    
    func stop(completion: @escaping (_ data: String?)->()) {
          guard isRecording else { return }
          isRecording = false
          videoWriter.finishWriting { [weak self] in
              self?.sessionAtSourceTime = nil
              guard let url = self?.videoWriter.outputURL else { return }
    
              completion(url.path)
          }
      }
}
