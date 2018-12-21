//
//  OmniBarDelegate.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation

enum OmniBarButton {
    case settings
    case history
}

protocol OmniBarDelegate: class {
    func inputChanged(input: String)
    func omnibarSubmitted()
    func inputCleared()
    func omniBarButtonPressed(_ button: OmniBarButton)
}

