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
    var selectedShortcut: SherlockShortcut?
    
    // transitions
    let modalTransition = NewModal()
    let modalDismiss = UnwindNewModal()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navBar.set(colors: ApplicationConstants._sherlockGradientColors)
        tableView.dataSource = self
        tableView.delegate = self
        
        // interactive gesture
        let backGesture = UIPanGestureRecognizer(target: self, action: #selector(SherlockSwipeViewController.didPan(_:)))
        view.addGestureRecognizer(backGesture)

        loadShortcuts()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadShortcuts()
    }
    
    func loadShortcuts(){
        shortcuts = SherlockShortcutManager.main.shortcuts
        addButtonIndex = shortcuts.count
        tableView.reloadData()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }

}

// MARK: Navigation
extension ShortcutSettingsViewController {
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        guard let destinationVC = segue.destination as? ShortcutComposeViewController else {
            return
        }
        destinationVC.transitioningDelegate = self
        destinationVC.shortcut = selectedShortcut
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
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "shortcut") as! ShortcutTableViewCell
            let shortcut = shortcuts[indexPath.row]
            cell.set(Shortcut: shortcut)
            return cell
        }
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "Shortcuts"
    }
    
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        return "Shortcuts allow you to jump to searching a specific service or set of services with a particular set of characters. Tap on one to edit or create a new one."
    }
    
}

// MARK: TableView Delegate
extension ShortcutSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if indexPath.row != addButtonIndex {
            selectedShortcut = shortcuts[indexPath.row]
        } else {
            selectedShortcut = nil
        }
        performSegue(withIdentifier: "newShortcut", sender: self)
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
