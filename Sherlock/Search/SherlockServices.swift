//
//  SherlockServices.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/21/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation
import UIKit

enum serviceType: String {
    case google = "google"
    case facebook = "facebook"
    case wikipedia = "wikipedia"
    case duckduckgo = "duckduckgo"
    case none =  "none"
}

struct SherlockService {
    var type: serviceType
    var searchText: String
    var searchURL: String
    var icon: UIImage
    // TODO: add support for autocomplete handler
    
    // Default values
    var weight: Int = 0
    
    init(name: String, searchText: String, searchURL: String, icon: UIImage) {
        self.type = serviceType(rawValue: name)!  // TODO: error check this
        self.searchText = searchText
        self.searchURL = searchURL
        self.icon = icon
    }
}


