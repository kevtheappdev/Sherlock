//
//  SettingsViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/5/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class SettingsViewController: UIViewController {

    @IBOutlet weak var versionLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var appIcon: UIImageView!
    @IBOutlet weak var navBar: UIGradientView!
    
    // transitions
    let push = PushTransition()
    let pop = UnwindPushTransition()
    let interactor = PushInteractor()
    
    var services: [SherlockService]!
    var otherServices: [SherlockService]!
    
    let options = ["Services", "Autocomplete", "Shortcuts", "Appearance"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        appIcon.layer.cornerRadius = 15
        appIcon.layer.masksToBounds = true
        navBar.set(colors: ApplicationConstants._sherlockGradientColors)
        
        tableView.dataSource = self
        tableView.delegate = self
        
        loadVersion()
        loadImage()
        NotificationCenter.default.addObserver(self, selector: #selector(SettingsViewController.loadImage), name: .appearanceChanged, object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        services = SherlockServiceManager.main.userServices
        otherServices = SherlockServiceManager.main.otherServices
    }
    
    func loadVersion(){
        guard
            let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String,
            let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
            else {
                return
            }
        
        versionLabel.text = "Version \(version) | Build \(build)"
    }
    
    @objc func loadImage(){
        appIcon.image = UIImage(named: "\(ApplicationConstants.currentColorKey)_background.png")
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // TODO: try and avoid this mess...
        if let destVC = segue.destination as? ServiceSettingsViewController {
            destVC.transitioningDelegate = self
            destVC.interactor = interactor
            destVC.services = services
            destVC.otherServices = otherServices
        } else if let destVC = segue.destination as? AutocompleteSettingsViewController {
            destVC.transitioningDelegate = self
            destVC.interactor = interactor
            destVC.services = services
        } else if let destVC = segue.destination as? SherlockSwipeViewController {
            destVC.interactor = interactor
            destVC.transitioningDelegate = self
        }
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        get {
            return .lightContent
        }
    }
}

// MARK: TableView Data source
extension SettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return options.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "topLevel")!
        
        cell.textLabel?.text = options[indexPath.row]
        return cell
    }
    
}

// MARK: TableView Delegate
extension SettingsViewController:  UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        if  indexPath.row == 0 {
            performSegue(withIdentifier: "toServices", sender: self)
        } else if indexPath.row == 1 {
            performSegue(withIdentifier: "toAutocomplete", sender: self)
        } else if indexPath.row == 2 {
            performSegue(withIdentifier: "toShortcuts", sender: self)
        } else if indexPath.row == 3 {
            performSegue(withIdentifier: "toAppearance", sender: self)
        }
    }
}

// MARK: Transition
extension SettingsViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return push
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return pop
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
