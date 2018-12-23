//
//  ServiceSelectorBarDelegate.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/22/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import Foundation


protocol ServiceSelectorBarDelegate: class {
    func selected(service: SherlockService)
}
