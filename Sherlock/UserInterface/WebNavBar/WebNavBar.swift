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
    
    // pass button presses through delegate
    @IBAction func backButtonPressed(_ sender: Any) {
        self.delegate?.backButtonPressed()
    }
    
    @IBAction func forwardButtonPressed(_ sender: Any) {
        self.delegate?.forwardButtonPressed()
    }
    
    @IBAction func reloadButtonPressed(_ sender: Any) {
        self.delegate?.reloadButtonPressed()
    }
    
    @IBAction func shareButtonPressed(_ sender: Any) {
        self.delegate?.shareButtonPressed()
    }
}
