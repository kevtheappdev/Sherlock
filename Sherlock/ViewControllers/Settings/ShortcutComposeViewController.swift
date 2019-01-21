//
//  ShortcutComposeViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/11/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit
import Intents
import IntentsUI

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
    var editMode = false {
        didSet {
            tableView.allowsSelectionDuringEditing = editMode
        }
    }
    
    var editMade = false
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
    
    
    //keyboard
    var keyboardShown = false
    var keyboardHeight: CGFloat?
    var keyboardAdjusted = false
    var ogTblViewFrame: CGRect?
    var initialLayoutComplete = false
    
    // cell UI elements
    weak var textField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.set(colors: ApplicationConstants._sherlockGradientColors)
        toggleSaveButton()
        tableView.dataSource = self
        tableView.delegate = self
        tableView.setEditing(true, animated: false)
        
        // listen for keyboard
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardAppeared(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardDissapeared(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        loadServices()
    }
    
    override func viewDidLayoutSubviews() {
        initialLayoutComplete = true
        layoutForKeyboard()
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
    
    // MARK: Keyboard notifications
    // TODO: break this out into a library of sorts
    @objc func keyboardAppeared(notification: NSNotification){
        if keyboardShown { return }
        keyboardShown = true
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            keyboardHeight =  keyboardFrame.cgRectValue.size.height
            if initialLayoutComplete {
                layoutForKeyboard()
            }
        }
    }
    
    @objc func keyboardDissapeared(notification: NSNotification){
        if !keyboardShown {return}
        keyboardShown = false
        keyboardAdjusted = false
        if let ogFrame = ogTblViewFrame {
            view.frame = ogFrame
        }
    }
    
    func layoutForKeyboard(){
        if let kbdHeight = keyboardHeight {
            if !keyboardShown || keyboardAdjusted {return}
            ogTblViewFrame = view.frame
            let fullHeight = view.frame.height
            keyboardAdjusted = true
            view.frame = CGRect(origin: view.frame.origin, size: CGSize(width: UIScreen.main.bounds.width, height: fullHeight - kbdHeight))
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
        if editMade {
            let alert = UIAlertController(title: "Cancel", message: "Are you sure you would like to cancel without saving?", preferredStyle: .actionSheet)
            let yesAction = UIAlertAction(title: "Yes", style: .destructive, handler:{(action) in
                self.dismiss(animated: true, completion: nil)
            })
            let continueAction = UIAlertAction(title: "No", style: .cancel, handler: nil)
            alert.addAction(yesAction)
            alert.addAction(continueAction)
            present(alert, animated: true, completion: nil)
        } else {
            dismiss(animated: true, completion: nil)
        }
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
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
}

// MARK: TableView Data source
extension ShortcutComposeViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 || section == 3 || section == 4 {
            return 1
        } else if section == 1 {
            return shortcutServices.count
        } else {
            return otherServices.count
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "shortcutEdit") as! ShortcutComposeTableViewCell
            cell.textField.delegate = self
            textField = cell.textField
            cell.textField.text = shortcutText
            cell.textField.becomeFirstResponder()
            return cell
        } else if indexPath.section == 3 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "siri")!
            cell.contentView.layer.opacity = servicesSet && textSet ? 1.0 : 0.4
            return cell
        } else if indexPath.section == 4 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "delete")!
            cell.contentView.layer.opacity = servicesSet && textSet ? 1.0 : 0.4
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
        return 5
    }
    
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        return indexPath.section == 1
    }
    
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
        shortcutServices.swapAt(sourceIndexPath.row, destinationIndexPath.row)
        editMade = true
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
            editMade = true
        }
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section == 0 {
            return "Shortcut text"
        } else if section == 1 {
            return "Shortcut Services"
        } else if section == 2 {
            return "Services"
        } else if section == 3 {
            return "Siri"
        } else {
            return nil
        }
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        if section == 0 {
            return "Up to 15 characters, no spaces."
        } else if section == 1 {
            return "Services that will be searched when the shortcut text is entered"
        }
        
        return nil
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
            self.editMade = true
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
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 4 && textSet && servicesSet {
            let alert = UIAlertController(title: "Delete", message: "Are you sure would like to delete this shortcut?", preferredStyle: .actionSheet)
            let deleteAction = UIAlertAction(title: "Delete Shortcut", style: .destructive, handler: {(action) in
                guard let activationText = self.shortcutText else {
                    fatalError("can't delete it if its not there dum dum")
                }
                SherlockShortcutManager.main.delete(Shortcut: activationText)
                self.dismiss(animated: true, completion: nil)
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alert.addAction(cancelAction)
            alert.addAction(deleteAction)
            present(alert, animated: true)
        } else if indexPath.section == 3 && shortcut != nil {
            let activity = SherlockShortcutManager.main.createUserActivity(withShortcut: shortcut!)
            let activityShortcut = INShortcut(userActivity: activity)
            let vc = INUIAddVoiceShortcutViewController(shortcut: activityShortcut)
            vc.delegate = self
            present(vc, animated: true)
        }
    }
    
}

// MARK: Voice Delegate
extension ShortcutComposeViewController: INUIAddVoiceShortcutViewControllerDelegate {
    func addVoiceShortcutViewController(_ controller: INUIAddVoiceShortcutViewController, didFinishWith voiceShortcut: INVoiceShortcut?, error: Error?) {
        dismiss(animated: true, completion: nil)
    }
    
    func addVoiceShortcutViewControllerDidCancel(_ controller: INUIAddVoiceShortcutViewController) {
        dismiss(animated: true, completion: nil)
    }
    
    
}

// MARK: Textfield delegate
extension ShortcutComposeViewController: UITextFieldDelegate {
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        editMade = true
        
        let prohibited = [" ", "\n"]
        for c in prohibited {
            if string.contains(c) {
                return false
            }
        }
        
        guard let oldInput = textField.text else { return true}
        let newInput = NSString(string: oldInput).replacingCharacters(in: range, with: string)
        if oldInput.count == 15 && newInput.count > oldInput.count { return false }
        shortcutText = newInput
        
        if !newInput.isEmpty {
            textSet = true
        } else {
            textSet = false
        }
        
        return true
    }
}


