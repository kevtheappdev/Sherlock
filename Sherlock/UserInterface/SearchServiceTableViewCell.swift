//
//  SearchServiceTableViewCell.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/21/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit


class SearchServiceTableViewCell: UITableViewCell {
    // outlets
    @IBOutlet weak var serviceLabel: UILabel!
    @IBOutlet weak var serviceIcon: UIImageView!
    
    var type: sherlockServices!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func configureCell(withService service: SherlockService){
        self.serviceLabel.text = service.searchText
        self.serviceIcon.image = service.icon
        
        self.type = sherlockServices(rawValue: service.name)
    }
    
}
