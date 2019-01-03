//
//  UIGradientView.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class UIGradientView: UIView {

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    init(frame: CGRect, andColors colors: [CGColor]) {
        super.init(frame: frame)
        set(colors: colors)
    }
    
    public func set(colors: [CGColor]){
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = colors
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
