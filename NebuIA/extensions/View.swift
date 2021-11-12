//
//  View.swift
//  NebuIA
//
//  Created by Miguel Angel on 08/11/21.
//

import Foundation

extension CALayer {


    func addGradientBorder(colors:[UIColor],width:CGFloat = 1) {
            let gradientLayer = CAGradientLayer()
            gradientLayer.frame =  CGRect(origin: CGPoint.zero, size: self.bounds.size)
            gradientLayer.startPoint = CGPoint(x:0.0, y:0.0)
            gradientLayer.endPoint = CGPoint(x:1.0,y:1.0)
            gradientLayer.colors = colors.map({$0.cgColor})

            let shapeLayer = CAShapeLayer()
            shapeLayer.lineWidth = width
            shapeLayer.path = UIBezierPath(ovalIn: self.bounds).cgPath;
            shapeLayer.fillColor = nil
            shapeLayer.strokeColor = UIColor.red.cgColor
            gradientLayer.mask = shapeLayer

            self.addSublayer(gradientLayer)
        }
}
