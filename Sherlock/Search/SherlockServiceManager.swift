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
    private var isFinal = false
    private var loaded = false
    private var ogOrder = Dictionary<serviceType, Int>() // Maps service types with their original index
    private lazy var _servicesMapping: Dictionary<serviceType, SherlockService> = {
        if !self.loaded {
            fatalError("Must call load() before accessing")
        }
        
        var mapping = Dictionary<serviceType, SherlockService>()
        for service in self.services {
            mapping[service.type] = service
        }
        return mapping
    }()
    
    // ivars
    private var _services = Array<SherlockService>()
    weak var delegate: SherlockServiceManagerDelegate?
    weak var commitDelegate: SherlockServiceManagerCommitDelegate?
    
    // data structure access
    var services: [SherlockService] {
        get {
            return self._services
        }
    }
    
    var servicesMapping: [serviceType: SherlockService] {
        get {
            return self._servicesMapping
        }
    }

    
    private override init() {
        super.init()
        self.timer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(SherlockServiceManager.update(_:)), userInfo: nil, repeats: true)
    }
    
    
    func load(){
        // Other setup
        self.loaded = true
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
                    serviceObj.config = self.parse(config: config)
                }
                
                // parse out categories if they exist
                if let categories = serviceDetails!["categories"]?.dictionary {
                   serviceObj.categories = self.parse(categories: categories)
                }
                
                if let acURL = serviceDetails!["acURL"]?.string {
                    if let acParser = ApplicationConstants.autocomplete[name] {
                        serviceObj.automcompleteHandler = AutoCompleteRequester(url: acURL, autocomplete: acParser)
                    }
                }
                
                serviceObj.ogIndex = index // preserve original indexing
                index += 1
                
                self._services.append(serviceObj)
            }
        }
        
    }
    
    // update delegate subscribers
    @objc func update(_ sender: Any){
        if self.needsUpdate {
            if self.canChangeOrder {
                self.reorder() // ensure sorted data
                self.canChangeOrder = false // limit how often we change results
                Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) {_ in
                    self.canChangeOrder = true
                }
            }
            self.delegate?.resultsChanged(self.copyServices())
            self.needsUpdate = false
            if self.isFinal {
                self.commitDelegate?.resultsCommited(self.copyServices())
                self.isFinal = false
            }
            
            if self.cleared {
                self.delegate?.resultsCleared()
                self.cleared = false
            }
        }
        
    }
    
    func copyServices() -> [SherlockService]
    {
        var copy: [SherlockService] = []
        for service in self.services {
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
        self.fetchAutocomplete(forQuery: query)
        self.analyze(Query: query)
    }
    
    func commit(Query query: String){
        self.fetchAutocomplete(forQuery: query)
        self.categorize(withQuery: query)
        self.isFinal = true
        self.needsUpdate  = true
    }
    
    func cancelQuery(){
        self.cancelAutocomplete()
        self.clearAutocomplete()
        self.resetRankings()
        self.cleared = true
    }
}

// MARK: Parsing functions for services
extension SherlockServiceManager {
    // configure SherlockServiceConfig objectr from the JSON
    private func parse(config configDict: Dictionary<String, JSON>) -> SherlockServiceConfig {
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
    
    private func parse(categories categoryDict: Dictionary<String, JSON>) -> [NSLinguisticTag: Int] { // TODO: Change out NSLinguisticTag enum for something more extensible
        
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
        for service in self.services {
            service.automcompleteHandler?.makeRequest(withQuery: query) {(error) in
                if error == nil {
                    self.needsUpdate = true
                }
            }
        }
    }
    
    private func clearAutocomplete(){
        for service in self.services {
            service.automcompleteHandler?.clear()
        }
        
        self.needsUpdate = true
    }
    
    private func cancelAutocomplete(){
        for service in self.services {
            service.automcompleteHandler?.cancel()
        }
    }
}

// MARK: Linguistic analysis
extension SherlockServiceManager {
    
    private func analyze(Query query: String){
        self.categorize(withQuery: query)
        self.addressAnalysis(ofString: query)
    }
    
    private func categorize(withQuery query: String){
        self.clearLinguisticWeights()//  fresh start on rankings
        
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
                print("tag: \(tag) for str: \(query)")
                for (service, serviceWeight) in serviceWeights {
                    self.add(weight: serviceWeight, toService: service)
                }
            } else {
                self.clearLinguisticWeights()
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
        
        
        for service in self.services {
            let sWeight = service.categories[.placeName]
            if sWeight != nil {
                if foundAddress {
                    self.add(weight: sWeight! * 2, toService: service.type)
                } else {
                    self.subtract(weight: sWeight! * 2, forService: service.type)
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
        for service in self.services {
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
        
        let ss = self.servicesMapping[serviceType]
        ss?.weight = 0
        self.needsUpdate = true
    }
    
    func subtract(weight: Int, forService serviceType: serviceType){
        
        let ss = self.servicesMapping[serviceType]
        guard let curWeight = ss?.weight else {
            return
        }
        
        if curWeight >= weight {
            ss?.weight -= weight
        }
        
        self.needsUpdate = true
    }
    
    func add(weight: Int, toService serviceType: serviceType){
        let ss = self.servicesMapping[serviceType]
        ss?.weight += weight
        self.needsUpdate = true
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
        for service in self.services {
            service.weight = 0
        }
        
        self.needsUpdate = true
    }
    
}
