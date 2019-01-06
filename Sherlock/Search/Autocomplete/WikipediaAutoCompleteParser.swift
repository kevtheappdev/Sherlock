//
//  WikipediaAutoCompleteParser.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/29/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import SwiftyJSON

class WikipediaAutoCompleteParser: AutoCompleteParser {
    var weightUpdated = false
    var weight = 5
    
    func clear() {
        weightUpdated = true
    }
    
    func process(results data: Data) -> [Autocomplete] {
        guard
            let acResult = try? JSON(data: data),
            let results = acResult.array,
            let titleArr = results[1].array,
            let descriptionResult = results[2].array,
            let urlArr = results[3].array
        else {
            resetWeight()
            return []
        }
        
        
        

        if titleArr.count == 0 {
            resetWeight()
            return []
        }
        
        
        if urlArr.count == 0 {
            resetWeight()
            return []
        }
        
        guard
            let title = titleArr[0].string,
            let urlStr = urlArr[0].string,
            let descripStr = descriptionResult[0].string
        else {
            resetWeight()
            return []
        }
        
        // make sure we only autocomplete sure matches
        if descripStr.contains("may refer to:") {
            resetWeight()
            return []
        }
        
        guard let url = URL(string: urlStr) else {
            resetWeight()
            return []
        }
        
        
        if !weightUpdated {
            SherlockServiceManager.main.add(weight: 3, toService: .wikipedia)
            weightUpdated = true
        }
        return [Autocomplete(suggestion: title, url: url)]
    }
    
    private func resetWeight(){
        SherlockServiceManager.main.subtract(weight: weight, forService: .wikipedia)
    }

}
