//
//  WebNavBarDelegate.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/23/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation

protocol WebNavBarDelegate: class {
    func backButtonPressed()
    func forwardButtonPressed()
    func reloadButtonPressed()
    func shareButtonPressed()
}
