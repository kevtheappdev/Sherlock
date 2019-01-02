//
//  WebTitleBar.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/23/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class WebTitleBar: UIView {
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var urlLabel: UILabel!
    @IBOutlet weak var progressBar: SherlockProgressBar!
    weak var delegate: WebTitleBarDelegate?
    
    override func awakeFromNib() {
        self.layer.borderColor = UIColor.gray.cgColor
        self.layer.borderWidth = 1.0
    }
    
    func set(title: String, url urlStr: String){
        self.titleLabel.text = title
        self.urlLabel.text = urlStr
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        self.delegate?.titleBackButtonPressed()
    }
    // TODO: functinality for copying URL, view full URL, overall back button, progress bar
}
