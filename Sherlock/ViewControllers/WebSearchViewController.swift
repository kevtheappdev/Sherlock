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
    var coverView: LoadingCoverView!
    var openInView: URLSchemeCoverView?
    var sherlockService: SherlockService
    var isUrlScheme = false

    init(service: SherlockService, javascriptEnabled: Bool = false){
        // init WKWebView
        let webPrefs = WKPreferences()
        webPrefs.javaScriptEnabled = javascriptEnabled
        let webConfig =  WKWebViewConfiguration()
        webConfig.preferences = webPrefs
        webView = WKWebView(frame: CGRect.zero, configuration: webConfig)
        sherlockService = service
        super.init(nibName: nil, bundle: nil)
        
        if service.config.openURLScheme {
            guard let openInView = Bundle.main.loadNibNamed("URLSchemeCoverView", owner: self, options: nil)?.first as? URLSchemeCoverView else {
                return
            }
            
            isUrlScheme = true // TODO: allocate less stuff if this is true
            self.openInView = openInView
            openInView.set(Service: service)
            view.addSubview(openInView)
        } else {
            webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
        }
        

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // setup cover view
        coverView = LoadingCoverView()
        coverView.backgroundColor = UIColor.white
    }
    
    override func loadView() {
         view = webView
    }
    
    override func viewDidLayoutSubviews() {
        let screenFrame = CGRect(origin: CGPoint.zero, size: view.frame.size)
        coverView.frame = screenFrame
        if let openInView = self.openInView {
            openInView.frame = screenFrame
        }
    }
    
    func execute(query: String) {
        if isUrlScheme {return}
        coverView.loadingIndicator.startLoadAnimation()
        let urlStr = sherlockService.searchURL
        let urliFiedQuery = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
        let completedURL = urlStr.replacingOccurrences(of: "{query}", with: urliFiedQuery)
        let url = URL(string: completedURL)!
        let request = URLRequest(url: url)
        view.addSubview(coverView)
        webView.load(request)
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            if !webView.isLoading {
                coverView.removeFromSuperview()
            }
            
            // run any javascript
            if let js = sherlockService.config.jsString {
                webView.evaluateJavaScript(js, completionHandler: {(data, error) in
                    print("data: \(data) error: \(error)")
                })
            }
            
        }
    }
    
}
