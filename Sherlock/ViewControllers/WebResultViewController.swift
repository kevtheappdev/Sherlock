//
//  WebResultViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/23/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import WebKit

class WebResultViewController: UIViewController {
    var url: URL
    var recordHistory: Bool
    var historyRecorded = false
    var webView: WKWebView!
    var titleBar: WebTitleBar!
    var navBar: WebNavBar!
    var interactor: PushInteractor?
    
    // constraints
    var topConstraint: NSLayoutConstraint?
    var bottomConstraint: NSLayoutConstraint?
    
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
        self.webView = WKWebView()
        self.webView.navigationDelegate = self
        self.webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        self.view.addSubview(self.webView)
        
        // title bar setup
        self.titleBar = Bundle.main.loadNibNamed("WebTitleBar", owner: self, options: nil)?.first as? WebTitleBar
        self.view.addSubview(self.titleBar)
        
        // nav bar setup
        self.navBar = Bundle.main.loadNibNamed("WebNavBar", owner: self, options: nil)?.first as? WebNavBar
        self.navBar.delegate = self
        self.view.addSubview(self.navBar)
        
        // interaction gesture
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(WebResultViewController.didPan(_:)))
        self.view.isUserInteractionEnabled = true
        self.view.addGestureRecognizer(gestureRecognizer)
        
        self.load()
    }
    
    override func viewWillLayoutSubviews() {
        let navBar = self.navBar!
        let titleBar = self.titleBar!
        let webView = self.webView!
    
        navBar.translatesAutoresizingMaskIntoConstraints = false
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        self.view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let topConstraint = NSLayoutConstraint(item: titleBar, attribute: .top, relatedBy: .equal, toItem: self.view, attribute: .top, multiplier: 1, constant: 0)
        self.view.addConstraint(topConstraint)
        self.topConstraint = topConstraint
        
        let bottomConstraint = NSLayoutConstraint(item: navBar, attribute: .bottom, relatedBy: .equal, toItem: self.view, attribute: .bottom, multiplier: 1, constant: 0)
        self.view.addConstraint(bottomConstraint)
        self.bottomConstraint = bottomConstraint
        
        
        
        let views = ["navBar": navBar, "titleBar": titleBar, "webView": webView]
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
        
        self.view.addConstraints(navConstraints)
        self.view.addConstraints(webViewConstraints)
        self.view.addConstraints(titleBarConstraints)
        self.view.addConstraints(verticalConstraints)
        
    }
    
    func load(){
        let request = URLRequest(url: self.url)
        self.webView.load(request)
    }
    
    // webview progress
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "estimatedProgress" {
            let progress = Float(self.webView.estimatedProgress)
            if progress > 0.5 && self.recordHistory && !self.historyRecorded {
                self.historyRecorded = true
                SherlockHistoryManager.main.log(webPage: webView.url!, title: webView.title!) // TODO: error check this
            }
            
            self.titleBar.progressBar.progress = Float(self.webView.estimatedProgress)
            if webView.title  != nil  && !webView.title!.isEmpty {
                self.titleBar.set(title: webView.title!, url: webView.url!.absoluteString)
            }
        }
    }
    
    // transition gesture
    @objc func didPan(_ sender: UIPanGestureRecognizer){
        let percentThreshold: CGFloat = 0.3
        // convert x-position rightward pull progress
        let translation = sender.translation(in: self.view)
        let horizontalMovement = translation.x / self.view.bounds.width
        let rightwardMovement = fmaxf(Float(horizontalMovement), 0.0)
        let rightwardMovementPercent = fminf(rightwardMovement,  1.0)
        let progress = CGFloat(rightwardMovementPercent)
        
        guard let interactor = self.interactor else {return}
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            self.dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .ended:
            interactor.hasStarted = false
            interactor.completionSpeed = 0.99
            if interactor.shouldFinish {
                 interactor.finish()
            } else {
                interactor.cancel()
                UIApplication.shared.keyWindow!.addSubview(self.view)
            }
        default:
            break
        }
    }

}

extension WebResultViewController: WebNavBarDelegate {
    func backButtonPressed() {
        if self.webView.canGoBack {
            self.navBar.forwardButton.isEnabled = true
            self.webView.goBack()
        }  else {
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    func forwardButtonPressed() {
        if self.webView.canGoForward {
            self.webView.goForward()
            self.navBar.forwardButton.isEnabled = self.webView.canGoForward
        }
    }
    
    func reloadButtonPressed() {
        self.webView.reload()
    }
    
    func shareButtonPressed() {
        let shareSheet = UIActivityViewController(activityItems: [self.url], applicationActivities: nil)
        self.present(shareSheet, animated: true)
    }
}

extension WebResultViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
        self.titleBar.progressBar.progress = 0.0
        if self.recordHistory && !self.historyRecorded {
            self.historyRecorded = true
            SherlockHistoryManager.main.log(webPage: webView.url!, title: webView.title!)
        }
    }
    
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        if navigationAction.navigationType == .linkActivated {
            self.historyRecorded = false
            self.recordHistory = true
        }
        decisionHandler(.allow)
    }
}
