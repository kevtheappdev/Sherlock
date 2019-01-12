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
    let flipTransition = FlipTransition()
    let unwindFlipTransition = UnwindFlipTransition()
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
        if queryToExecute { // TODO: make this a check  on the query string itself
            let services = SherlockServiceManager.main.copyServices()
            resultsVC.execute(query: query!, services: services, recordHistory: false)
            switchTo(viewController: resultsVC)
            omniBar.searchField.text = query
            omniBar.resignActive()
            queryToExecute = false
        }
    }
    
    func setupOmniBar(){
        if let searchBar =  Bundle.main.loadNibNamed("OmniBar", owner: self, options: nil)?.first as? OmniBar {
            searchBar.delegate = self
            omniBar = searchBar
            view.addSubview(omniBar)
            // layout
            view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
            omniBar.translatesAutoresizingMaskIntoConstraints = false
            
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
            
            view.addConstraints(verticalConstraints)
            view.addConstraints(horizontalConstraints)
            omniBar.addConstraint(heightConstraint)
        } else {
            fatalError("failed to load omni bar")
        }
    }
    
    // MARK: View Controller logic
    func loadViewControllers(){
        let services = SherlockServiceManager.main.userServices
        
        // service results view
        let service = ServiceResultsTableViewController(services: services)
        register(viewController: service)
        service.delegate = self
        serviceVC = service
        
        // web search view
        let webSearch = ScrollResultsViewController(services: services)
        register(viewController: webSearch)
        resultsVC = webSearch
        
        // set ServiceResults as default
        switchTo(viewController: service)
    }

    func register(viewController vc: UIViewController){
        addChild(vc)
        vc.didMove(toParent: self)
        view.addSubview(vc.view)
        
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
        
        view.addConstraints(verticalConstraints)
        view.addConstraints(horizontalConstraints)
        
    }
    
    func switchTo(viewController vc: UIViewController){
        view.bringSubviewToFront(vc.view)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }

}

// MARK: 3D touch shortcut handling
extension SearchViewController {
    func startNewSearch(){
        query = ""
        omniBar.searchField.text = ""
        SherlockServiceManager.main.cancelQuery()
        switchTo(viewController: serviceVC)
        if !omniBar.isFirstResponder {
            omniBar.searchField.becomeFirstResponder()
        }
    }
    
    func displayHistory(){
        let historySB = UIStoryboard(name: "History", bundle: nil)
        let historyVC = historySB.instantiateViewController(withIdentifier: "historyVC") as! HistoryViewController
        historyVC.delegate = self
        historyVC.transitioningDelegate = self
        historyVC.modalInteractor = modalInteractor
        present(historyVC, animated: true)
    }
}

// MARK:  ServiceResultDelegate
extension SearchViewController: ServiceResultDelegate {
    func addServices() {
        let settingsSB = UIStoryboard(name: "Settings", bundle: nil)
        let svc = settingsSB.instantiateViewController(withIdentifier: "settings") as! ServiceSettingsViewController
        svc.services = SherlockServiceManager.main.userServices
        svc.otherServices = SherlockServiceManager.main.otherServices
        svc.transitioningDelegate = self
        svc.interactor = interactor
        present(svc, animated: true)
    }
    
    func updated(query: String) {
        self.query = query
        omniBar.searchField.text = query
    }
    
    func didSelect(service: SherlockService) {
        guard let queryVal = query else {return}
        if queryVal.isEmpty {return}
        omniBar.resignActive()
        let services = SherlockServiceManager.main.commitQuery()
        resultsVC.execute(query: queryVal, service: service, services: services)
        switchTo(viewController: resultsVC)
        
        // Open URL scheme
        if service.config.openURLScheme {
            guard let queryStr = query else {
                return
            }
            var urlStr = service.searchURL.replacingOccurrences(of: "{query}", with: queryStr)
            urlStr = urlStr.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
            let url = URL(string: urlStr)!
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
}

// MARK: OmniBarDelegate
extension SearchViewController: OmniBarDelegate {
    func inputChanged(input: String) {
        query = input
        if input.isEmpty {
            inputCleared()
        } else {
            SherlockServiceManager.main.begin(Query: input)
        }
    }
    
    func inputCleared() {
        query = ""
        // clear autocomplete suggestions
        SherlockServiceManager.main.cancelQuery()
    }
    
    func omniBarSelected() {
        switchTo(viewController: serviceVC)
    }
    
    func omnibarSubmitted() {
        if let queryVal = query {
            if queryVal.isEmpty {return}
            let services = SherlockServiceManager.main.commitQuery()
            resultsVC.execute(query: queryVal, services: services)
            omniBar.resignActive()
            switchTo(viewController: resultsVC)
        }
    }
    
    func omniBarButtonPressed(_ button: OmniBarButton) {
        if button == .history {
            displayHistory()
        } else {
            let settingsSB = UIStoryboard(name: "Settings", bundle: nil)
            let settingsVC = settingsSB.instantiateViewController(withIdentifier: "mainSettings") as! SettingsViewController
            settingsVC.services = SherlockServiceManager.main.userServices
            settingsVC.otherServices = SherlockServiceManager.main.otherServices
            settingsVC.transitioningDelegate = self
            present(settingsVC, animated: true)
        }
    }
    
}


// MARK: HistoryVCDDelegate
extension SearchViewController: HistoryVCDDelegate {
    func execute(search: String) {
        query = search
        queryToExecute = true
    }
    
}

// MARK: UIViewControllerTransitioningDelegate
extension SearchViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let _ = presented as? HistoryViewController {
            return newModal
        } else if let _ = presented as? SettingsViewController{
            return flipTransition
        } else {
            return present
        }
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        if let _ = dismissed as? HistoryViewController {
            return unwindNewModal
        } else if let _ = dismissed as? SettingsViewController {
            return unwindFlipTransition
        } else {
            return dissmiss
        }
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        if let _ = animator as? UnwindPushTransition {
            return interactor.hasStarted ? interactor : nil
        } else {
            return modalInteractor.hasStarted ? modalInteractor : nil
        }
    }
}
