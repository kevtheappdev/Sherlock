//
//  WebResultViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/23/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import WebKit

class WebResultViewController: SherlockSwipeViewController {
    var url: URL
    var recordHistory: Bool
    var historyRecorded = false
    var webView: WKWebView!
    var titleBar: WebTitleBar!
    var navBar: WebNavBar!
    var statusBarBackground: UIView!
    var lastOffset: CGPoint = CGPoint.zero
    var userScrolling = false
    
    // constraints
    var topConstraint: NSLayoutConstraint!
    var bottomConstraint: NSLayoutConstraint!
    
    
    init(url: URL, recordHistory: Bool = true) {
        self.url = url
        self.recordHistory = recordHistory
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("not implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // web view setup
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        view.addSubview(webView)
        
        // title bar setup
        titleBar = Bundle.main.loadNibNamed("WebTitleBar", owner: self, options: nil)?.first as? WebTitleBar
        titleBar.delegate = self
        view.addSubview(titleBar)
        
        statusBarBackground = UIView()
        statusBarBackground.backgroundColor = UIColor.white
        view.addSubview(statusBarBackground)
        
        // nav bar setup
        navBar = Bundle.main.loadNibNamed("WebNavBar", owner: self, options: nil)?.first as? WebNavBar
        navBar.delegate = self
        view.addSubview(navBar)
        
        setupConstraints()
        load()
    }
    
    func setupConstraints(){
        let navBar = self.navBar!
        let titleBar = self.titleBar!
        let webView = self.webView!
        let statusBarBackground = self.statusBarBackground!
        
        navBar.translatesAutoresizingMaskIntoConstraints = false
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        statusBarBackground.translatesAutoresizingMaskIntoConstraints = false
        view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let topConstraint = NSLayoutConstraint(item: titleBar, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        view.addConstraint(topConstraint)
        self.topConstraint = topConstraint
        
        let bottomConstraint = NSLayoutConstraint(item: navBar, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraint)
        self.bottomConstraint = bottomConstraint
        
        let views = ["navBar": navBar, "titleBar": titleBar, "webView": webView, "sbMask": statusBarBackground]
        let metrics = ["sbHeight": UIApplication.shared.statusBarFrame.height]
        
        let sbVertical = NSLayoutConstraint.constraints(withVisualFormat: "V:|[sbMask(sbHeight)]",
                                                        options: [],
                                                        metrics: metrics,
                                                        views: views)
        
        let sbHorizontal = NSLayoutConstraint.constraints(withVisualFormat: "H:|[sbMask]|",
                                                          options: [],
                                                          metrics: nil,
                                                          views: views)
        
        
        let navConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[navBar]|",
                                                            options: [],
                                                            metrics: nil,
                                                            views: views)
        
        let webViewConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[webView]|",
                                                                options: [],
                                                                metrics: nil,
                                                                views: views)
        
        let titleBarConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[titleBar]|",
                                                                 options: [],
                                                                 metrics: nil,
                                                                 views: views)
        
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:[titleBar(130)][webView][navBar(90)]",
                                                                 options: [], metrics: nil,
                                                                 views: views)
        
        view.addConstraints(sbVertical)
        view.addConstraints(sbHorizontal)
        view.addConstraints(navConstraints)
        view.addConstraints(webViewConstraints)
        view.addConstraints(titleBarConstraints)
        view.addConstraints(verticalConstraints)
    }
    
    
    func load(){
        let request = URLRequest(url: url)
        webView.load(request)
    }
    
    // webview progress
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            titleBar.progressBar.progress = Float(webView.estimatedProgress)
            if webView.title  != nil  && !webView.title!.isEmpty {
                titleBar.set(title: webView.title!, url: webView.url!.absoluteString)
                // record history
                if recordHistory && !historyRecorded {
                    SherlockHistoryManager.main.log(webPage: webView.url!, title: webView.title!)
                    historyRecorded = true
                }
            }
        }
    }
    


}

// MARK: WebNavBarDelegate
extension WebResultViewController: WebNavBarDelegate {
    func backButtonPressed() {
        if webView.canGoBack {
            navBar.forwardButton.isEnabled = true
            webView.goBack()
        }  else {
            dismiss(animated: true, completion: nil)
        }
    }
    
    func forwardButtonPressed() {
        if webView.canGoForward {
            webView.goForward()
            navBar.forwardButton.isEnabled = webView.canGoForward
        }
    }
    
    func reloadButtonPressed() {
        webView.reload()
    }
    
    func shareButtonPressed() {
        let shareSheet = UIActivityViewController(activityItems: [url], applicationActivities: nil)
        present(shareSheet, animated: true)
    }
}

// MARK: WebTitleBarDelegate
extension WebResultViewController: WebTitleBarDelegate {
    func titleBackButtonPressed() {
        dismiss(animated: true, completion: nil)
    }

}

// MARK: WKNavigationDelegate
extension WebResultViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        if recordHistory && !historyRecorded {
            historyRecorded = true
            SherlockHistoryManager.main.log(webPage: webView.url!, title: webView.title!)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            historyRecorded = false
            recordHistory = true
        }
        decisionHandler(.allow)
    }
    
}

// MARK: UIScrollViewDelegate
extension WebResultViewController: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        if !userScrolling {return} // ensure scrolling occurs from user
        if offset.y < 0 || offset.y > webView.scrollView.contentSize.height {return}
        
        let diff = abs(offset.y - lastOffset.y)
        if offset.y > lastOffset.y {
            // going down
            print("going down: \(offset.y) diff: \(diff)")
            
            let curTopVal = topConstraint.constant
            let destTopVal = -titleBar.bounds.height
            
            if curTopVal > destTopVal {
                topConstraint.constant -= diff
            }
            
            let curBottomVal = bottomConstraint.constant
            let destBottomVal = navBar.bounds.height
            
            if curBottomVal < destBottomVal {
                bottomConstraint.constant += diff
            }
            
            view.layoutIfNeeded()
            
        } else {
            // going up
            
            if topConstraint.constant < 0 && diff <= abs(topConstraint.constant) {
                topConstraint.constant += diff
            } else if topConstraint.constant < 0 {
                topConstraint.constant = 0
            }
            
            
            if bottomConstraint.constant > 0 && diff <= abs(bottomConstraint.constant){
                bottomConstraint.constant -=  diff
            } else if bottomConstraint.constant > 0 {
                bottomConstraint.constant = 0
            }
            
            view.layoutIfNeeded()
            
        }
        lastOffset = offset
        
    }
    
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        userScrolling = true
    }
}
