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
        webView = WKWebView(frame: CGRect.zero, configuration: webConfig)
        sherlockService = service
        super.init(nibName: nil, bundle: nil)
        
        webView.addObserver(self, forKeyPath: "loading", options: .new, context: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        webView.scrollView.contentInsetAdjustmentBehavior = .never
        
        // setup cover view
        coverView = CoverView()
        coverView.backgroundColor = UIColor.white
    }
    
    override func loadView() {
         view = webView
    }
    
    override func  viewDidLayoutSubviews() {
        coverView.frame = CGRect(origin: CGPoint.zero, size: view.frame.size)
    }
    
    func execute(query: String) {
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
//                print("finished loading: \(sherlockService.searchURL)")
                coverView.removeFromSuperview()
            }
        }
    }
    
}
