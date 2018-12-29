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
    func process(results data: Data) -> [String] {
        guard let acResults = try? JSON(data: data).array else {
            return []
        }
        
        guard let results = acResults else {
            return []
        }
        
        var suggestions = Array<String>()
        for result in results {
            if let phrase = result.dictionary {
                if let suggestionObj = phrase["phrase"] {
                    if let suggestion = suggestionObj.string {
                        suggestions.append(suggestion)
                    }
                }
            }
        }
        
        return suggestions
    }
    
}
