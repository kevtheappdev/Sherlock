//
//  AutocompleteSettingsViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/5/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class AutocompleteSettingsViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UIGradientView!
    
    var services: [SherlockService]! {
        didSet {
            loadAcServices()
        }
    }
    var acServices = [SherlockService]()
    var disabledServices: Set<String>!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        navBar.set(colors: ApplicationConstants._sherlockGradientColors)
    }
    
    func loadAcServices(){
        for service in services {
            if service.automcompleteHandler != nil {
                acServices.append(service)
            }
        }
        
        disabledServices = SherlockSettingsManager.main.disabledAutoComplete
    }

    @IBAction func backButtonPressedd(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

extension AutocompleteSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return acServices.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let tbCell = tableView.dequeueReusableCell(withIdentifier: "autoCompleteCell") as! AutocompleteSettingTableViewCell
        let service = acServices[indexPath.row]
        let acEnabled = !disabledServices.contains(service.type.rawValue)
        tbCell.set(Service: service, autocompleteEnabled: acEnabled)
        return tbCell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "services supporting autocomplete"
    }
}

// MARK: TableView Delegate
extension AutocompleteSettingsViewController: UITableViewDelegate {
    
}


