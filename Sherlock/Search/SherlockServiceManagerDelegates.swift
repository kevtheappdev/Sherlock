//
//  SherlockServiceManagerDelegate.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/21/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation

protocol SherlockServiceManagerDelegate: class {
    // func to notify of changes to subscribers
    func resultsChanged(_ services: [SherlockService])
    func resultsCleared()
}

protocol SherlockServiceManagerCommitDelegate: class {
    func resultsCommited(_ services: [SherlockService])
}
