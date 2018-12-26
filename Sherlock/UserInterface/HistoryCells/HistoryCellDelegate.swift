//
//  HistoryCellDelegate.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/24/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation
import CoreData

protocol HistoryCellDelegate: class {
    func deleteButtonPressed(object: NSManagedObject?)
}
