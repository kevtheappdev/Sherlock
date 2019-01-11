//
//  UserServiceTableViewCell.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/4/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class UserServiceTableViewCell: UITableViewCell {

    
    @IBOutlet weak var serviceTitle: UILabel!
    @IBOutlet weak var iconView: UIImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func set(Service service: SherlockService){
        iconView.image = service.icon
        serviceTitle.text = service.searchText
    }

}
