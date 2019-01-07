//
//  Constants.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation
import UIKit
import WebKit

struct ApplicationConstants {
    static var _sherlockGradientColors: [CGColor] {
        get {
            return colors[currentColorKey]!
        }
    }
    static var currentColorKey = "blue"
    static let _numACResults = 3
    
    // userdefaults keys
    static let servicesKey = "services"
    static let allServicesKey = "allServices"
    static let magicOrderKey = "magicOrder"
    static let setupKey = "setupKey"
    static let autocompleteKey = "disabledAutocomplete"
    static let appearanceKey = "appearance"
    
    // colors
    static let colors = [
        "blue": [UIColor(red:0.50, green:0.76, blue:0.95, alpha:1.0).cgColor, UIColor(red:0.29, green:0.56, blue:0.89, alpha:1.0).cgColor] ,
        "red": [UIColor(red:0.96, green:0.32, blue:0.37, alpha:1.0).cgColor, UIColor(red:0.62, green:0.02, blue:0.11, alpha:1.0).cgColor],
        "orange": [UIColor(red:0.98, green:0.85, blue:0.38, alpha:1.0).cgColor, UIColor(red:0.97, green:0.42, blue:0.11, alpha:1.0).cgColor]
    ]

// TODO: replace key with enum vals
    static let autocomplete: [String: AutoCompleteParser] = [
        "google": GoogleAutoCompleteParser(type: .google),
        "duckduckgo": DDGAutoCompleteParser(),
        "wikipedia": WikipediaAutoCompleteParser(),
        "youtube": GoogleAutoCompleteParser(type: .youtube)
    ]

}

extension Notification.Name  {
    static let appearanceChanged = Notification.Name(rawValue: "appearanceChanged")
    static let servicesChanged = Notification.Name(rawValue: "servicesChanged")
}
