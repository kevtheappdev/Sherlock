//
//  SherlockSettingsManager.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/4/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class SherlockSettingsManager: NSObject {
    static let main = SherlockSettingsManager()
    let userDefaults = UserDefaults.standard
    
    // computed properties
    var supportedServices: [String] {
        get {
            return userDefaults.array(forKey: ApplicationConstants.allServicesKey) as! [String]
        }
        
        set {
            userDefaults.set(newValue, forKey: ApplicationConstants.allServicesKey)
        }
    }
    
    var userServices: [String] {
        get {
            return userDefaults.array(forKey: ApplicationConstants.servicesKey) as! [String]
        }
        
        set {
            userDefaults.set(newValue, forKey: ApplicationConstants.servicesKey)
        }
    }
    
    var magicOrderingOn: Bool {
        get {
            return userDefaults.bool(forKey: ApplicationConstants.magicOrderKey)
        }
        
        set {
            userDefaults.set(newValue, forKey: ApplicationConstants.magicOrderKey)
        }
    }
    
    private override init() {
        super.init()
    }
    
    func setupPrefs(){
        // set all available services here
        if userDefaults.array(forKey: ApplicationConstants.allServicesKey) == nil { // TODO: Make keys a constant
            userDefaults.set([], forKey: ApplicationConstants.allServicesKey)
        }
        
        // TODO: just a temporary sitch until we have proper onboarding
        if userDefaults.array(forKey: ApplicationConstants.servicesKey) == nil {
            userDefaults.set([serviceType.google.rawValue, serviceType.wikipedia.rawValue, serviceType.facebook.rawValue], forKey: ApplicationConstants.servicesKey)
        }
        
        if !userDefaults.bool(forKey: ApplicationConstants.setupKey) { // set booleans and other default values
            userDefaults.set(true, forKey: ApplicationConstants.magicOrderKey)
            userDefaults.set(true, forKey: ApplicationConstants.setupKey)
        }
        
        
    }
    
    func addSupported(Service service: serviceType){
        var supported = supportedServices
        supported.append(service.rawValue)
        supportedServices = supported
    }
    
    func updateOrder(ofServices services: [SherlockService]){
        var index = 0
        for service in services {
            service.ogIndex = index
            index += 1
        }
        
        SherlockServiceManager.main.updateOrder(OfServices: services)
        userServices = extractRawValues(fromServices: services)
    }
    
    func update(Services services: [SherlockService], otherServices: [SherlockService]){
        SherlockServiceManager.main.update(Services: services, otherServices: otherServices)
        userServices = extractRawValues(fromServices: services)
        supportedServices = extractRawValues(fromServices: otherServices)
    }
    
    private func extractRawValues(fromServices services: [SherlockService]) -> [String] {
        var serviceTypes: [String] = []
        for service in services {
            serviceTypes.append(service.type.rawValue)
        }
        return serviceTypes
    }
    
}
