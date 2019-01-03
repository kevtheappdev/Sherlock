//
//  SherlockProgressBar.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/31/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class SherlockProgressBar: UIView {
    let progressLayer = CAGradientLayer()
    var progress: Float = 0.0 {
        didSet  {
            layoutSubviews()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        progressLayer.colors = ApplicationConstants._sherlockGradientColors
        layer.addSublayer(progressLayer)
    }
    
    override func layoutSubviews() {
        let viewWidth = bounds.width
        progressLayer.frame = CGRect(x: 0, y: 0, width: CGFloat(progress) * viewWidth, height: bounds.height)
    }
    
    
    
}
