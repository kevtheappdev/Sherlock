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
    let webView = WKWebView()

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.webView.navigationDelegate = self
    }
    
    override func loadView() {
         self.view = webView
    }
    
    func execute(query: String, withURL url: String) {
        let urliFiedQuery = self.urlify(text: query)
        let completedURL = url.replacingOccurrences(of: "{query}", with: urliFiedQuery)
        print("completedURL: \(completedURL)")
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

// experiment: find out how to intercept link clicks
extension WebSearchViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // prevent clicks on search results - to be overridden with customcontent viewer
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
        } else {
            decisionHandler(.allow)
        }
    }
}

