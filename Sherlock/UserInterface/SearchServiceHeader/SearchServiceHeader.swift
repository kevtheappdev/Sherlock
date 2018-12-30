//
//  SearchServiceHeader.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/29/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class SearchServiceHeader: UIView {
    @IBOutlet weak var serviceImage: UIImageView!
    @IBOutlet weak var serviceText: UILabel!
    weak var delegate: SearchServiceHeaderDelegate?
    
    func set(service: SherlockService){
        self.serviceImage.image = service.icon
        self.serviceText.text = service.searchText
    }
    
    @IBAction func headerTapped(_ sender: Any) {
        self.delegate?.tapped(index: self.tag)
    }
}
