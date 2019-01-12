//
//  ShortcutComposeViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/11/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class ShortcutComposeViewController: UIViewController {
    // outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UIGradientView!
    @IBOutlet weak var saveButton: UIButton!
    
    // data
    var shortcut: SherlockShortcut?
    var shortcutServices = [SherlockService]()
    var otherServices = [SherlockService]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.set(colors: ApplicationConstants._sherlockGradientColors)
        saveButton.isEnabled = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setEditing(true, animated: false)
        
        loadServices()
    }
    
    func loadServices(){
        var shortcutServicesSet = Set<serviceType>()
        if let shortcutObj = shortcut {
            let serviceMapping = SherlockServiceManager.main.servicesMapping
            let services = shortcutObj.services
            for service in services {
                shortcutServicesSet.insert(service)
                shortcutServices.append(serviceMapping[service]!)
            }
        }
        
        let allServices = SherlockServiceManager.main.allServices
        for serviceObj in allServices {
            if !shortcutServicesSet.contains(serviceObj.type) {
                otherServices.append(serviceObj)
            }
        }
        
    }
    

    @IBAction func cancelButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
}

// MARK: TableView Data source
extension ShortcutComposeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return shortcutServices.count
        } else {
            return otherServices.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        return UITableViewCell()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    
}

// MARK: TableView Delegate
extension ShortcutComposeViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 1 {
            return UITableViewCell.EditingStyle.delete
        } else if indexPath.section == 2 {
            return UITableViewCell.EditingStyle.insert
        } else {
            return UITableViewCell.EditingStyle.none
        }
    }
}


