//
//  SherlockServiceManager.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/21/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import SwiftyJSON

class SherlockServiceManager: NSObject {
    static let main = SherlockServiceManager()
    
    // ivars
    var services = Array<SherlockService>() // TODO: replace with custom data structure
    var delegate: SherlockServiceManagerDelegate? // TODO: Look into having multiple subscribers
    
    private override init() {
        super.init()
    }
    
    
    func load(){
        // Other setup
        loadServices()
    }
    
    private func loadServices(){
        // Load from UserDefaults and construct instances from json
        let defaults = UserDefaults.standard
        guard let userServices = defaults.array(forKey: "services") as? [String] else {return}
        
        guard let path = Bundle.main.path(forResource: "search_services", ofType: "json") else {return}
        
        var jsonString: String!
        jsonString = try! String(contentsOfFile: path, encoding: .utf8)

        
        guard let data = jsonString.data(using: .utf8) else {return}
        let serviceData = try! JSON(data: data).dictionary!
        
        
        for service in userServices {
            let serviceDetails = serviceData[service]!.dictionary
            if serviceDetails != nil {
                let name = service
                let searchName = serviceDetails!["searchText"]!.string!
                let searchURL = serviceDetails!["searchURL"]!.string!
                let iconPath = serviceDetails!["icon"]!.string!
                let icon = UIImage(named: iconPath)!
                
                var serviceObj = SherlockService(name: name, searchText: searchName, searchURL: searchURL, icon: icon)
                if let config = serviceDetails!["config"]?.dictionary {
                    serviceObj.config = self.parse(config: config)
                }
                
                if let acURL = serviceDetails!["acURL"]?.string {
                    if let acParser = autocomplete[name] {
                        serviceObj.automcompleteHandler = AutoCompleteRequester(url: acURL, autocomplete: acParser)
                    }
                }
                
                
                self.services.append(serviceObj)
            }
        }
        
    }
    
    
}

// MARK: API Methods
extension SherlockServiceManager {
    // temp function for current state of datastructures
    func getServices() -> [SherlockService] // TODO: callers pass in reference to conforming delegate method
    {
        return self.services
    }
    
    func beginAutocomplete(forQuery query: String){
        for service in self.services {
            service.automcompleteHandler?.makeRequest(withQuery: query) {(error) in
                if error == nil {
                    self.delegate?.autocompleteResultsChanged(self.services)
                }
            }
        }
    }
    
    func clearAutocomplete(){
        for service in self.services {
            service.automcompleteHandler?.suggestions.removeAll(keepingCapacity: true)
        }
        
        self.delegate?.autocompleteResultsChanged(self.services)
    }
    
    func cancelAutocomplete(){
        for service in self.services {
            service.automcompleteHandler?.cancel()
        }
    }
}

// MARK: Configuration parsing
extension SherlockServiceManager {
    // configure SherlockServiceConfig objectr from the JSON
    func parse(config configDict: Dictionary<String, JSON>) -> SherlockServiceConfig {
        var serviceConfig = SherlockServiceConfig()
        
        // resultsPage options
        if let resultsConfig = configDict["resultsPage"]?.dictionary {
            if let jsEnabled = resultsConfig["javascriptEnabled"]?.bool {
                serviceConfig.resultsJavascriptEnabled = jsEnabled
            }
        }
        
        return serviceConfig
    }
}
