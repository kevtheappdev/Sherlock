//
//  CoverView.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/26/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class CoverView: UIView {
    let loadingIndicator = LoadingIndicator()

    init(){
        super.init(frame: CGRect.zero)
        loadingIndicator.frame = CGRect(origin: CGPoint.zero, size: CGSize(width: 100, height: 100))
        addSubview(loadingIndicator)
    }
    
    override func layoutSubviews() {
        loadingIndicator.center = CGPoint(x: frame.width / 2, y: frame.height / 2)
    }
 
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    

}
