//
//  ServiceResultDelegate.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/21/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation

protocol ServiceResultDelegate: class {
    func didSelect(service: SherlockService)
}
