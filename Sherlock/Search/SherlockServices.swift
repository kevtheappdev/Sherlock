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
    case twitter = "twitter"
    case linkedin = "linkedin"
    case applemaps = "applemaps"
    case imdb = "imdb"
    case youtube = "youtube"
    case none =  "none"
}

class SherlockService {
    var type: serviceType
    var searchText: String
    var searchURL: String
    var icon: UIImage
    var config = SherlockServiceConfig()
    var automcompleteHandler: AutoCompleteRequester?
    var categories: [NSLinguisticTag:Int] = [:]
    var categoriesApplied: [Int] = []
    var ogIndex = 0
    
    // Default values
    var weight: Int = 0
    
    init(name: String, searchText: String, searchURL: String, icon: UIImage) {
        self.type = serviceType(rawValue: name)!
        self.searchText = searchText
        self.searchURL = searchURL
        self.icon = icon
    }
}


struct SherlockServiceConfig {
    var resultsJavascriptEnabled = false
    var openURLScheme = false
    var allowedUrls: [String] = []
    var jsString: String?
}


