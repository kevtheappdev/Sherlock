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
    var cellCache = Dictionary<serviceType, SearchServiceTableViewCell>()
    weak var delegate: ServiceResultDelegate?

    init(services: [SherlockService]){
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.separatorStyle = .none
        
        // listen for keyboard appearance
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardAppeared(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.keyboardDissapeared(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    
    // MARK: - Keyboard notifications
    @objc
    func keyboardAppeared(notification: NSNotification) {
        if self.keyboardShown {return}
        self.keyboardShown =  true
        self.ogTableFrame = self.view.frame
        let fullHeight = self.view.frame.size.height
        if let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardHeight =  keyboardFrame.cgRectValue.size.height
            self.view.frame = CGRect(origin: self.view.frame.origin, size: CGSize(width: UIScreen.main.bounds.width, height: fullHeight - keyboardHeight))
        }
    }
    
    @objc
    func keyboardDissapeared(notification: NSNotification) {
        if !self.keyboardShown {return}
        self.keyboardShown = false
        if let ogFrame = self.ogTableFrame {
            self.view.frame = ogFrame
        }
    }
    

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.services.count
    }

    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let service = self.services[indexPath.row]
        let serviceType = service.type
        var cell = cellCache[serviceType]
        if cell == nil {
            guard let loadCell = Bundle.main.loadNibNamed("SearchServiceCell", owner: self, options: nil)?.first as?  SearchServiceTableViewCell else {
                fatalError("Failed to load searchServiceCell nib.")
            }
            cellCache[serviceType] = loadCell
            cell = loadCell
        }
        
        // Configure the cell...
        cell!.configureCell(withService: service)
        return cell!
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let service = self.services[indexPath.row]
        self.delegate?.didSelect(service: service)
    }


    /*
    // Override to support conditional editing of the table view.
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the specified item to be editable.
        return true
    }
    */

    /*
    // Override to support editing the table view.
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            // Delete the row from the data source
            tableView.deleteRows(at: [indexPath], with: .fade)
        } else if editingStyle == .insert {
            // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
        }    
    }
    */

    /*
    // Override to support rearranging the table view.
    override func tableView(_ tableView: UITableView, moveRowAt fromIndexPath: IndexPath, to: IndexPath) {

    }
    */

    /*
    // Override to support conditional rearranging of the table view.
    override func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
        // Return false if you do not want the item to be re-orderable.
        return true
    }
    */

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */

}
