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
    }
    
}
