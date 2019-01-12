//
//  ShortcutSettingsViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/11/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class ShortcutSettingsViewController: SherlockSwipeViewController {
    // outlets
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var navBar: UIGradientView!
    
    // data
    var shortcuts: [SherlockShortcut]!
    var addButtonIndex = 0
    
    // transitions
    let modalTransition = NewModal()
    let modalDismiss = UnwindNewModal()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.set(colors: ApplicationConstants._sherlockGradientColors)
        tableView.dataSource = self
        tableView.delegate = self
        
        shortcuts = SherlockShortcutManager.main.shortcuts
        addButtonIndex = shortcuts.count
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: Navigation
extension ShortcutSettingsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? ShortcutComposeViewController else {
            return
        }
        destinationVC.transitioningDelegate = self
        // TODO: pass any selected shortcut here
    }
}

// MARK: TableView Data Source
extension ShortcutSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return shortcuts.count + 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == addButtonIndex {
            let cell = tableView.dequeueReusableCell(withIdentifier: "addShortcut")!
            return cell
        }
        return UITableViewCell()
    }
    
    
}

// MARK: TableView Delegate
extension ShortcutSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row == addButtonIndex {
            // segue to create shortcut
            performSegue(withIdentifier: "newShortcut", sender: self)
        }
    }
}

// MARK: transitions
extension ShortcutSettingsViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return modalTransition
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return modalDismiss
    }
}
