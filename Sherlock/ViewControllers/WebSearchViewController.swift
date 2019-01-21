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
    var autoLoad = true
    var loaded = false
    
    // transitions
    let present = PushTransition()
    let dissmiss = UnwindPushTransition()
    let interactor = PushInteractor()


    init(service: SherlockService, javascriptEnabled: Bool = false){
        sherlockService = service
        super.init(nibName: nil, bundle: nil)
        // url scheme
        if service.config.openURLScheme {
            guard let openInView = Bundle.main.loadNibNamed("URLSchemeCoverView", owner: self, options: nil)?.first as? URLSchemeCoverView else {
                return
            }
            
            isUrlScheme = true // TODO: allocate less stuff if this is true
            self.openInView = openInView
            openInView.set(Service: service)
            view.addSubview(openInView)
        } else {
            // init WKWebView
            let webPrefs = WKPreferences()
            webPrefs.javaScriptEnabled = javascriptEnabled
            let webConfig = WKWebViewConfiguration()
            webConfig.preferences = webPrefs
            webView = WKWebView(frame: CGRect.zero, configuration: webConfig)
            autoLoad = service.config.autoLoad
            
            // setup oberservers
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.isLoading), options: .new, context: nil)
            webView.addObserver(self, forKeyPath: #keyPath(WKWebView.url), options: .new, context: nil)
            webView.navigationDelegate = self
        }
        

    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // setup cover view
        coverView = LoadingCoverView()
        coverView.backgroundColor = UIColor.white
        
        if isUrlScheme {return}
        webView.scrollView.contentInsetAdjustmentBehavior = .never
    }
    
    override func loadView() {
         view = webView
    }
    
    override func viewDidLayoutSubviews() {
        let screenFrame = CGRect(origin: CGPoint.zero, size: view.frame.size)
        if let openInView = self.openInView {
            openInView.frame = screenFrame
        } else {
            coverView.frame = screenFrame
        }
    }
    
    func execute(query: String, force: Bool = false) {
        if isUrlScheme || (!autoLoad && !force) || loaded {return}
        coverView.loadingIndicator.startLoadAnimation()
        let urlStr = sherlockService.searchURL
        let urliFiedQuery = query.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlFragmentAllowed)!
        let completedURL = urlStr.replacingOccurrences(of: "{query}", with: urliFiedQuery)
        let url = URL(string: completedURL)!
        let request = URLRequest(url: url)
        view.addSubview(coverView)
        webView.load(request)
        loaded = true
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if keyPath == "loading" {
            if !webView.isLoading {
                coverView.removeFromSuperview()
                
                // run any javascript
                if let js = sherlockService.config.jsString {
                    webView.evaluateJavaScript(js, completionHandler: nil)
                }
            }
        } else if keyPath == #keyPath(WKWebView.url) {
            if !webView.isLoading {
                let url = webView.url!
                let allowedUrls = sherlockService.config.allowedUrls
                for allowedUrl in allowedUrls {
                    if url.absoluteString.contains(allowedUrl){
                        return
                    }
                }
                openWebResultsVC(url: url)
                webView.goBack()
            }
            
        }
        
    }
    
    
    func openWebResultsVC(url: URL){
        let sfVC = WebResultViewController(url: url)
        sfVC.transitioningDelegate = self
        sfVC.interactor = interactor
        present(sfVC, animated: true)
    }
    
}

// MARK: WKNavigationDelegate
extension WebSearchViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // prevent clicks on search results - to be overridden with custom content viewer
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            guard let url = navigationAction.request.url else {
                return
            }
            openWebResultsVC(url: url)
        } else {
            decisionHandler(.allow)
        }
    }
}

extension WebSearchViewController: UIViewControllerTransitioningDelegate {
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return present
    }
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        return dissmiss
    }
    
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
            return interactor.hasStarted ? interactor : nil
    }
}
