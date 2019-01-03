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
    private var canChangeOrder = true
    private var cleared = false
    private var loaded = false
    private var ogOrder = [serviceType: Int]() // Maps service types with their original index
    private lazy var _servicesMapping: [serviceType: SherlockService] = {
        if !loaded {
            fatalError("Must call load() before accessing")
        }
        
        var mapping = [serviceType: SherlockService]()
        for service in services {
            mapping[service.type] = service
        }
        return mapping
    }()
    
    // ivars
    private var _services = [SherlockService]()
    weak var delegate: SherlockServiceManagerDelegate?
    
    // data structure access
    var services: [SherlockService] {
        get {
            return _services
        }
    }
    
    var servicesMapping: [serviceType: SherlockService] {
        get {
            return self._servicesMapping
        }
    }

    
    private override init() {
        super.init()
        timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(SherlockServiceManager.update(_:)), userInfo: nil, repeats: true)
    }
    
    
    func load(){
        // Other setup
        loaded = true
        loadServices()
        resetRankings() // fresh rank
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
                    serviceObj.config = parse(config: config)
                }
                
                // parse out categories if they exist
                if let categories = serviceDetails!["categories"]?.dictionary {
                   serviceObj.categories = parse(categories: categories)
                }
                
                if let acURL = serviceDetails!["acURL"]?.string {
                    if let acParser = ApplicationConstants.autocomplete[name] {
                        serviceObj.automcompleteHandler = AutoCompleteRequester(url: acURL, autocomplete: acParser)
                    }
                }
                
                serviceObj.ogIndex = index // preserve original indexing
                index += 1
                
                _services.append(serviceObj)
            }
        }
        
    }
    
    // update delegate subscribers
    @objc func update(_ sender: Any){
        if needsUpdate {
            if canChangeOrder {
                reorder() // ensure sorted data
                canChangeOrder = false // limit how often we change results
                Timer.scheduledTimer(withTimeInterval: 0.25, repeats: false) {_ in
                    self.canChangeOrder = true
                }
            }
            delegate?.resultsChanged(copyServices())
            needsUpdate = false
            
            if cleared {
                delegate?.resultsCleared()
                cleared = false
            }
        }
        
    }
    
    func copyServices() -> [SherlockService]
    {
        var copy: [SherlockService] = []
        for service in services {
            let copyService = SherlockService(name: service.type.rawValue, searchText: service.searchText, searchURL: service.searchURL, icon: service.icon)
            copyService.config = service.config
            copyService.automcompleteHandler = service.automcompleteHandler?.copy()
            copyService.weight = service.weight
            copy.append(copyService)
        }
        
        return copy
    }
    
    
}

// MARK: API Methods
extension SherlockServiceManager {
    
    func begin(Query query: String){
        fetchAutocomplete(forQuery: query)
        analyze(Query: query)
    }
    
    func commitQuery() -> [SherlockService]{
        needsUpdate = false
        cancelAutocomplete()
        return copyServices()
    }
    
    func cancelQuery(){
        cancelAutocomplete()
        clearAutocomplete()
        resetRankings()
        cleared = true
    }
}

// MARK: Parsing functions for services
extension SherlockServiceManager {
    // configure SherlockServiceConfig objectr from the JSON
    private func parse(config configDict: [String: JSON]) -> SherlockServiceConfig {
        var serviceConfig = SherlockServiceConfig()
        
        // resultsPage options
        if let resultsConfig = configDict["resultsPage"]?.dictionary {
            if let jsEnabled = resultsConfig["javascriptEnabled"]?.bool {
                serviceConfig.resultsJavascriptEnabled = jsEnabled
            }
            
            if let openURL = resultsConfig["openURL"]?.bool {
                serviceConfig.openURLScheme = openURL
            }
        }
        
        return serviceConfig
    }
    
    private func parse(categories categoryDict: [String: JSON]) -> [NSLinguisticTag: Int] { // TODO: Change out NSLinguisticTag enum for something more extensible
        
        var serviceCategories: [NSLinguisticTag:Int] = [:]
        for (category, weight) in categoryDict {
            guard let weight = weight.int else {
                continue
            }
            
            let tag = NSLinguisticTag(rawValue: category)
            serviceCategories[tag] = weight
        }
        return serviceCategories
    }

}

// MARK: Autocomplete
extension SherlockServiceManager {
    private func fetchAutocomplete(forQuery query: String){
        for service in services {
            service.automcompleteHandler?.makeRequest(withQuery: query) {(error) in
                if error == nil {
                    self.needsUpdate = true
                }
            }
        }
    }
    
    private func clearAutocomplete(){
        for service in services {
            service.automcompleteHandler?.clear()
        }
        
        needsUpdate = true
    }
    
    private func cancelAutocomplete(){
        for service in services {
            service.automcompleteHandler?.cancel()
        }
    }
}

// MARK: Linguistic analysis
extension SherlockServiceManager {
    
    private func analyze(Query query: String){
        categorize(withQuery: query)
        addressAnalysis(ofString: query)
    }
    
    private func categorize(withQuery query: String){
        clearLinguisticWeights()//  fresh start on rankings
        
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
                let serviceWeights = servicesFor(tag: tag)
                print("tag: \(tag) for str: \(query)")
                for (service, serviceWeight) in serviceWeights {
                    add(weight: serviceWeight, toService: service)
                }
            } else {
                clearLinguisticWeights()
            }
        }
    }
    
    private func addressAnalysis(ofString query: String) {
        guard let detector = try? NSDataDetector(types: NSTextCheckingResult.CheckingType.address.rawValue) else {
            return
        }
        
        var foundAddress = false
        let matches = detector.matches(in: query, options: [], range: NSRange(location: 0, length: query.count))
        for match in matches {
            if match.resultType == .address {
                foundAddress = true
                break
            }
        }
        
        
        for service in services {
            let sWeight = service.categories[.placeName]
            if sWeight != nil {
                if foundAddress {
                    add(weight: sWeight! * 2, toService: service.type)
                } else {
                    subtract(weight: sWeight! * 2, forService: service.type)
                }
            }
        }

    }
    
    private func servicesFor(tag: NSLinguisticTag) -> [serviceType: Int]{
        var services: [serviceType: Int] = [:]
        for service in self.services {
            if service.categories[tag] != nil {
                let weight = service.categories[tag]!
                service.categoriesApplied.append(weight)
                services[service.type] = weight
            }
        }
        
        return services
    }
    
    private func clearLinguisticWeights(){
        for service in services {
            for weight in service.categoriesApplied {
                if weight > service.weight {
                    break
                }
                service.weight -= weight
            }
            service.categoriesApplied.removeAll()
        }
    }
}

// MARK: Automatic ordering
extension SherlockServiceManager {

    func removeWeight(forService serviceType: serviceType){
        
        let ss = servicesMapping[serviceType]
        ss?.weight = 0
        needsUpdate = true
    }
    
    func subtract(weight: Int, forService serviceType: serviceType){
        
        let ss = servicesMapping[serviceType]
        guard let curWeight = ss?.weight else {
            return
        }
        
        if curWeight >= weight {
            ss?.weight -= weight
        }
        
        needsUpdate = true
    }
    
    func add(weight: Int, toService serviceType: serviceType){
        let ss = servicesMapping[serviceType]
        ss?.weight += weight
        needsUpdate = true
    }

    
    private func reorder(){
        self._services.sort {a, b in
            if a.weight == b.weight {
                return a.ogIndex < b.ogIndex
            }
            return a.weight > b.weight
        }
    }
    
    func resetRankings(){
        for service in services {
            service.weight = 0
        }
        
        needsUpdate = true
    }
    
}
