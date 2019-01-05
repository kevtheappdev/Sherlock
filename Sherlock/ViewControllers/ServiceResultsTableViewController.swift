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
    let numAcResults = ApplicationConstants._numACResults

    init(services: [SherlockService]){
        self.services = services
        super.init(nibName: nil, bundle: nil)
        initReducedMode()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func initReducedMode(){
        for service in services { // reduced mode for all searches
            reducedModeDict[service.type] = true
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.separatorStyle = .none
        
        // subscribe to SherlockServiceManager delegate
        SherlockServiceManager.main.delegate = self
        
        // register autocomplete cells
        tableView.register(UINib(nibName: "AutoCompleteTableViewCell", bundle: nil), forCellReuseIdentifier: "autocomplete")
        
        // listen for keyboard appearance
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardAppeared(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDissapeared(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.services = SherlockServiceManager.main.services
        tableView.reloadData()
        initReducedMode() // TODO: look into better way than calling this every time the data changes
    }
    
    override func viewDidLayoutSubviews() {
        if let kbdHeight = keyboardHeight {
            if !keyboardShown || keyboardAdjusted {return}
            ogTableFrame = view.frame
            let fullHeight = view.frame.height
            keyboardAdjusted = true
            view.frame = CGRect(origin: view.frame.origin, size: CGSize(width: UIScreen.main.bounds.width, height: fullHeight - kbdHeight))
        }
    }
    
    // MARK: - Keyboard notifications
    @objc
    func keyboardAppeared(notification: NSNotification) {
        if keyboardShown {return}
        keyboardShown =  true
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardHeight =  keyboardFrame.cgRectValue.size.height
        }
    }
    
    @objc
    func keyboardDissapeared(notification: NSNotification) {
        if !keyboardShown {return}
        keyboardShown = false
        keyboardAdjusted = false
        if let ogFrame = ogTableFrame {
            view.frame = ogFrame
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return services.count
    }
    
    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = Bundle.main.loadNibNamed("SearchServiceHeader", owner: self, options: nil)?.first as? SearchServiceHeader else {
            return UIView()
        }
        
        let service = services[section]
        headerView.delegate = self
        headerView.tag = section
        headerView.set(service: service)
        return headerView
    }
    
    override func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 85
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let acHandler = services[section].automcompleteHandler {
            let suggestionCount = acHandler.suggestions.count
            let type = services[section].type
            if suggestionCount > numAcResults && reducedModeDict[type]! {
                return numAcResults + 1
            } else {
                return acHandler.suggestions.count
            }
        }
        
        return 0

    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let type = services[indexPath.section].type
        if reducedModeDict[type]! && indexPath.row >= numAcResults {
            guard let cell = Bundle.main.loadNibNamed("ChevronCell", owner: self, options: nil)?.first as? UITableViewCell else {
                return UITableViewCell()
            }
            
            return cell
        }
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "autocomplete", for: indexPath) as! AutoCompleteTableViewCell
        let suggestion = services[indexPath.section].automcompleteHandler!.suggestions[indexPath.row]
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
        let type = services[indexPath.section].type
        if reducedModeDict[type]! && indexPath.row >= numAcResults {
            reducedModeDict[type] = false
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
            tableView.insertRows(at: createIndexPaths(forSection: indexPath.section), with: UITableView.RowAnimation.automatic)
            tableView.endUpdates()
            return
        }
        let service = services[indexPath.section]
        guard let querySuggestion = service.automcompleteHandler?.suggestions[indexPath.row] else {
            return
        }
        delegate?.updated(query: querySuggestion.suggestion)
        delegate?.didSelect(service: service)
    }

    
    private func createIndexPaths(forSection section: Int) -> [IndexPath]{
        let service = services[section]
        guard let acSuggest = service.automcompleteHandler?.suggestions else {
            return []
        }
        
        var indexPaths = [IndexPath]()
        for i in numAcResults..<acSuggest.count {
            let ip = IndexPath(row: i, section: section)
            indexPaths.append(ip)
        }
        
        return  indexPaths
    }
    

}

// MARK: SherlockServiceManagerDelegate
extension ServiceResultsTableViewController: SherlockServiceManagerDelegate {
    func resultsCleared() {
        initReducedMode()
    }
    
    func resultsChanged(_ services: [SherlockService]) {
        if reloadingResults {
            return // skip this reload if data source is updating.
        }
        
        self.services = services
        // debug statements
        print("\nupdated services:")
        for service in services {
            print("\(service.type.rawValue):  \(service.weight)")
        }
        
        
        CATransaction.begin()
        reloadingResults = true
        CATransaction.setCompletionBlock({() in
            self.reloadingResults = false
        })
        tableView.reloadData()
        tableView.layoutIfNeeded()
        CATransaction.commit()
    }
}

// MARK: SearchServiceHeaderDelegate
extension ServiceResultsTableViewController: SearchServiceHeaderDelegate {
    func tapped(index: Int) {
        delegate?.didSelect(service: services[index])
    }
    
}


