//
//  URLSchemeCoverView.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/3/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class URLSchemeCoverView: UIView {
    var service: SherlockService!
    @IBOutlet weak var iconView: UIImageView!
    @IBOutlet weak var openInButton: UIButton!
    
    func set(Service service: SherlockService){
        self.service = service
        self.openInButton.setTitle(service.searchText, for: .normal)
        self.iconView.image = service.icon
    }

    @IBAction func openButtonPressed(_ sender: Any) {
        guard let queryStr = SherlockServiceManager.main.currentQuery else {
            return
        }
        var urlStr = service.searchURL.replacingOccurrences(of: "{query}", with: queryStr)
        urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
        let url = URL(string: urlStr)!
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
}
