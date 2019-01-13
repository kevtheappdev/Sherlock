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
    @IBOutlet weak var titleLabel: UILabel!
    
    // data
    var shortcut: SherlockShortcut?
    var shortcutText: String?
    var originalShortcutText: String? // for editing
    var shortcutServices = [SherlockService]()
    var otherServices = [SherlockService]()
    var editMode = false
    var servicesSet = false {
        didSet {
            toggleSaveButton()
        }
    }
    var textSet = false {
        didSet {
            toggleSaveButton()
        }
    }
    
    weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.set(colors: ApplicationConstants._sherlockGradientColors)
        toggleSaveButton()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setEditing(true, animated: false)
        
        loadServices()
    }
    
    func loadServices(){
        var shortcutServicesSet = Set<serviceType>()
        if let shortcutObj = shortcut {
            textSet = true
            servicesSet = true
            editMode = true
            
            shortcutText = shortcutObj.activationText
            originalShortcutText = shortcutText
            titleLabel.text = "Edit Shortcut"
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
    
    @IBAction func saveButtonPressed(_ sender: Any) {
        var serviceTypes = [serviceType]()
        for service in shortcutServices {
            serviceTypes.append(service.type)
        }
        
        let shortcut = SherlockShortcut(activationText: textField.text!, services: serviceTypes)
        
        if !editMode {
            SherlockShortcutManager.main.add(Shortcut: shortcut)
        } else {
            SherlockShortcutManager.main.update(Shortcut: originalShortcutText!, updatedShortcut: shortcut)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    @IBAction func cancelButtonPressed(_ sender: Any) {
        // TODO: have a pop up if user has inputted information
        dismiss(animated: true, completion: nil)
    }
    
    func toggleSaveButton(){
        if servicesSet && textSet {
            saveButton.isEnabled = true
            saveButton.layer.opacity = 1.0
        } else {
            saveButton.isEnabled = false
            saveButton.layer.opacity = 0.4
        }
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
        if indexPath.section == 0{
            let cell = tableView.dequeueReusableCell(withIdentifier: "shortcutEdit") as! ShortcutComposeTableViewCell
            cell.textField.delegate = self
            textField = cell.textField
            cell.textField.text = shortcutText
            cell.textField.becomeFirstResponder()
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "serviceSetting") as! UserServiceTableViewCell
            var service: SherlockService
            if indexPath.section == 1 {
                service = shortcutServices[indexPath.row]
            } else {
                service = otherServices[indexPath.row]
            }
            
            cell.set(Service: service)
            return cell
        }
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .insert {
            let addedService = otherServices.remove(at: indexPath.row)
            shortcutServices.append(addedService)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .automatic)
            tableView.insertRows(at: [IndexPath(row: shortcutServices.count - 1, section: 1)], with: .left)
            tableView.endUpdates()
            servicesSet = true
        }
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
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 45
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deleteAction = UITableViewRowAction(style: .destructive, title: "Delete", handler: {(action, indexPath) in
            let removedService = self.shortcutServices.remove(at: indexPath.row)
            self.otherServices.insert(removedService, at: removedService.ogIndex)
            tableView.beginUpdates()
            tableView.deleteRows(at: [indexPath], with: .fade)
            tableView.insertRows(at: [IndexPath(row: removedService.ogIndex, section: 2)], with: .left)
            tableView.endUpdates()
            self.servicesSet = self.shortcutServices.count > 0
        })
        
        return [deleteAction]
    }
    
}

// MARK: Textfield delegate
extension ShortcutComposeViewController: UITextFieldDelegate {
    // TODO: handle the enabling and disabling of the save button
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        let prohibited = [" ", "\n"]
        for c in prohibited {
            if string.contains(c) {
                return false
            }
        }
        
        guard let oldInput = textField.text else { return true}
        let newInput = NSString(string: oldInput).replacingCharacters(in: range, with: string)
        
        if !newInput.isEmpty {
            textSet = true
        } else {
            textSet = false
        }
        
        return true
    }
}


