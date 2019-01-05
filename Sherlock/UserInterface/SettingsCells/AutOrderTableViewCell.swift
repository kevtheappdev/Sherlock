//
//  AutOrderTableViewCell.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/4/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class AutOrderTableViewCell: UITableViewCell {
    @IBOutlet weak var autoOrderSwitch: UISwitch!
    
    @IBAction func switchFlipped(_ sender: Any) {
        SherlockSettingsManager.main.magicOrderingOn = autoOrderSwitch.isOn
    }
    
    override func awakeFromNib() {
        self.autoOrderSwitch.isOn = SherlockSettingsManager.main.magicOrderingOn
    }
    
}
