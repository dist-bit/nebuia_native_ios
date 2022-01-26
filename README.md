nebuia

[![N|Nebula](https://i.ibb.co/DC46xJv/banner-min.png)](https://nebuia.com)

[![Build Status](https://travis-ci.org/joemccann/dillinger.svg?branch=master)](https://travis-ci.org/joemccann/dillinger)

### Introduction

NebuIA Native Core is library for nebuia services integration. NebuIA use platform native channels and run over native
languages Objective-C for IOS and Kotlin/Java for Android

NebuIA is an Deep Learning library and supports
  - Face Detection and auto crop
  - Proof of Live in real time
    - Darkened images
    - Office fluorescent lighting
    - Office with lighting turned off, illuminated only by natural sunlight
    - Supported attacks
      - Print
      - 2D Mask
      - 2 Replay
  - Document Detection in real time
    - Faster and best accuracy than conventional ID Detector (95%)
    - Support auto cropping
  - Proof of Address
    - Automatic extract address
  - Tipical OTP Verifications for Email and Phone Number SMS
    - Time-Based One-Time Password (TOTP)
    - HMAC-Based One-Time Password (HOTP)
    * [RFC 4226: "RFC 4226 HOTP: An HMAC-Based One-Time Password Algorithm"](https://www.ietf.org/rfc/rfc4226.txt)
    * [RFC 6238: "TOTP: Time-Based One-Time Password Algorithm"](https://tools.ietf.org/html/rfc6238)


### Requirements
 - iOS 12+

Add NebuIA pod to yout **Podfile**
```ruby
# Uncomment the next line to define a global platform for your project
platform :ios, '12.0'

target 'Demo' do
	# Comment the next line if you don't want to use dynamic frameworks
	use_frameworks!
	# Pods for Demo
	pod 'NebuIA', :git => 'https://github.com/dist-bit/nebuia_native_ios.git'
end
```

### Integration

Add your private and public key to **Info.plst**
```xml
<key>NebuIAPublicKey</key>
<string>23VDPJS-*****-*****-2BG1838</string>
<key>NebuIASecretKey</key>
<string>87b6da59-****-****-****-8b2e9700a068</string>
```

Sample Integration using swift and UIController
```swift
import UIKit
import NebuIA

class ViewController: UIViewController {
   
  	// init nebuIA class
    var nebuIA: ModuleNebuIA!
    @IBOutlet weak var ppreview: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
      	// pass current controller context to nebuia instance
        nebuIA = ModuleNebuIA(controller: self)
      	// set report if you already have one or create new (nebuIA.createReport)
        nebuIA.setReport(report: "611034***********ffc31e")
      	// set your temporal access code (read documentation for generation)
        nebuIA.setCode(code: "86996105")
    }
    
    @IBAction func createReport(_ sender: UIButton) {
      	// create new report and return string with report id
      	// all empty reports will be deleted after 12 hours of inactivity
        nebuIA.createReport() { report in
            print(report)
        }
    }

    @IBAction func callFaceScanner(_ sender: UIButton) {
      	// call proof of live screen
        nebuIA.faceProof() {
           
        }
    }
    
    @IBAction func callFingerScanner(_ sender: UIButton) {
      	// call fingerprint scanner and return 4 fingers images (index, middle, ring, little <= UIImage)
        nebuIA.fingerprintScanner() { index, middle, ring, little in
            DispatchQueue.main.async {
                // Get wsq file from fingerprint and return Data type file
                self.nebuIA.getFingerprintWSQ(image: index) { data in
                   // data is wsq file
                }
            }
        }
    }
    
    @IBAction func callIDScanner(_ sender: UIButton) {
      	// call id scanner for mexican id and passport
        nebuIA.idScanner() { 
        }
    }
    
    @IBAction func getIDImage(_ sender: UIButton) {
      	// get id document images by side (side = SIDE.front or SIDE.back)
      	// return image <= UIImage
        nebuIA.getDocumentIDSide(side: SIDE.front) { image in
            DispatchQueue.main.async {
                self.ppreview.image = image
            }
        }
    }
    
    @IBAction func getFaceImage(_ sender: UIButton) {
      	// get face image if the user performs the life test
      	// return image <= UIImage
        nebuIA.getDocumentFace() { image in
            DispatchQueue.main.async {
                self.ppreview.image = image
            }
        }
    }
    
    @IBAction func getReportSummary(_ sender: UIButton) {
      	// get all report summary (FaceMatch score, Liveness score, ID data and verifications)
        nebuIA.getReportIDSummary() { summary in
            print(summary)
        }
    }
}
```

### Notes

##### Temporal password

You need read documentation to generate this code

```swift
nebuIA.setCode(code: "86996105")
```



##### Report identifier

You can use existing report id.
```swift
nebuIA.setReport(report: "6110****************c31e")
```

or create new
```swift
nebuIA.createReport() { report in
            print(report)
}
```

##### C++ support

You need to add C++ framework under Build Phases

<a href="https://ibb.co/4mPwjp0"><img src="https://i.ibb.co/DV5P7Qj/Captura-de-Pantalla-2021-08-10-a-la-s-17-27-45.png" alt="Captura-de-Pantalla-2021-08-10-a-la-s-17-27-45" border="0"></a>

### Images







