//
//  SherlockHistoryManager.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/23/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import CoreData

class SherlockHistoryManager: NSObject {
    var managedContext: NSManagedObjectContext!
    static let main = SherlockHistoryManager()
    
    private override init() {
        super.init()
        
        // load managed context
        guard  let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            fatalError("shit is fucked")
        }
        managedContext = appDelegate.persistentContainer.viewContext
    }
    
    // save methods
    func log(webPage url: URL, title: String){
        let webEntry = WebHistoryEntry(context: managedContext)
        webEntry.datetime = Date()
        webEntry.url = url.absoluteString
        webEntry.title =  title
        save()
    }
    
    func log(search: String){
        let searchEntry =  SearchHistoryEntry(context: managedContext)
        searchEntry.query = search
        searchEntry.datetime = Date()
        save()
    }
    
    private func save(){
        do {
            try managedContext.save()
        } catch let error {
            print ("Failed to save with error: \(error)")
            return
        }
    }
    
    // retreival methods
    func getWebEntries()-> [WebHistoryEntry]?{
        let request = NSFetchRequest<WebHistoryEntry>(entityName: "WebHistoryEntry")
        var result: [WebHistoryEntry]
        do {
            result = try managedContext.fetch(request)
        } catch let error {
            print("failed to retreive web entries with error: \(error)")
            return nil
        }
        return result
    }
    
    func getSearchEntries()-> [SearchHistoryEntry]? {
        let request = NSFetchRequest<SearchHistoryEntry>(entityName: "SearchHistoryEntry")
        var result: [SearchHistoryEntry]
        do {
            result = try managedContext.fetch(request)
        } catch let error {
            print("failed to retreive search entries with error: \(error)")
            return nil
        }
        return result
    }
    
    // update
    func update(entry: NSManagedObject) {
        entry.setValue(Date(), forKey: "datetime")
        save()
    }
    
    // delete
    func delete(entry: NSManagedObject){
        managedContext.delete(entry)
        save()
    }
    
}
