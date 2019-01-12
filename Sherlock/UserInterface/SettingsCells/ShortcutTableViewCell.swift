//
//  ShortcutTableViewCell.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/12/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class ShortcutTableViewCell: UITableViewCell {
    @IBOutlet weak var shortcutText: UILabel!
    @IBOutlet weak var servicesLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    func set(Shortcut shortcut: SherlockShortcut){
        shortcutText.text = shortcut.activationText
        
        var serviceNames = [String]()
        let mapping = SherlockServiceManager.main.servicesMapping
        for serviceType in shortcut.services {
            serviceNames.append(mapping[serviceType]!.searchText)
        }
        
        servicesLabel.text = serviceNames.joined(separator: ", ")
    }

}
