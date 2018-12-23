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
        do {
            jsonString = try String(contentsOfFile: path, encoding: .utf8)
        } catch {
            return // TODO: figure out a better handling here
        }
        
        guard let data = jsonString.data(using: .utf8) else {return}
        let serviceData = try! JSON(data: data).dictionary! // TODO: revisit this
        
        
        for service in userServices {
            let serviceDetails = serviceData[service]!.dictionary
            if serviceDetails != nil {
                let name = service
                let searchName = serviceDetails!["searchText"]!.string!
                let searchURL = serviceDetails!["searchURL"]!.string!
                let iconPath = serviceDetails!["icon"]!.string!
                let icon = UIImage(named: iconPath)!
                
                let serviceObj = SherlockService(name: name, searchText: searchName, searchURL: searchURL, icon: icon)
                self.services.append(serviceObj)
            }
        }
        
    }
    
}

// MARK: API Methods
extension SherlockServiceManager {
    // temp function for current state of datastructures
    func getServices() -> [SherlockService]
    {
        return self.services
    }
}
