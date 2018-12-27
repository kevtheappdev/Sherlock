//
//  LoadCoverView.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/26/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class LoadingIndicator: UIView {
    let loadLayer =  CAShapeLayer()
    var animationStarted = false
    
    override func layoutSubviews() {
        let size = self.frame.size.width > self.frame.size.height ? self.frame.size.height : self.frame.size.width
        let path = UIBezierPath(arcCenter: CGPoint(x: size / 2, y: size / 2), radius: size / 2, startAngle: 0, endAngle: CGFloat.pi, clockwise: true)
        self.loadLayer.path = path.cgPath
        self.loadLayer.strokeColor = UIColor.lightGray.cgColor
        self.loadLayer.lineWidth = 10
        self.loadLayer.fillColor = UIColor.clear.cgColor
        self.loadLayer.lineCap = CAShapeLayerLineCap.round
        self.loadLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        self.layer.addSublayer(self.loadLayer)
    }
    
    func startLoadAnimation(){
        if !animationStarted  {
            let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
            rotateAnimation.fromValue = 0.0
            rotateAnimation.toValue =  CGFloat(Float.pi * 2.0)
            rotateAnimation.duration = 1.0
            rotateAnimation.repeatCount = .greatestFiniteMagnitude
            self.animationStarted = true
            self.layer.add(rotateAnimation, forKey: nil)
        }
    }
}
