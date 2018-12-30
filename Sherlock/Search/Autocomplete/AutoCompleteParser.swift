//
//  AutoCompleteParser.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/28/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit


protocol AutoCompleteParser: class {
    func process(results data: Data) -> [Autocomplete]
}
