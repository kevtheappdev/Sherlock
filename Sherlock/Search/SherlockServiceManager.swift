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
    private var timer: Timer!
    private var needsUpdate = false
    private var ogOrder = Dictionary<serviceType, Int>() // Maps service types with their original index
    private var servicesMapping = Dictionary<serviceType, SherlockService>()
    
    // ivars
    var services = Array<SherlockService>() // TODO: replace with custom data structure
    var delegate: SherlockServiceManagerDelegate? // TODO: Look into having multiple subscribers

    
    private override init() {
        super.init()
        self.timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(SherlockServiceManager.update(_:)), userInfo: nil, repeats: true)
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
        
        var index = 0
        for service in userServices {
            let serviceDetails = serviceData[service]!.dictionary
            if serviceDetails != nil {
                let name = service
                let searchName = serviceDetails!["searchText"]!.string!
                let searchURL = serviceDetails!["searchURL"]!.string!
                let iconPath = serviceDetails!["icon"]!.string!
                let icon = UIImage(named: iconPath)!
                
                let serviceObj = SherlockService(name: name, searchText: searchName, searchURL: searchURL, icon: icon)
                if let config = serviceDetails!["config"]?.dictionary {
                    serviceObj.config = self.parse(config: config)
                }
                
                // parse out categories if they exist
                // TODO: move this into a utility function
                if let categories = serviceDetails!["categories"]?.dictionary {
                    var serviceCategories: [NSLinguisticTag:Int] = [:]
                    for (category, weight) in categories {
                        guard let weight = weight.int else {
                            continue
                        }
                        
                        
                        let tag = NSLinguisticTag(rawValue: category)
                        serviceCategories[tag] = weight
                    }
                    serviceObj.categories = serviceCategories
                }
                
                if let acURL = serviceDetails!["acURL"]?.string {
                    if let acParser = autocomplete[name] {
                        serviceObj.automcompleteHandler = AutoCompleteRequester(url: acURL, autocomplete: acParser)
                    }
                }
                
                self.ogOrder[serviceObj.type] = index // preserve original indexing
                index += 1
                
                self.services.append(serviceObj)
            }
        }
        
    }
    
    @objc func update(_ sender: Any){
        if self.needsUpdate {
            self.delegate?.autocompleteResultsChanged(self.services)
            self.needsUpdate = false
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
                    self.needsUpdate = true
                }
            }
        }
    }
    
    func clearAutocomplete(){
        for service in self.services {
            service.automcompleteHandler?.suggestions.removeAll(keepingCapacity: true)
        }
        
        self.delegate?.autocompleteCleared()
        self.needsUpdate = true
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

// MARK: Linguistic analysis
extension SherlockServiceManager {
    func categorize(withQuery query: String){
        self.clearRankings() //  fresh start on rankings
        
        let query = query.capitalized
        let schemes = NSLinguisticTagger.availableTagSchemes(forLanguage: "en")
        let tagger = NSLinguisticTagger(tagSchemes: schemes, options: 0)
        tagger.string = query
        let range = NSRange(location: 0, length: query.count)
        tagger.setOrthography(NSOrthography.defaultOrthography(forLanguage: "en"), range: range)
        let options: NSLinguisticTagger.Options = [.omitPunctuation, .omitWhitespace, .joinNames]
        let tags: [NSLinguisticTag] = [.personalName, .placeName, .organizationName]
        tagger.enumerateTags(in: range, unit: .word, scheme: .nameType, options: options) { tag, tokenRange, stop in
            if let tag = tag, tags.contains(tag) {
                let serviceWeights = self.servicesFor(tag: tag)
                for (service, serviceWeight) in serviceWeights {
                    self.add(weight: serviceWeight, toService: service)
                }
            }
        }
    }
    
    func servicesFor(tag: NSLinguisticTag) -> [serviceType: Int]{
        var services: [serviceType: Int] = [:]
        for service in self.services {
            if service.categories[tag] != nil {
                services[service.type] = service.categories[tag]
            }
        }
        
        return services
    }
}

// MARK: Automatic ordering
extension SherlockServiceManager {
    func add(weight: Int, toServices selectServices: [serviceType]){  // maybe redundant?
        let serviceSet = Set<serviceType>(selectServices)
        for service in self.services {
            if serviceSet.contains(service.type) {
                service.weight += weight
            }
        }
        self.reorder()
    }
    
    func add(weight: Int, toService serviceType: serviceType){
        if self.servicesMapping.isEmpty {
            for service in self.services {
                self.servicesMapping[service.type] = service
            }
        }
        
        let ss = self.servicesMapping[serviceType]
        ss?.weight += weight
        
        self.reorder()
    }
    
    private func reorder(){
        self.services.sort {a, b in
            return a.weight > b.weight
        }
        
        self.needsUpdate = true
    }
    
    func resetRankings(){
        
        for service in self.services {
            service.weight = self.ogOrder[service.type]!
        }
        
        self.services.sort {a, b in
            return b.weight > a.weight
        }
        
        self.needsUpdate = true
    }
    
    func clearRankings(){
        for service in self.services {
            service.weight = 0
        }
    }
    
}
