//
//  Device.swift
//  NebuIA
//
//  Created by Miguel on 24/06/21.
//

extension UIDevice {
    /// Returns `true` if the device has a notch
    var hasNotch: Bool {
        guard #available(iOS 11.0, *), let topPadding = UIApplication.shared.keyWindow?.safeAreaInsets.top, topPadding > 24 else {
                return false
            }
            return true
    }
}
