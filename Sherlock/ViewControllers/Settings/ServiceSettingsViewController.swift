//
//  SettingsViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/4/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class ServiceSettingsViewController: SherlockSwipeViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var settingsNavBar: UIGradientView!
    
    var services: [SherlockService]!
    var otherServices: [SherlockService]! // services the user hasn't enabled
    
    
    // header titles
    let headers = ["Automatic Ordering", "Enabled Services", "Available Services"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        settingsNavBar.set(colors: ApplicationConstants._sherlockGradientColors)
        tableView.setEditing(true, animated: false)
        
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(SherlockSwipeViewController.didPan(_:)))
        settingsNavBar.isUserInteractionEnabled = true
        settingsNavBar.addGestureRecognizer(gestureRecognizer)
    }

    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
}

// MARK: Data source
extension ServiceSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        } else if section == 1 {
            return services.count
        } else {
            return otherServices.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            return tableView.dequeueReusableCell(withIdentifier: "autoOrder")!
        }
        
        let settingsCell = tableView.dequeueReusableCell(withIdentifier: "serviceSetting") as! UserServiceTableViewCell
        
        var service: SherlockService
        if indexPath.section == 1 {
            service = self.services[indexPath.row]
        } else {
            service = self.otherServices[indexPath.row]
        }
        settingsCell.set(Service: service)
        return settingsCell
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        if indexPath.section > 0 {
            return true
        } else {
            return false
        }
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        services.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        SherlockSettingsManager.main.updateOrder(ofServices: services)
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return headers[section]
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Sherlock will automatically order search services based on the query."
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .insert{
            // update data source
            let serviceToAdd = otherServices.remove(at: indexPath.row)
            services.append(serviceToAdd)
            
            // update tableview
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.insertRows(at: [IndexPath(row: services.count - 1, section: 1)], with: .top)
            tableView.endUpdates()
        }
        
        // update settings
        SherlockSettingsManager.main.update(Services: services, otherServices: otherServices)
    }
    
    
}

extension ServiceSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        if indexPath.section == 1 {
            return UITableViewCell.EditingStyle.delete
        } else if indexPath.section == 2 {
            return UITableViewCell.EditingStyle.insert
        } else {
            return UITableViewCell.EditingStyle.none
        }
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deletion = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            print("deleting")
            // update data source
            let removedService = self.services.remove(at: indexPath.row)
            self.otherServices.append(removedService)
            
            // update tableview
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [IndexPath(row: self.otherServices.count - 1, section: 2)], with: .top)
            tableView.endUpdates()
            
            // update model
            SherlockSettingsManager.main.update(Services: self.services, otherServices: self.otherServices)
        }
        return [deletion]
    }
    
    

}
