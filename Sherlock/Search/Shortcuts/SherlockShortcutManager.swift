//
//  SherlockShortcutManager.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/11/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit
import Intents

class SherlockShortcutManager: NSObject {
    static let main = SherlockShortcutManager()
    
    // ivars
    private var _shortcuts = [SherlockShortcut]()
    private var currentShortcut: String?
    
    
    // getters
    var shortcuts: [SherlockShortcut] {
        get {
            return _shortcuts
        }
    }
    
    private var shortcutMap: [String: SherlockShortcut]!
    
    private override init(){
        super.init()
        loadShortcuts()
        loadMap()
    }
    
    private func loadShortcuts(){
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
    
    private func loadMap() {
        var map = [String: SherlockShortcut]()
        for shortcut in _shortcuts {
            map[shortcut.activationText] = shortcut
        }
        shortcutMap = map
    }
    
    private func reload(){
        _shortcuts.removeAll(keepingCapacity: true)
        loadShortcuts()
        loadMap()
    }
    
    func add(Shortcut shortcut: SherlockShortcut){
        _shortcuts.append(shortcut)
        SherlockSettingsManager.main.add(Shortcut: shortcut)
        loadMap()
    }
    
    func update(Shortcut shortcutKey: String, updatedShortcut: SherlockShortcut){
        SherlockSettingsManager.main.update(Shortcut: shortcutKey, updatedShortcut: updatedShortcut)
        reload()
    }
    
    func delete(Shortcut shortcutKey: String){
        SherlockSettingsManager.main.delete(Shortcut: shortcutKey)
        reload()
    }
    
    func screen(Query query: String) -> (SherlockShortcut?, String?) {
        if query.isEmpty {return (nil, nil)}
        var queryComponents = query.split(separator: " ")
        let comp = String(queryComponents.remove(at: 0))
        if comp.count == 0 {return (nil, nil)}
        let cleanedQuery = queryComponents.joined(separator: " ")
        return (shortcutMap[comp], cleanedQuery)
    }
    
    func createUserActivity(withShortcut shortcut: SherlockShortcut) -> NSUserActivity {
        let activity = NSUserActivity(activityType: "com.kevinturner.Sherlock.shortcutSearch")
        activity.title = shortcut.activationText
        activity.userInfo = ["shortcut": shortcut.activationText]
        activity.isEligibleForSearch = true
        activity.isEligibleForPrediction = true
        return activity
    }
}
