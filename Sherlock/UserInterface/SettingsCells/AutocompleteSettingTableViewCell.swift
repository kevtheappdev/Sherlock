//
//  AutocompleteSettingTableViewCell.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/5/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class AutocompleteSettingTableViewCell: UITableViewCell {
    @IBOutlet weak var onSwitch: UISwitch!
    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var serviceIcon: UIImageView!
    
    var service: SherlockService!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        // Configure the view for the selected state
    }
    
    func set(Service service: SherlockService, autocompleteEnabled: Bool){
        onSwitch.isOn = autocompleteEnabled
        serviceIcon.image = service.icon
        serviceLabel.text = service.searchText.capitalized
        self.service = service
    }

    @IBAction func switchFlipped(_ sender: Any) {
        if onSwitch.isOn {
            SherlockSettingsManager.main.removeDisabledAutocomplete(Service: service)
        } else {
            SherlockSettingsManager.main.addDisabledAutocomplete(Service: service)
        }
    }
    
}
