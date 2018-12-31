//
//  SearchViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/20/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import  SafariServices

class SearchViewController: UIViewController {
    // transitions
    let present = PushTransition()
    let dissmiss = UnwindPushTransition()
    let newModal = NewModal()
    let unwindNewModal = UnwindNewModal()
    let interactor = PushInteractor()
    let modalInteractor = NewModalInteractor()
    
    var omniBar: OmniBar!
    var serviceVC: ServiceResultsTableViewController!
    var resultsVC: ScrollResultsViewController!
    var query: String?
    var queryToExecute = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // view setup
        setupOmniBar()
        loadViewControllers()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if self.queryToExecute {
            self.resultsVC.execute(query: self.query!)
            switchTo(viewController: resultsVC)
            self.omniBar.searchField.text = self.query
            self.omniBar.resignActive()
            self.queryToExecute = false
        }
    }
    
    func setupOmniBar(){
        if let searchBar =  Bundle.main.loadNibNamed("OmniBar", owner: self, options: nil)?.first as? OmniBar {
            searchBar.delegate = self
            self.omniBar = searchBar
            self.view.addSubview(self.omniBar)
            // layout
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
            
            let heightConstraint = NSLayoutConstraint(item: searchBar, attribute: .height, relatedBy: .equal, toItem: nil, attribute: .notAnAttribute, multiplier: 1.0, constant: 100)
            
            self.view.addConstraints(verticalConstraints)
            self.view.addConstraints(horizontalConstraints)
            self.omniBar.addConstraint(heightConstraint)
        } else {
            fatalError("failed to load omni bar")
        }
    }
    
    // MARK: View Controller logic
    func loadViewControllers(){
        let services = SherlockServiceManager.main.services
        
        // service results view
        let service = ServiceResultsTableViewController(services: services)
        register(viewController: service)
        service.delegate = self
        self.serviceVC = service
        
        // web search view
        let webSearch = ScrollResultsViewController(services: services)
        webSearch.delegate = self
        register(viewController: webSearch)
        self.resultsVC = webSearch
        
        // set ServiceResults as default
        switchTo(viewController: service)
    }

    func register(viewController vc: UIViewController){
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

extension SearchViewController: ServiceResultDelegate {
    func updated(query: String) {
        self.query = query
        self.omniBar.searchField.text = query
    }
    
    func didSelect(service: SherlockService) {
        guard let queryVal = self.query else {return}
        if queryVal.isEmpty {return}
        self.omniBar.resignActive()
        self.resultsVC.execute(query: queryVal, service: service)
        switchTo(viewController: self.resultsVC)
    }
}

extension SearchViewController: OmniBarDelegate {
    func inputChanged(input: String) {
        self.query = input
        if input.isEmpty {
            self.inputCleared()
        } else {
            SherlockServiceManager.main.begin(Query: input)
        }
    }
    
    func inputCleared() {
        self.query = ""
        // clear autocomplete suggestions
        SherlockServiceManager.main.cancelQuery()
    }
    
    func omniBarSelected() {
        switchTo(viewController: self.serviceVC)
    }
    
    func omnibarSubmitted() {
        if let queryVal = self.query {
            if queryVal.isEmpty {return}
            SherlockServiceManager.main.commit(Query: queryVal)
            self.resultsVC.execute(query: queryVal)
            self.omniBar.resignActive()
            switchTo(viewController: resultsVC)
        }
    }
    
    func omniBarButtonPressed(_ button: OmniBarButton) {
        if button == .history {
            let historySB = UIStoryboard(name: "History", bundle: nil)
            let historyVC = historySB.instantiateViewController(withIdentifier: "historyVC") as! HistoryViewController
            historyVC.delegate = self
            historyVC.transitioningDelegate = self
            historyVC.modalInteractor = self.modalInteractor
            self.present(historyVC, animated: true)
        }
    }
    
}

extension SearchViewController: ScrollResultsDelegate {
    func selectedLink(url: URL) {
        let sfVC = WebResultViewController(url: url)
        sfVC.transitioningDelegate = self
        sfVC.interactor = self.interactor
        self.present(sfVC, animated: true)
    }
    
    func switchedTo(service: serviceType) {
//        print("switched to: \(service.rawValue)")
        let services = SherlockServiceManager.main.servicesMapping
        let ss = services[service]!
        
        if ss.config.openURLScheme {
            guard let queryStr = self.query else {
                return
            }
            var urlStr = ss.searchURL.replacingOccurrences(of: "{query}", with: queryStr)
            urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
            let url = URL(string: urlStr)!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        
        
        
    }
    
}

extension SearchViewController: HistoryVCDDelegate {
    func execute(search: String) {
        self.query = search
        self.queryToExecute = true
    }
    
}

extension SearchViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let _ = presented as? HistoryViewController {
            return self.newModal
        }
        return self.present
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let _ = dismissed as? HistoryViewController {
            return self.unwindNewModal
        }
        return self.dissmiss
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if let _ = animator as? UnwindPushTransition {
            return interactor.hasStarted ? interactor : nil
        } else {
            return modalInteractor.hasStarted ? modalInteractor : nil
        }
    }
}
