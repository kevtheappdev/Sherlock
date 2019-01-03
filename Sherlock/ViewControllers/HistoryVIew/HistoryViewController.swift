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
    
    @IBOutlet weak var clearAllButton: UIButton!
    // transitions
    let push = PushTransition()
    let unwindPush = UnwindPushTransition()
    let interactor = PushInteractor()
    var modalInteractor: NewModalInteractor?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        clearAllButton.isHidden = true
        historyNavBar.set(colors: ApplicationConstants._sherlockGradientColors)
        view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // interactive transition
        let edgeRecognizer = UIPanGestureRecognizer(target: self, action: #selector(HistoryViewController.didPan(_:)))
        historyNavBar.addGestureRecognizer(edgeRecognizer)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadHistory()
        clearAllButton.isHidden = !(dateStrings.count > 0)
        tableView.reloadData()
    }
    
    @IBAction func doneButtonPressed(_ sender: Any) {
        dismiss(animated: true, completion: nil)
    }
    @IBAction func clearAllButtonPressed(_ sender: Any) {
        let alert =  UIAlertController(title: "Clear History", message: "Are you sure you would like to delete all history?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive, handler: {(_) in
            self.deleteAll()
        }))
        present(alert, animated: true, completion: nil)
    }
    
    func loadHistory(){
        // clear previous
        dateStrings = []
        historyEntries = [:]
        
        guard let searchEntries = SherlockHistoryManager.main.getSearchEntries() else {return}
        guard let webEntries = SherlockHistoryManager.main.getWebEntries() else {return}
        
        // combine both and sort
        var allHistoryEntries = [NSManagedObject]()
        
        for searchEntry in searchEntries {
            allHistoryEntries.append(searchEntry)
        }
        
        for webEntry in webEntries {
            allHistoryEntries.append(webEntry)
        }
        
        allHistoryEntries.sort(by: sortEntries(a:b:))
        
        for historyEntry in allHistoryEntries {
            let date = historyEntry.value(forKey: "datetime") as! Date
            let dateStr = extractStrFrom(date: date)
            var arr = historyEntries[dateStr]
            
            if arr == nil {
                arr = []
                historyEntries[dateStr] = arr
                dateStrings.append(dateStr)
            }
            arr!.append(historyEntry)
            historyEntries[dateStr] = arr
        }
        
    }
    
    func deleteAll(){
        for (_, entries) in historyEntries {
            for entry in entries {
                SherlockHistoryManager.main.delete(entry: entry)
            }
        }
        
        historyEntries.removeAll()
        dateStrings.removeAll()
        
        tableView.reloadData()
    }
    
    func sortEntries(a: NSManagedObject, b: NSManagedObject) -> Bool {
        let aDate = a.value(forKey: "datetime") as! Date
        let bDate = b.value(forKey: "datetime") as! Date
        return aDate.compare(bDate) == .orderedDescending
    }
    
    func extractStrFrom(date: Date) -> String {
        let dateFmt = DateFormatter()
        dateFmt.timeZone = TimeZone.ReferenceType.default
        dateFmt.dateFormat = "MMM dd"
        
        let today = Date()
        let todayStr = dateFmt.string(from: today)
        let dateStr = dateFmt.string(from: date)
        if dateStr == todayStr {
            return "Today"
        }
        
        // yesterday
        let calendar = Calendar.current
        let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
        let yesterdayStr = dateFmt.string(from: yesterday)
        
        if dateStr == yesterdayStr {
            return "Yesterday"
        }
        
        return dateStr
    }
    
    @objc func didPan(_ sender: UIPanGestureRecognizer){
        let percenTrheshold: CGFloat = 0.3
        let translation = sender.translation(in: view)
        let verticalMovement = translation.y / view.bounds.height
        let downwardMovement = fmax(Float(verticalMovement), 0.0)
        let downwardMovementPercent = fminf(downwardMovement, 1.0)
        let progress = CGFloat(downwardMovementPercent)
        
        guard let interactor = modalInteractor else {return}
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
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
        let dateStr = dateStrings[section]
        return historyEntries[dateStr]!.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        
        let dateStr = dateStrings[indexPath.section]
        let entry = historyEntries[dateStr]![indexPath.row]
        if let searchEntry = entry as? SearchHistoryEntry {
            let cell = tableView.dequeueReusableCell(withIdentifier: "searchEntry") as!  QueryTableViewCell
            cell.queryLabel.text = searchEntry.query
            return cell
        } else {
            let webEntry = entry as! WebHistoryEntry
            let cell = tableView.dequeueReusableCell(withIdentifier: "webEntry")  as! WebTableViewCell
            cell.siteUrlLabel.text = webEntry.url
            cell.siteTitleLabel.text = webEntry.title
            return cell
        }

    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return dateStrings.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = Bundle.main.loadNibNamed("HistoryHeaderView", owner: self, options: nil)?.first as? HistoryHeaderView else {
            return UIView()
        }
        
        headerView.dateStr = dateStrings[section]
        headerView.delegate = self
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 55
    }
    
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

    func tableView(_ tableView: UITableView, editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        return UITableViewCell.EditingStyle.delete
    }
    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        let deletion = UITableViewRowAction(style: .destructive, title: "Delete") { (action, indexPath) in
            let dateStr = self.dateStrings[indexPath.section]
            var arr = self.historyEntries[dateStr]!
            var deleteObject: NSManagedObject
            if arr.count == 1 {
                // remove section
                deleteObject = arr[0]
                self.dateStrings.remove(at: indexPath.section)
                self.historyEntries.removeValue(forKey: dateStr)
                tableView.beginUpdates()
                tableView.deleteSections([indexPath.section], with: UITableView.RowAnimation.automatic)
            } else {
                if indexPath.row >=  arr.count {return}
                deleteObject = arr.remove(at: indexPath.row)
                self.historyEntries[dateStr] = arr
                tableView.beginUpdates()
                tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                tableView.endUpdates()
            }
            
            SherlockHistoryManager.main.delete(entry: deleteObject)
            
         }
        return [deletion]
    }
}

extension HistoryViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 85
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        let selectedDateStr = dateStrings[indexPath.section]
        let selectedEntry = historyEntries[selectedDateStr]![indexPath.row]
        if let webEntry =  selectedEntry as? WebHistoryEntry {
            let url = URL(string: webEntry.url!)!
            let webVC = WebResultViewController(url: url, recordHistory: false)
            SherlockHistoryManager.main.update(entry: webEntry)
            webVC.transitioningDelegate = self
            webVC.interactor = interactor
            present(webVC, animated: true)
        } else {
            let searchEntry = selectedEntry as! SearchHistoryEntry
            SherlockHistoryManager.main.update(entry: searchEntry)
            SherlockServiceManager.main.begin(Query: searchEntry.query!)
            dismiss(animated: true, completion: nil)
            delegate?.execute(search: searchEntry.query!)
        }
    }
}


extension HistoryViewController: HistorySectionDelegate {
    func deleteButtonPressed(dateStr: String) {
        let deleteIndex = dateStrings.index(of: dateStr)!
        dateStrings.remove(at: deleteIndex)
        let deletedEntries = historyEntries.removeValue(forKey: dateStr)!
        tableView.beginUpdates()
        tableView.deleteSections([deleteIndex], with: UITableView.RowAnimation.automatic)
        tableView.endUpdates()
        
        for entry in deletedEntries {
            SherlockHistoryManager.main.delete(entry: entry)
        }
    }
    
}

extension HistoryViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return  push
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return unwindPush
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactor.hasStarted ? interactor : nil
    }
}
