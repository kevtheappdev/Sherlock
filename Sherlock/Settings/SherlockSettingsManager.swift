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
    
    var disabledAutoComplete: Set<String> {
        get {
            let arr = userDefaults.array(forKey: ApplicationConstants.autocompleteKey) as! [String]
            return Set<String>(arr)
        }
        
        set {
            let newSet = Array<String>(newValue)
            userDefaults.set(newSet, forKey: ApplicationConstants.autocompleteKey)
        }
    }
    
    var appearanceColor: String {
        get {
            return userDefaults.string(forKey: ApplicationConstants.appearanceKey)!
        }
        
        set {
            ApplicationConstants.currentColorKey = newValue
            userDefaults.set(newValue, forKey: ApplicationConstants.appearanceKey)
        }
    }

    var shortcutKeys: [String] {
        get {
            // TODO: implement this for all properties instead of relying on default being set
            if userDefaults.array(forKey: ApplicationConstants.shortcutKey) == nil {
                userDefaults.set([], forKey: ApplicationConstants.shortcutKey)
                return []
            }
            
            return userDefaults.array(forKey: ApplicationConstants.shortcutKey) as! [String]
        }
        
        set {
            userDefaults.set(newValue, forKey: ApplicationConstants.shortcutKey)
        }
    }
    
    private override init() {
        super.init()
    }
    
    func setupPrefs(){
        // set all available services here
        if userDefaults.array(forKey: ApplicationConstants.allServicesKey) == nil { 
            userDefaults.set([], forKey: ApplicationConstants.allServicesKey)
        }
        
        // TODO: just a temporary sitch until we have proper onboarding
        if userDefaults.array(forKey: ApplicationConstants.servicesKey) == nil {
            userDefaults.set([serviceType.google.rawValue, serviceType.wikipedia.rawValue, serviceType.facebook.rawValue], forKey: ApplicationConstants.servicesKey)
        }
        
        if !userDefaults.bool(forKey: ApplicationConstants.setupKey) { // set booleans and other default values
            userDefaults.set(true, forKey: ApplicationConstants.magicOrderKey)
            userDefaults.set(true, forKey: ApplicationConstants.setupKey)
            userDefaults.set([], forKey: ApplicationConstants.autocompleteKey)
            userDefaults.set([], forKey: ApplicationConstants.shortcutKey)
            userDefaults.set("blue", forKey: ApplicationConstants.appearanceKey)
        }
    
        ApplicationConstants.currentColorKey = appearanceColor
        
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
        
        NotificationCenter.default.post(name: .servicesChanged, object: nil)
    }
    
    func update(Services services: [SherlockService], otherServices: [SherlockService]){
        SherlockServiceManager.main.update(Services: services, otherServices: otherServices)
        userServices = extractRawValues(fromServices: services)
        supportedServices = extractRawValues(fromServices: otherServices)
        NotificationCenter.default.post(name: .servicesChanged, object: nil)
    }
    
    // MARK: autocomplete
    func addDisabledAutocomplete(Service service: SherlockService){
        var disabled = disabledAutoComplete
        disabled.insert(service.type.rawValue)
        disabledAutoComplete = disabled
    }
    
    func removeDisabledAutocomplete(Service service: SherlockService){
        var disabled = disabledAutoComplete
        disabled.remove(service.type.rawValue)
        disabledAutoComplete = disabled
    }
    
    private func extractRawValues(fromServices services: [SherlockService]) -> [String] {
        var serviceTypes: [String] = []
        for service in services {
            serviceTypes.append(service.type.rawValue)
        }
        return serviceTypes
    }
    
    // MARK: Shortcuts
    func add(Shortcut shortcut: SherlockShortcut){
        var keys = shortcutKeys
        keys.append(shortcut.activationText)
        shortcutKeys = keys
        
        var serviceTypes = [String]()
        for service in shortcut.services {
            serviceTypes.append(service.rawValue)
        }
        userDefaults.set(serviceTypes, forKey: shortcut.activationText)
    }
    
    func update(Shortcut shortcutKey: String, updatedShortcut: SherlockShortcut) {
        var keys = shortcutKeys
        let removeIndex = keys.index(of: shortcutKey)! // TODO: Look into making sure this never fails
        keys.remove(at: removeIndex)
        shortcutKeys = keys
        userDefaults.removeObject(forKey: shortcutKey)
        add(Shortcut: updatedShortcut)
    }
    
}
