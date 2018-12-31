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
        self.historyNavBar.set(colors: ApplicationConstants._sherlockGradientColors)
        self.view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        // interactive transition
        let edgeRecognizer = UIPanGestureRecognizer(target: self, action: #selector(HistoryViewController.didPan(_:)))
        self.historyNavBar.addGestureRecognizer(edgeRecognizer)
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
        return self.dateStrings.count
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let headerView = Bundle.main.loadNibNamed("HistoryHeaderView", owner: self, options: nil)?.first as? HistoryHeaderView else {
            return UIView()
        }
        
        headerView.dateStr = self.dateStrings[section]
        headerView.delegate = self
        return headerView
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 85
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
                self.tableView.beginUpdates()
                self.tableView.deleteSections([indexPath.section], with: UITableView.RowAnimation.automatic)
            } else {
                if indexPath.row >=  arr.count {return}
                deleteObject = arr.remove(at: indexPath.row)
                self.historyEntries[dateStr] = arr
                self.tableView.beginUpdates()
                self.tableView.deleteRows(at: [indexPath], with: UITableView.RowAnimation.automatic)
                self.tableView.endUpdates()
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


extension HistoryViewController: HistorySectionDelegate {
    func deleteButtonPressed(dateStr: String) {
        let deleteIndex = self.dateStrings.index(of: dateStr)!
        self.dateStrings.remove(at: deleteIndex)
        let deletedEntries = self.historyEntries.removeValue(forKey: dateStr)!
        self.tableView.beginUpdates()
        self.tableView.deleteSections([deleteIndex], with: UITableView.RowAnimation.automatic)
        self.tableView.endUpdates()
        
        for entry in deletedEntries {
            SherlockHistoryManager.main.delete(entry: entry)
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
