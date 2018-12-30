//
//  ScrollResultsViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/22/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import WebKit

class ScrollResultsViewController: UIViewController {
    let scrollView = UIScrollView()
    var serviceSelector: ServiceSelectorBar
    var services: [SherlockService]
    var lastQuery:  String?
    var webControllers: [serviceType:  WebSearchViewController] = Dictionary<serviceType, WebSearchViewController>()
    weak var currentResult: WebSearchViewController!
    weak var delegate: ScrollResultsDelegate?
    var loadOk = true

    
    init(services: [SherlockService]) {
        self.serviceSelector = ServiceSelectorBar(services: services)
        self.services = services
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //  setup scrollview
        self.scrollView.delegate = self
        self.scrollView.isPagingEnabled = true
        self.scrollView.showsHorizontalScrollIndicator = false
        self.scrollView.bounces = false
        self.view.addSubview(self.scrollView)
        
        // setup service selector
        self.serviceSelector.delegate = self
        self.view.addSubview(self.serviceSelector)
        
        // add web views
        for service in services {
            let config = service.config
            let webVC = WebSearchViewController(service: service, javascriptEnabled: config.resultsJavascriptEnabled)
            self.webControllers[service.type] = webVC
            self.addChild(webVC)
            webVC.didMove(toParent:self)
            self.scrollView.addSubview(webVC.view)
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillLayoutSubviews() {
        super.viewWillLayoutSubviews()
        // layout scrollview and service selector
        let views = ["scrollView": scrollView, "serviceSelector": serviceSelector]
        self.view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        self.scrollView.translatesAutoresizingMaskIntoConstraints = false
        self.serviceSelector.translatesAutoresizingMaskIntoConstraints = false
        
        let scrollViewHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|",
                                                                             options: [],
                                                                             metrics: nil,
                                                                             views: views)
        
        let serviceSelectorHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[serviceSelector]|",
                                                                                  options: [],
                                                                                  metrics: nil,
                                                                                  views: views)
        
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView][serviceSelector(100)]|",
                                                                 options: [],
                                                                 metrics: nil,
                                                                 views: views)
        
        self.view.addConstraints(scrollViewHorizontalConstraints)
        self.view.addConstraints(serviceSelectorHorizontalConstraints)
        self.view.addConstraints(verticalConstraints)
        
        let width = self.view.bounds.width
        let height = self.view.bounds.height
        self.scrollView.contentSize = CGSize(width: width * CGFloat(self.services.count), height: height)
        
        // layout webviews
        var curX: CGFloat = 0
        for service in self.services {
            let webVC = self.webControllers[service.type]!
            
            webVC.view.frame = CGRect(x: curX, y: 0, width: width, height: height)
            curX += width
        }

    }
    
    func execute(query: String, service: SherlockService? = nil, force: Bool = false){
        if !force && !self.loadOk {return}
        
        // only execute on a new query
        if let lastQuery = self.lastQuery {
            if lastQuery == query {
                scrollToService(service: service)
                return
            }
        }
        lastQuery = query
        
        if force {
            SherlockHistoryManager.main.log(search: query)
        }
        
        for (_, webVC) in webControllers { // TODO: limit this when we add more services
            webVC.execute(query: query)
        }
        
        scrollToService(service: service)
    
        // rate limiting
        self.loadOk = false
        Timer.scheduledTimer(withTimeInterval: 0.75, repeats: false, block:{_  in  // TODO: have servicespecific rate limiting
            self.loadOk = true
        })
    }
    
    func scrollToService(service: SherlockService?){
        if let selectedService = service {
            // scroll to selected service
            let type = selectedService.type
            guard let curVC = webControllers[type] else {
                return
            }
            self.currentResult = curVC
            self.scrollView.contentOffset = curVC.view.frame.origin
            self.serviceSelector.select(service: type)
        } else {
            self.currentResult = webControllers[services.first!.type]
        }
        
        self.currentResult.webView.navigationDelegate = self
    }
}

extension ScrollResultsViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset
        
        for (serviceType, webVC) in webControllers {
            if offset == webVC.view.frame.origin && currentResult.sherlockService.type != webVC.sherlockService.type {
                self.delegate?.switchedTo(service: serviceType)
                self.currentResult = webVC
                webVC.webView.navigationDelegate = self
                self.serviceSelector.select(service: serviceType)
            }
        }
    }
}

extension ScrollResultsViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // prevent clicks on search results - to be overridden with custom content viewer
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            self.delegate?.selectedLink(url: navigationAction.request.url!)
        } else {
            decisionHandler(.allow)
        }
    }
}

extension ScrollResultsViewController: ServiceSelectorBarDelegate {
func selected(service: SherlockService) {
        self.scrollToService(service: service)
    }
}
