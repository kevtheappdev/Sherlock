//
//  GoogleAutoCompleteParser.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/28/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import SwiftyJSON

class GoogleAutoCompleteParser: AutoCompleteParser {
    var weightChanged = false
    var weight = 2
    var type: serviceType
    
    init(type: serviceType){
        self.type = type
    }
    
    func clear() {
        weightChanged = false
    }
    
    
    func process(results data: Data) -> [Autocomplete] {
        // TODO: Insert logging for these failure points
        guard let acResults = try? JSON(data: data).array else {
            return []
        }
        guard let suggestions = acResults?[1].array else {
            return []
        }
        
        var results = [Autocomplete]()
        for suggestion in suggestions {
            guard let suggestionStr = suggestion.string else {
                continue
            }
            let ac = Autocomplete(suggestion: suggestionStr, url: nil)
            results.append(ac)
        }
        
        if  results.count > 0 && !weightChanged {
            SherlockServiceManager.main.add(weight: weight, toService: type)
            weightChanged = true
        } else if results.count == 0 {
            SherlockServiceManager.main.subtract(weight: weight, forService: type)
            weightChanged = false
        }
        
        return results
    }
}
