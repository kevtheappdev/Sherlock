//
//  SherlockServices.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/21/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation
import UIKit

enum sherlockServices: String {
    case google = "google"
    case facebook = "facebook"
    case wikipedia = "wikipedia"
    case duckduckgo = "duckduckgo"
    case none =  "none"
}

struct SherlockService {
    var name: String
    var searchText: String
    var searchURL: String
    var icon: UIImage
    // TODO: add support for autocomplete handler
    
    // Default values
    var weight: Int = 0
    
    init(name: String, searchText: String, searchURL: String, icon: UIImage) {
        self.name = name
        self.searchText = searchText
        self.searchURL = searchURL
        self.icon = icon
    }
}


