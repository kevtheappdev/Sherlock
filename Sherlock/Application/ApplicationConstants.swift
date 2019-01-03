//
//  Constants.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation
import UIKit

struct ApplicationConstants {
    static let _sherlockGradientColors = [UIColor(red:0.50, green:0.76, blue:0.95, alpha:1.0).cgColor, UIColor(red:0.29, green:0.56, blue:0.89, alpha:1.0).cgColor]
    static let _numACResults = 3

// TODO: replace key with enum vals
    static let autocomplete: [String: AutoCompleteParser] = [
        "google": GoogleAutoCompleteParser(),
        "duckduckgo": DDGAutoCompleteParser(),
        "wikipedia": WikipediaAutoCompleteParser()
    ]

}


