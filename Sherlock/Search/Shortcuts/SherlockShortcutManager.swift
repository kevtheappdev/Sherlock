//
//  SherlockShortcutManager.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/11/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class SherlockShortcutManager: NSObject {
    static let main = SherlockShortcutManager()
    
    // ivars
    private var _shortcuts = [SherlockShortcut]()
    
    
    // getters
    var shortcuts: [SherlockShortcut] {
        get {
            return _shortcuts
        }
    }
    
    private override init(){
        super.init()
        load()
    }
    
    private func load(){
        let shortcuts = SherlockSettingsManager.main.shortcutKeys
        for key in shortcuts {
            let serviceVals = UserDefaults.standard.array(forKey: key) as! [String]
            var serviceTypes = [serviceType]()
            for serviceVal in serviceVals {
                serviceTypes.append(serviceType(rawValue: serviceVal)!)
            }
            
            let shortcutObj = SherlockShortcut(activationText: key, services: serviceTypes)
            _shortcuts.append(shortcutObj)
        }
    }
    
    func add(Shortcut shortcut: SherlockShortcut){
        _shortcuts.append(shortcut)
        SherlockSettingsManager.main.add(Shortcut: shortcut)
    }
    
}
