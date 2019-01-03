//
//  WebNavBar.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/23/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class WebNavBar: UIView {
    // IBOutlets
    @IBOutlet weak var backButton: UIButton!
    @IBOutlet weak var forwardButton: UIButton!
    
    weak var delegate: WebNavBarDelegate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func awakeFromNib() {
        layer.borderColor = UIColor.gray.cgColor
        layer.borderWidth = 1
    }
    
    // pass button presses through delegate
    @IBAction func backButtonPressed(_ sender: Any) {
        delegate?.backButtonPressed()
    }
    
    @IBAction func forwardButtonPressed(_ sender: Any) {
        delegate?.forwardButtonPressed()
    }
    
    @IBAction func reloadButtonPressed(_ sender: Any) {
        delegate?.reloadButtonPressed()
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        delegate?.shareButtonPressed()
    }
}
