//
//  OmniBar.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class OmniBar: UIGradientView {

    @IBOutlet weak var searchField: UITextField!
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        set(colors: _sherlockGradientColors)
    }
    
    // MARK: User Interface Actions
    @IBAction func settingsButtonPressed(_ sender: Any) {
        
    }
    
    @IBAction func historyButtonPressed(_ sender: Any) {
    }
}
