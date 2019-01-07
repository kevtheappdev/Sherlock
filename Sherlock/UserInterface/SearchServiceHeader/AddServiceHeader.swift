//
//  AddServiceHeader.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/5/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class AddServiceHeader: UIView {

    @IBOutlet weak var addIcon: UIGradientView!
    var delegate: SearchServiceHeaderDelegate?
    
    override func awakeFromNib() {
        addIcon.layer.cornerRadius = 22.5
        addIcon.layer.masksToBounds = true
        addIcon.set(colors: ApplicationConstants._sherlockGradientColors)
    }

    @IBAction func headerTapped(_ sender: Any) {
        delegate?.tapped(index: tag)
    }
    
}
