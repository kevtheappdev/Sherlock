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
        webView = WKWebView()
        webView.navigationDelegate = self
        webView.scrollView.delegate = self
        webView.addObserver(self, forKeyPath: #keyPath(WKWebView.estimatedProgress), options: .new, context: nil)
        view.addSubview(webView)
        
        // title bar setup
        titleBar = Bundle.main.loadNibNamed("WebTitleBar", owner: self, options: nil)?.first as? WebTitleBar
        titleBar.delegate = self
        view.addSubview(titleBar)
        
        // nav bar setup
        navBar = Bundle.main.loadNibNamed("WebNavBar", owner: self, options: nil)?.first as? WebNavBar
        navBar.delegate = self
        view.addSubview(navBar)
        
        // interaction gesture
        let gestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(WebResultViewController.didPan(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(gestureRecognizer)
        
        load()
    }
    
    override func viewWillLayoutSubviews() {
        let navBar = self.navBar!
        let titleBar = self.titleBar!
        let webView = self.webView!
        
        navBar.translatesAutoresizingMaskIntoConstraints = false
        titleBar.translatesAutoresizingMaskIntoConstraints = false
        webView.translatesAutoresizingMaskIntoConstraints = false
        view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        
        let topConstraint = NSLayoutConstraint(item: titleBar, attribute: .top, relatedBy: .equal, toItem: view, attribute: .top, multiplier: 1, constant: 0)
        view.addConstraint(topConstraint)
        self.topConstraint = topConstraint
        
        let bottomConstraint = NSLayoutConstraint(item: navBar, attribute: .bottom, relatedBy: .equal, toItem: view, attribute: .bottom, multiplier: 1, constant: 0)
        view.addConstraint(bottomConstraint)
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
    
    // transition gesture
    @objc func didPan(_ sender: UIPanGestureRecognizer){
        let percentThreshold: CGFloat = 0.3
        // convert x-position rightward pull progress
        let translation = sender.translation(in: view)
        let horizontalMovement = translation.x / view.bounds.width
        let rightwardMovement = fmaxf(Float(horizontalMovement), 0.0)
        let rightwardMovementPercent = fminf(rightwardMovement,  1.0)
        let progress = CGFloat(rightwardMovementPercent)
        
        guard let interactor = interactor else {return}
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
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
            }
        default:
            break
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
        // TODO: make chrome disapear on scroll
    }
}
