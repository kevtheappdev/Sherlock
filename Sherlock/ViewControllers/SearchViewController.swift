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
    var serviceVC: ServiceResultsTableViewController!
    var webSearchVC: WebSearchViewController!
    var query: String?

    override func viewDidLoad() {
        super.viewDidLoad()
        // view setup
        setupOmniBar()
        loadViewControllers()
    }
    
    func setupOmniBar(){
        if let searchBar =  Bundle.main.loadNibNamed("OmniBar", owner: self, options: nil)?.first as? OmniBar {
            searchBar.delegate = self
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
        } else {
            fatalError("failed to load omni bar")
        }
    }
    
    // MARK: View Controller logic
    func loadViewControllers(){
        // service results view
        let service = ServiceResultsTableViewController()
        register(viewController: service)
        service.delegate = self
        self.serviceVC = service
        
        // web search view
        let webSearch = WebSearchViewController()
        register(viewController: webSearch)
        self.webSearchVC = webSearch
        
        // set ServiceResults as default
        switchTo(viewController: service)
    }

    func register(viewController vc: UIViewController){
        // for now add as child viewcontroller - reevaluate how that should go soon
        addChild(vc)
        vc.didMove(toParent: self)
        self.view.addSubview(vc.view)
        
        let vcView = vc.view
        let omniBar = self.omniBar
        let views = ["vcView": vcView!, "omniBar": omniBar!]
        
        // layout
        vcView?.translatesAutoresizingMaskIntoConstraints = false
        
        let horizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[vcView]|",
                                                                   options: [],
                                                                   metrics: nil,
                                                                   views: views)
        
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[omniBar][vcView]|",
                                                                 options: [],
                                                                 metrics: nil,
                                                                 views: views)
        
        self.view.addConstraints(verticalConstraints)
        self.view.addConstraints(horizontalConstraints)
        
    }
    
    func switchTo(viewController vc: UIViewController){
        self.view.bringSubviewToFront(vc.view)
    }

}

extension SearchViewController: ServiceResultDelegate {
    func didSelect(service: SherlockService) {
        guard let queryVal = self.query else {
            return
        }
        self.omniBar.resignActive()
        self.webSearchVC.execute(query: queryVal, withURL: service.searchURL)
        switchTo(viewController: self.webSearchVC)
    }
}

extension SearchViewController: OmniBarDelegate {
    func inputChanged(input: String) {
        self.query = input
        // TODO: autocomplete process kicks off here
    }
    
    func inputCleared() {
        
    }
    
    func omniBarSelected() {
        switchTo(viewController: self.serviceVC)
    }
    
    func omnibarSubmitted() {
        guard let firstService = SherlockServiceManager.main.getServices().first else {return}
        if let queryVal = self.query{
            self.webSearchVC.execute(query: queryVal, withURL: firstService.searchURL)
            self.omniBar.resignActive()
            switchTo(viewController: webSearchVC)
        }
    }
    
    func omniBarButtonPressed(_ button: OmniBarButton) {
        
    }
    
    
}
