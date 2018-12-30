//
//  ServiceResultsTableViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/21/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class ServiceResultsTableViewController: UITableViewController {
    var services: [SherlockService]
    var ogTableFrame: CGRect?
    var keyboardShown = false
    var keyboardAdjusted = false
    weak var delegate: ServiceResultDelegate?
    var keyboardHeight: CGFloat?
    var reloadingResults = false
    var reducedModeDict: [serviceType: Bool] = [:]

    init(services: [SherlockService]){
        self.services = services
        super.init(nibName: nil, bundle: nil)
        self.initReducedMode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initReducedMode(){
        for service in self.services { // reduced mode for all searches
            self.reducedModeDict[service.type] = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none
        
        // subscribe to SherlockServiceManager delegate
        SherlockServiceManager.main.delegate = self
        
        // register autocomplete cells
        self.tableView.register(UINib(nibName: "AutoCompleteTableViewCell", bundle: nil), forCellReuseIdentifier: "autocomplete")
        
        // listen for keyboard appearance
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardAppeared(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDissapeared(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    
    override func viewDidLayoutSubviews() {
        if let kbdHeight = self.keyboardHeight {
            if !self.keyboardShown || self.keyboardAdjusted {return}
            self.ogTableFrame = self.view.frame
            let fullHeight = self.view.frame.height
            self.keyboardAdjusted = true
            self.view.frame = CGRect(origin: self.view.frame.origin, size: CGSize(width: UIScreen.main.bounds.width, height: fullHeight - kbdHeight))
        }
    }
    
    // MARK: - Keyboard notifications
    @objc
    func keyboardAppeared(notification: NSNotification) {
        if self.keyboardShown {return}
        self.keyboardShown =  true
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            self.keyboardHeight =  keyboardFrame.cgRectValue.size.height
        }
    }
    
    @objc
    func keyboardDissapeared(notification: NSNotification) {
        if !self.keyboardShown {return}
        self.keyboardShown = false
        self.keyboardAdjusted = false
        if let ogFrame = self.ogTableFrame {
            self.view.frame = ogFrame
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.services.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = Bundle.main.loadNibNamed("SearchServiceHeader", owner: self, options: nil)?.first as? SearchServiceHeader else {
            return UIView()
        }
        
        let service = self.services[section]
        headerView.delegate = self
        headerView.tag = section
        headerView.set(service: service)
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 85
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let acHandler = self.services[section].automcompleteHandler {
            let suggestionCount = acHandler.suggestions.count
            let type = self.services[section].type
            if suggestionCount > _numACResults && self.reducedModeDict[type]! { // TODO: figure out how to get around potential error here
                return _numACResults + 1
            } else {
                return acHandler.suggestions.count
            }
        }
        
        return 0

    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = self.services[indexPath.section].type
        if self.reducedModeDict[type]! && indexPath.row >= _numACResults {
            guard let cell = Bundle.main.loadNibNamed("ChevronCell", owner: self, options: nil)?.first as? UITableViewCell else {
                return UITableViewCell()
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "autocomplete", for: indexPath) as! AutoCompleteTableViewCell
        let suggestion = self.services[indexPath.section].automcompleteHandler!.suggestions[indexPath.row]
        if suggestion.url != nil {
            cell.iconImageView.image  = UIImage(imageLiteralResourceName: "file-text.png")
        } else {
            cell.iconImageView.image = UIImage(imageLiteralResourceName: "search.png")
        }
        cell.suggestionLabel.text = suggestion.suggestion
        return cell
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let type = self.services[indexPath.section].type
        if self.reducedModeDict[type]! && indexPath.row >= _numACResults {
            self.reducedModeDict[type] = false
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            tableView.insertRows(at: self.createIndexPaths(forSection: indexPath.section), with: UITableView.RowAnimation.automatic)
            tableView.endUpdates()
            return
        }
        let service = self.services[indexPath.section]
        guard let querySuggestion = service.automcompleteHandler?.suggestions[indexPath.row] else {
            return
        }
        self.delegate?.updated(query: querySuggestion.suggestion)
        self.delegate?.didSelect(service: service)
    }

    
    private func createIndexPaths(forSection section: Int) -> [IndexPath]{
        let service = self.services[section]
        guard let acSuggest = service.automcompleteHandler?.suggestions else {
            return []
        }
        
        var indexPaths = Array<IndexPath>()
        for i in _numACResults..<acSuggest.count {
            let ip = IndexPath(row: i, section: section)
            indexPaths.append(ip)
        }
        
        return  indexPaths
    }
    

}

extension ServiceResultsTableViewController: SherlockServiceManagerDelegate {
    func autocompleteCleared() {
        self.initReducedMode()
    }
    
    func autocompleteResultsChanged(_ services: [SherlockService]) {
        if self.reloadingResults { // TOOD: maybe replace with timer callback
            return // skip this reload if data source is updating.
        }
        
        self.services = services
        
        CATransaction.begin()
        self.reloadingResults = true
        CATransaction.setCompletionBlock({() in
            self.reloadingResults = false
        })
        self.tableView.reloadData()
        self.tableView.layoutIfNeeded()
        CATransaction.commit()
    }
}

extension ServiceResultsTableViewController: SearchServiceHeaderDelegate {
    func tapped(index: Int) {
        self.delegate?.didSelect(service: self.services[index])
    }
    
}


