//
//  HistoryViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/24/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import CoreData

class HistoryViewController: UIViewController {
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var historyNavBar: UIGradientView!
    var historyEntries: [String: [NSManagedObject]] = [:]
    var dateStrings: [String] = []
    weak var delegate: HistoryVCDDelegate?
    
    // transitions
    let push = PushTransition()
    let unwindPush = UnwindPushTransition()
    let interactor = PushInteractor()
    var modalInteractor: NewModalInteractor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.dataSource = self
        self.tableView.delegate = self
        self.historyNavBar.set(colors: _sherlockGradientColors)
        self.view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // interactive transition
        let edgeRecognizer = UIPanGestureRecognizer(target: self, action: #selector(HistoryViewController.didPan(_:)))
        self.view.addGestureRecognizer(edgeRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.loadHistory()
        self.tableView.reloadData()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func loadHistory(){
        // clear previous
        self.dateStrings = []
        self.historyEntries = [:]
        
        guard let searchEntries = SherlockHistoryManager.main.getSearchEntries() else {return}
        guard let webEntries = SherlockHistoryManager.main.getWebEntries() else {return}
        
        // combine both and sort
        var historyEntries = Array<NSManagedObject>()
        
        for searchEntry in searchEntries {
            historyEntries.append(searchEntry)
        }
        
        for webEntry in webEntries {
            historyEntries.append(webEntry)
        }
        
        historyEntries.sort(by: sortEntries(a:b:))
        
        for historyEntry in historyEntries {
            let date = historyEntry.value(forKey: "datetime") as! Date
            let dateStr = extractStrFrom(date: date)
            var arr = self.historyEntries[dateStr]
            
            if arr == nil {
                arr = []
                self.historyEntries[dateStr] = arr
                self.dateStrings.append(dateStr)
            }
            arr!.append(historyEntry)
            self.historyEntries[dateStr] = arr
            
        }
        
    }
    
    func sortEntries(a: NSManagedObject, b: NSManagedObject) -> Bool {
        let aDate = a.value(forKey: "datetime") as! Date
        let bDate = b.value(forKey: "datetime") as! Date
        return aDate.compare(bDate) == .orderedDescending
    }
    
    func extractStrFrom(date: Date) -> String{
        let dateFmt = DateFormatter()
        dateFmt.timeZone = TimeZone.ReferenceType.default
        dateFmt.dateFormat = "MMM dd"
        return dateFmt.string(from:date)
    }
    
    @objc func didPan(_ sender: UIPanGestureRecognizer){
        let percenTrheshold: CGFloat = 0.3
        let translation = sender.translation(in: self.view)
        let verticalMovement = translation.y / self.view.bounds.height
        let downwardMovement = fmax(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        guard let interactor = self.modalInteractor else {return}
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            self.dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > percenTrheshold
            interactor.update(progress)
        case .ended:
            interactor.hasStarted = false
            if interactor.shouldFinish {
                interactor.finish()
            } else {
                interactor.cancel()
            }
        default:
            break
            
        }
        
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    
}

extension HistoryViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        let dateStr = self.dateStrings[section]
        return self.historyEntries[dateStr]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        
        let dateStr = self.dateStrings[indexPath.section]
        let entry = self.historyEntries[dateStr]![indexPath.row]
        if let searchEntry = entry as? SearchHistoryEntry {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchEntry") as!  QueryTableViewCell
            cell.set(data: searchEntry, index: indexPath, delegate: self)
            return cell
        } else {
            let webEntry = entry as! WebHistoryEntry
            let cell = tableView.dequeueReusableCell(withIdentifier: "webEntry")  as! WebTableViewCell
            cell.set(data: webEntry, index: indexPath, delegate: self)
            return cell
        }

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.dateStrings.count
    }
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.dateStrings[section]
    }
    
}

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedDateStr = self.dateStrings[indexPath.section]
        let selectedEntry = self.historyEntries[selectedDateStr]![indexPath.row]
        if let webEntry =  selectedEntry as? WebHistoryEntry {
            let url = URL(string: webEntry.url!)!
            let webVC = WebResultViewController(url: url, recordHistory: false)
            SherlockHistoryManager.main.update(entry: webEntry)
            webVC.transitioningDelegate = self
            webVC.interactor = self.interactor
            self.present(webVC, animated: true)
        } else {
            let searchEntry = selectedEntry as! SearchHistoryEntry
            SherlockHistoryManager.main.update(entry: searchEntry)
            SherlockServiceManager.main.begin(Query: searchEntry.query!)
            self.dismiss(animated: true, completion: nil)
            self.delegate?.execute(search: searchEntry.query!)
        }
    }
}

extension HistoryViewController: HistoryCellDelegate {
    func deleteButtonPressed(object: NSManagedObject?) {
        if let deletedObject = object { // TODO: Look into making this faster
            // remove from data source
            let dateStr = self.extractStrFrom(date: deletedObject.value(forKey: "datetime") as! Date)
            guard let sectionIndex = self.dateStrings.index(of: dateStr) else {return}
            guard let rowIndex = self.historyEntries[dateStr]!.index(of: deletedObject) else {return}
            var arr = self.historyEntries[dateStr]!
            if arr.count == 1 {
                self.dateStrings.remove(at: sectionIndex)
                self.historyEntries[dateStr] = []
                self.tableView.deleteSections([sectionIndex], with: UITableView.RowAnimation.automatic)
            } else {
                arr.remove(at: rowIndex)
                self.historyEntries[dateStr] = arr
                self.tableView.deleteRows(at: [IndexPath(row: rowIndex, section: sectionIndex)], with: UITableView.RowAnimation.automatic)
            }
            
            // delete from core data
            SherlockHistoryManager.main.delete(entry: deletedObject)
        }
    }
    
}

extension HistoryViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return  self.push
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return self.unwindPush
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.interactor.hasStarted ? self.interactor : nil
    }
}
