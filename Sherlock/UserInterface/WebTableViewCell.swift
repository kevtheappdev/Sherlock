//
//  WebTableViewCell.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/24/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import CoreData

class WebTableViewCell: UITableViewCell {
    @IBOutlet weak var siteTitleLabel: UILabel!
    @IBOutlet weak var siteUrlLabel: UILabel!
    weak var delegate: HistoryCellDelegate?
    var index: IndexPath?
    var data: NSManagedObject?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
    func set(data: WebHistoryEntry, index: IndexPath, delegate: HistoryCellDelegate? = nil){
        self.data = data
        self.siteTitleLabel.text = data.title
        self.siteUrlLabel.text = data.url
        self.index = index
        self.delegate = delegate
    }

    @IBAction func deleteButtonPressed(_ sender: Any) {
        self.delegate?.deleteButtonPressed(object: self.data)
    }
}
