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
    private var cleared = false
    private var loaded = false
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
    private var _allServices = [SherlockService]()
    weak var delegate: SherlockServiceManagerDelegate?
    var currentQuery: String?
    
    // data structure access
    var services: [SherlockService] {
        get {
            return _services
        }
    }
    
    var servicesMapping: [serviceType: SherlockService] {
        get {
            return _servicesMapping
        }
    }
    
    var allServices: [SherlockService] {
        get {
            return _allServices
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
    
    // TODO: Clean this up
    private func loadServices(){
        // Load from UserDefaults and construct instances from json
        let defaults = UserDefaults.standard
        guard var userServices = defaults.array(forKey: "services") as? [String] else {return}
        guard var allServices = defaults.array(forKey: "allServices") as? [String] else {return}
        guard let path = Bundle.main.path(forResource: "search_services", ofType: "json") else {return}
        
        var jsonString: String!
        jsonString = try! String(contentsOfFile: path, encoding: .utf8)
        guard let data = jsonString.data(using: .utf8) else {return}
        let serviceData = try! JSON(data: data).dictionary!
        
        let userServicesSet = Set<String>(userServices)
        let allServicesSet = Set<String>(allServices)
        
        userServices += allServices // combine all services and user services
        
        var index = 0
        for serviceName in userServices {
            let serviceDetails = serviceData[serviceName]?.dictionary
            if serviceDetails != nil {
                
                let serviceObj = parse(serviceDetails: serviceDetails!, serviceName: serviceName)
                serviceObj.ogIndex = index // preserve original indexing
                index += 1
                
                if userServicesSet.contains(serviceName) {
                    _services.append(serviceObj)
                } else {
                    _allServices.append(serviceObj)
                }
            }
        }
        
        // load all available services
        var firstRun = false // populate available services
        let settingsManager = SherlockSettingsManager.main
        firstRun = settingsManager.supportedServices.count == 0
        if !firstRun {return}
        
        
        for (serviceName, service) in serviceData {
            if !allServicesSet.contains(serviceName) {
                if let serviceDetails = service.dictionary {
                    let serviceObj = parse(serviceDetails: serviceDetails, serviceName: serviceName)
                    allServices.append(serviceName)
                    _allServices.append(serviceObj)
                }
            }
        }
        
        settingsManager.supportedServices = allServices
        
    }
    
    // TODO: cut down on the number of parrse overloads
    private func parse(serviceDetails: [String: JSON], serviceName: String) -> SherlockService {
        let name = serviceName
        let searchName = serviceDetails["searchText"]!.string!
        let searchURL = serviceDetails["searchURL"]!.string!
        let iconPath = serviceDetails["icon"]!.string!
        let icon = UIImage(named: iconPath)!
        
        let serviceObj = SherlockService(name: name, searchText: searchName, searchURL: searchURL, icon: icon)
        if let config = serviceDetails["config"]?.dictionary {
            serviceObj.config = parse(config: config)
        }
        
        // parse out categories if they exist
        if let categories = serviceDetails["categories"]?.dictionary {
            serviceObj.categories = parse(categories: categories)
        }
        
        if let acURL = serviceDetails["acURL"]?.string {
            if let acParser = ApplicationConstants.autocomplete[name] {
                serviceObj.automcompleteHandler = AutoCompleteRequester(url: acURL, autocomplete: acParser)
            }
        }
        
        return serviceObj
    }
    
    // update delegate subscribers
    @objc func update(_ sender: Any){
        if needsUpdate {
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

// nc
extension SherlockServiceManager {
    
    func begin(Query query: String){
        currentQuery = query
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
    
    // TODO: revisit the design of these methods
    func updateOrder(OfServices services: [SherlockService]){
        self._services = services
    }
    
    func update(Services services: [SherlockService], otherServices: [SherlockService]){
        self._allServices = otherServices
        self._services = services
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
        let disabledList = SherlockSettingsManager.main.disabledAutoComplete
        for service in services {
            if disabledList.contains(service.type.rawValue) {
                continue
            }
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
                let percentOfQuery = Float(tokenRange.length) / Float(query.count)
                if percentOfQuery >= 0.75 { // TODO: make this constant
                    let name = (query as NSString).substring(with: tokenRange)
                    print("tag: \(tag) for str: \(name)")
                    for (service, serviceWeight) in serviceWeights {
                        add(weight: serviceWeight, toService: service)
                    }
                } else {
                    clearLinguisticWeights()
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
        if !SherlockSettingsManager.main.magicOrderingOn {return}
        
        let ss = servicesMapping[serviceType]
        ss?.weight = 0
        needsUpdate = true
    }
    
    func subtract(weight: Int, forService serviceType: serviceType){
        if !SherlockSettingsManager.main.magicOrderingOn {return}
        
        let ss = servicesMapping[serviceType]
        guard let curWeight = ss?.weight else {
            return
        }
        
        if curWeight >= weight {
            ss?.weight -= weight
        }
        
        reorder()
        needsUpdate = true
    }
    
    func add(weight: Int, toService serviceType: serviceType){
        if !SherlockSettingsManager.main.magicOrderingOn {return}
        
        let ss = servicesMapping[serviceType]
        ss?.weight += weight
        reorder()
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
        
        reorder()
        needsUpdate = true
    }
    
}
