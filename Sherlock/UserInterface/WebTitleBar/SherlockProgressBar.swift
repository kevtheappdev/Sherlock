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
            self.layoutSubviews()
        }
    }

    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.progressLayer.colors = ApplicationConstants._sherlockGradientColors
        self.layer.addSublayer(self.progressLayer)
    }
    
    override func layoutSubviews() {
        let viewWidth = self.bounds.width
        self.progressLayer.frame = CGRect(x: 0, y: 0, width: CGFloat(progress) * viewWidth, height: self.bounds.height)
    }
    
    
    
}
