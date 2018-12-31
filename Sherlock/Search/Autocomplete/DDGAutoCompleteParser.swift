//
//  DDGAutoCompleteParser.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/28/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import SwiftyJSON

class DDGAutoCompleteParser: AutoCompleteParser {
    func process(results data: Data) -> [Autocomplete] {
        guard let acResults = try? JSON(data: data).array else {
            return []
        }
        
        guard let results = acResults else {
            return []
        }
        
        var suggestions = Array<Autocomplete>()
        for result in results {
            if let phrase = result.dictionary {
                if let suggestionObj = phrase["phrase"] {
                    if let suggestion = suggestionObj.string {
                        let ac  = Autocomplete(suggestion: suggestion, url: nil)
                        suggestions.append(ac)
                    }
                }
            }
        }
        
        if suggestions.count > 0 {
            SherlockServiceManager.main.add(weight: 2, toService: .duckduckgo)
        }
        
        return suggestions
    }
    
}
