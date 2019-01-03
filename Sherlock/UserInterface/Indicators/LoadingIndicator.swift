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
    
    override func layoutSubviews() {
        let size = frame.size.width > frame.size.height ? frame.size.height : frame.size.width
        let path = UIBezierPath(arcCenter: CGPoint(x: size / 2, y: size / 2), radius: size / 2, startAngle: 0, endAngle: CGFloat.pi, clockwise: true)
        loadLayer.path = path.cgPath
        loadLayer.strokeColor = UIColor.lightGray.cgColor
        loadLayer.lineWidth = 10
        loadLayer.fillColor = UIColor.clear.cgColor
        loadLayer.lineCap = CAShapeLayerLineCap.round
        loadLayer.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        layer.addSublayer(loadLayer)
    }
    
    func startLoadAnimation(){
        let rotateAnimation = CABasicAnimation(keyPath: "transform.rotation")
        rotateAnimation.fromValue = 0.0
        rotateAnimation.toValue =  CGFloat(Float.pi * 2.0)
        rotateAnimation.duration = 1.0
        rotateAnimation.repeatCount = .greatestFiniteMagnitude
        layer.add(rotateAnimation, forKey: nil)
    }
}
