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
    var coverView: CoverView!
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
        
        self.webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // setup cover view
        self.coverView = CoverView()
        self.coverView.backgroundColor = UIColor.white
    }
    
    override func loadView() {
         self.view = webView
    }
    
    override func  viewDidLayoutSubviews() {
        self.coverView.frame = CGRect(origin: CGPoint.zero, size: self.view.frame.size)
    }
    
    func execute(query: String) {
        self.coverView.loadingIndicator.startLoadAnimation()
        let urlStr = self.sherlockService.searchURL
        let urliFiedQuery = self.urlify(text: query)
        let completedURL = urlStr.replacingOccurrences(of: "{query}", with: urliFiedQuery)
        let url = URL(string: completedURL)!
        let request = URLRequest(url: url)
        self.view.addSubview(self.coverView)
        self.webView.load(request)
    }
    
    func urlify(text textStr: String) -> String {
        let str = textStr.components(separatedBy: " ")
        let arr = str.filter({$0 != ""})
        return arr.joined(separator: "%20")
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            if !self.webView.isLoading {
                print("finished loading: \(sherlockService.searchURL)")
                self.coverView.removeFromSuperview()
            }
        }
    }
    
}
