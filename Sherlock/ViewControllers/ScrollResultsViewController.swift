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
    var currentIndex = 0
    var webControllers: [serviceType:  WebSearchViewController] = Dictionary<serviceType, WebSearchViewController>()
    weak var currentResult: WebSearchViewController!
    weak var delegate: ScrollResultsDelegate?


    
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
        scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        self.view.addSubview(self.scrollView)
        
        // setup service selector
        self.serviceSelector.delegate = self
        self.view.addSubview(self.serviceSelector)
        
        // add web views
        var index = 0
        for service in services {
            let config = service.config
            let webVC = WebSearchViewController(service: service, javascriptEnabled: config.resultsJavascriptEnabled) // TODO: decouple the passing of this data  from the constructor
            self.webControllers[service.type] = webVC
            self.addChild(webVC)
            webVC.didMove(toParent:self)
            self.scrollView.addSubview(webVC.view)
            index += 1
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
        
       
        
        // layout webviews
        layoutWebviews()

    }
    
    private func layoutWebviews(){
        let width = self.view.bounds.width
        let height = self.view.bounds.height
         self.scrollView.contentSize = CGSize(width: width * CGFloat(self.services.count), height: height)
        
        var index = 0
        for service in self.services {
            let webVC = self.webControllers[service.type]!
            webVC.view.frame = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
            index += 1
        }
        
        self.scrollView.contentOffset = CGPoint(x: CGFloat(self.currentIndex) * width, y: 0)
    }
    
    func execute(query: String, service: SherlockService? = nil) {
        
        // only execute on a new query
        if let lastQuery = self.lastQuery {
            if lastQuery == query {
                scrollToService(service: service)
                return
            }
        }
        lastQuery = query
        
        
        SherlockHistoryManager.main.log(search: query)
        
        
        for (_, webVC) in webControllers { // TODO: limit this when we add more services
            webVC.execute(query: query)
        }
        
        scrollToService(service: service)
    }
    
    func scrollToService(service: SherlockService?){
        if let selectedService = service {
            // scroll to selected service
            let type = selectedService.type
            guard let curVC = webControllers[type] else {
                return
            }
            self.delegate?.switchedTo(service: selectedService.type)
            self.currentResult = curVC
            self.scrollView.contentOffset = curVC.view.frame.origin
            self.currentIndex = Int(self.scrollView.contentOffset.x / self.currentResult.view.frame.size.width)
            self.serviceSelector.select(service: type)
        } else {
            let firstType = services.first!.type
            self.delegate?.switchedTo(service: firstType)
            self.currentResult = webControllers[firstType]
            self.currentIndex = 0
        }
        
        self.currentResult.webView.navigationDelegate = self
    }
    
    
}

extension ScrollResultsViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset

        for (serviceType, webVC) in webControllers { // TODO: refactor this - use dictionary to map offsets to viewcontroller instances
            if offset == webVC.view.frame.origin && currentResult.sherlockService.type != webVC.sherlockService.type {
                self.delegate?.switchedTo(service: serviceType)
                self.currentResult = webVC
                webVC.webView.navigationDelegate = self
                self.serviceSelector.select(service: serviceType)
                self.currentIndex = Int(offset.x / webVC.view.frame.width)
                break
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
