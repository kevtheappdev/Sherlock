//
//  AutoCompleteRequester.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/27/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class AutoCompleteRequester: NSObject {
    typealias Completion = (Error?) -> Void
    
    var url: String
    var autoCompleteParser: AutoCompleteParser
    var task: URLSessionDataTask?
    var suggestions: [Autocomplete] = []
    
    init(url: String, autocomplete: AutoCompleteParser) {
        self.url = url
        self.autoCompleteParser = autocomplete
        super.init()
    }
    
    func makeRequest(withQuery query: String, completion: @escaping Completion){
        guard let param = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed) else {
            return
        }
        let fullURLStr = self.url.replacingOccurrences(of: "{query}", with: param)
        guard let url = URL(string: fullURLStr) else {return}
        self.task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let data = data {
                let suggestions = self.autoCompleteParser.process(results: data)
                self.suggestions = suggestions
            }
            
            DispatchQueue.main.async {
                completion(error)
            }
        }
        self.task?.resume()
    }
    
    func cancel(){
        self.task?.cancel()
    }
    
    func clear(){
        self.suggestions.removeAll()
        self.autoCompleteParser.clear()
    }
    
}
