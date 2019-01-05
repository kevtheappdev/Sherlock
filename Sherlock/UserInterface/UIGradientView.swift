//
//  UIGradientView.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class UIGradientView: UIView {
    var staticColor = false

    override class var layerClass: AnyClass {
        return CAGradientLayer.self
    }
    
    init(frame: CGRect, andColors colors: [CGColor]) {
        super.init(frame: frame)
        set(colors: colors)
        NotificationCenter.default.addObserver(self, selector: #selector(UIGradientView.colorChanged), name: .appearanceChanged, object: nil)
    }
    
    
    @objc func colorChanged() {
        if staticColor {return}
        DispatchQueue.main.async {
            self.set(colors: ApplicationConstants._sherlockGradientColors)
        }
    }
    
    override func awakeFromNib() {
        NotificationCenter.default.addObserver(self, selector: #selector(UIGradientView.colorChanged), name: .appearanceChanged, object: nil)
    }
    
    public func set(colors: [CGColor]){
        let gradientLayer = layer as! CAGradientLayer
        gradientLayer.colors = colors
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }

}
