//
//  WebSearchViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/21/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import WebKit
import SafariServices

class WebSearchViewController: UIViewController {
    var webView: WKWebView = WKWebView()
    var sherlockService: SherlockService

    init(service: SherlockService, javascriptEnabled: Bool = false){
        // init WKWebView
        let webPrefs = WKPreferences()
        webPrefs.javaScriptEnabled = javascriptEnabled
        let webConfig =  WKWebViewConfiguration()
        webConfig.preferences = webPrefs
        self.webView = WKWebView(frame: CGRect.zero, configuration: webConfig)
        self.sherlockService = service
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.view.backgroundColor = UIColor.white
        self.webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    override func loadView() {
         self.view = webView
    }
    
    func execute(query: String) {
        let urlStr = self.sherlockService.searchURL
        let urliFiedQuery = self.urlify(text: query)
        let completedURL = urlStr.replacingOccurrences(of: "{query}", with: urliFiedQuery)
        let url = URL(string: completedURL)!
        let request = URLRequest(url: url)
        self.webView.load(request)
    }
    
    func urlify(text textStr: String) -> String {
        let str = textStr.components(separatedBy: " ")
        let arr = str.filter({$0 != ""})
        return arr.joined(separator: "%20")
    }

}

