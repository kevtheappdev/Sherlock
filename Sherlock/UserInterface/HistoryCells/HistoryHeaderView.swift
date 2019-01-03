//
//  HistoryHeaderView.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/31/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class HistoryHeaderView: UIView {

    @IBOutlet weak var dateStrLabel: UILabel!
    weak var delegate: HistorySectionDelegate?
    
    var dateStr: String {
        get {
            guard let dateStrInLabel = dateStrLabel.text else {
                return ""
            }
            
            return dateStrInLabel
        }
        
        set {
            dateStrLabel.text = newValue
        }
    }
    
    @IBAction func deleteButtonPressed(_ sender: Any) {
        delegate?.deleteButtonPressed(dateStr: dateStr)
    }
    
}
