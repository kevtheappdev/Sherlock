//
//  AppearanceTableViewCell.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/5/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class AppearanceTableViewCell: UITableViewCell {

    @IBOutlet weak var gradientDisplay: UIGradientView!
    @IBOutlet weak var colorNameLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        gradientDisplay.staticColor = true
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    func set(Color colors: [CGColor], name: String){
        colorNameLabel.text = name
        gradientDisplay.set(colors: colors)
    }
    

}
