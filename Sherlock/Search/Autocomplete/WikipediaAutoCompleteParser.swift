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
    
    func process(results data: Data) -> [Autocomplete] {
        guard let acResult = try? JSON(data: data) else {
            return []
        }
        
        guard let results = acResult.array  else  {
            return []
        }
        
        guard let titleArr = results[1].array else {
            return []
        }
        
        if titleArr.count == 0 {
            return []
        }
        
        guard let title = titleArr[0].string else {
            return []
        }
        
        guard let urlArr = results[3].array else {
             return []
        }
        
        if urlArr.count == 0 {
            return []
        }
        
        guard let urlStr = urlArr[0].string else {
            return []
        }
        
        guard let url = URL(string: urlStr) else {
            return []
        }
        
        
        return [Autocomplete(suggestion: title, url: url)]
    }

}
