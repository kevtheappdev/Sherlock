//
//  AppearanceSettingsViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/5/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class AppearanceSettingsViewController: UIViewController {

    @IBOutlet weak var navBar: UIGradientView!
    @IBOutlet weak var tableView: UITableView!
    var appearanceKeys = Array(ApplicationConstants.colors.keys)
    let appearanceColorsDict = ApplicationConstants.colors
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        navBar.set(colors: ApplicationConstants._sherlockGradientColors)
        
        appearanceKeys.sort()
    }
    
    @IBAction func backButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    
}

extension AppearanceSettingsViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appearanceKeys.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let appearanceCell = tableView.dequeueReusableCell(withIdentifier: "appearanceCell") as! AppearanceTableViewCell
        let key = appearanceKeys[indexPath.row]
        appearanceCell.set(Color: appearanceColorsDict[key]!, name: key)
        if key == ApplicationConstants.currentColorKey {
            appearanceCell.accessoryType = .checkmark
        } else {
            appearanceCell.accessoryType = .none
        }
        return appearanceCell
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return "pick a color any color"
    }
}

extension AppearanceSettingsViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 50
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        SherlockSettingsManager.main.appearanceColor = appearanceKeys[indexPath.row]
        tableView.reloadData()
        NotificationCenter.default.post(name: .appearanceChanged, object: nil)
    }
    
}
