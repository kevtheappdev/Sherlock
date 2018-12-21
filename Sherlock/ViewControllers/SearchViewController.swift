//
//  SearchViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class SearchViewController: UIViewController {
    var omniBar: OmniBar!
    var viewControllers: [UIViewController]? // TODO: look into having a more specific subclass here

    override func viewDidLoad() {
        super.viewDidLoad()
        setupOmniBar()
    }
    
    func setupOmniBar(){
        if let searchBar =  Bundle.main.loadNibNamed("OmniBar", owner: self, options: nil)?.first as? OmniBar {
            self.omniBar = searchBar
            self.view.addSubview(self.omniBar)
            // layout
            self.view.translatesAutoresizingMaskIntoConstraints = false
            self.view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            self.omniBar.translatesAutoresizingMaskIntoConstraints = false
            
            let views = ["omniBar": searchBar]
            let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[omniBar]|",
                                                                       options: [],
                                                                       metrics: nil,
                                                                       views: views)
            
            let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[omniBar]",
                                                                     options: [],
                                                                     metrics: nil,
                                                                     views: views)
            
            let heightConstraint = NSLayoutConstraint(item: searchBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 125)
            
            self.view.addConstraints(verticalConstraints)
            self.view.addConstraints(horizontalConstraints)
            self.omniBar.addConstraint(heightConstraint)
            
        
        }
    }
    
    // MARK: Load View Controllers
    func loadSearchViewController(){
        // load from storyboard
    }
    

}
