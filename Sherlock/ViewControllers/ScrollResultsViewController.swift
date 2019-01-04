//
//  ScrollResultsViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/22/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit
import WebKit

enum ScrollDirection {
    case left
    case right
}

class ScrollResultsViewController: UIViewController {
    let scrollView = UIScrollView()
    var serviceSelector: ServiceSelectorBar
    var services: [SherlockService] = []
    var lastQuery:  String?
    var lastContentOffset = CGPoint(x: 0, y: 0)
    var currentIndex = 0
    var webControllers: [serviceType:  WebSearchViewController] = [:]
    var userScrolling = true
    weak var currentResult: WebSearchViewController!
    weak var delegate: ScrollResultsDelegate?


    
    init(services: [SherlockService]) {
        self.services = services
        self.serviceSelector = ServiceSelectorBar()
        super.init(nibName: nil, bundle: nil)
        self.setupWebViews()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //  setup scrollview
        scrollView.delegate = self
        scrollView.isPagingEnabled = true
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bounces = false
        scrollView.contentInsetAdjustmentBehavior = UIScrollView.ContentInsetAdjustmentBehavior.never
        view.addSubview(scrollView)
        
        // setup service selector
        serviceSelector.delegate = self
        view.addSubview(serviceSelector)
        
        setupWebViews()
        setupConstraints()
    }
    
    func setupWebViews(){
        // clear previous webviews
        for (_, webVC) in webControllers {
            webVC.removeFromParent()
            webVC.view.removeFromSuperview()
        }
        webControllers.removeAll()
        
        // add web views
        var index = 0
        for service in services {
            let config = service.config
            let webVC = WebSearchViewController(service: service, javascriptEnabled: config.resultsJavascriptEnabled)
            webControllers[service.type] = webVC
            addChild(webVC)
            webVC.didMove(toParent:self)
            scrollView.addSubview(webVC.view)
            index += 1
        }
    }
    
    func set(Services services: [SherlockService]){
        self.services = services
        serviceSelector.display(Services: services)
        layoutWebviews()
        view.layoutIfNeeded()
    }
    
    private func setupConstraints() {
        // layout scrollview and service selector
        let views = ["scrollView": scrollView, "serviceSelector": serviceSelector]
        view.layoutMargins = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        serviceSelector.translatesAutoresizingMaskIntoConstraints = false
        
        var serviceBarHeight: CGFloat = 100
        if view.safeAreaInsets.bottom > CGFloat(0) {
            // device with home bar
            serviceBarHeight = 115
        }
        
        let scrollViewHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[scrollView]|",
                                                                             options: [],
                                                                             metrics: nil,
                                                                             views: views)
        
        let serviceSelectorHorizontalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "H:|[serviceSelector]|",
                                                                                  options: [],
                                                                                  metrics: nil,
                                                                                  views: views)
        
        let verticalConstraints = NSLayoutConstraint.constraints(withVisualFormat: "V:|[scrollView][serviceSelector(barHeight)]|",
                                                                 options: [],
                                                                 metrics: ["barHeight": serviceBarHeight],
                                                                 views: views)
        
        view.addConstraints(scrollViewHorizontalConstraints)
        view.addConstraints(serviceSelectorHorizontalConstraints)
        view.addConstraints(verticalConstraints)
        
        
        
        // layout webviews
        layoutWebviews()
    }
    
    
    private func layoutWebviews(){
        let width = view.bounds.width
        let height = view.bounds.height
        scrollView.contentSize = CGSize(width: width * CGFloat(services.count), height: height)
        
        var index = 0
        for service in services {
            let webVC = webControllers[service.type]!
            webVC.view.frame = CGRect(x: width * CGFloat(index), y: 0, width: width, height: height)
            index += 1
        }
        
        scrollView.contentOffset = CGPoint(x: CGFloat(currentIndex) * width, y: 0)
    }
    
    func execute(query: String, service: SherlockService? = nil, services: [SherlockService], recordHistory: Bool = true) {
        set(Services: services)
        
        
        // only execute on a new query
        if let lastQuery = lastQuery {
            if lastQuery == query {
                scrollToService(service: service)
                return
            }
        }
        lastQuery = query
        
        if recordHistory {
            SherlockHistoryManager.main.log(search: query)
        }
        
        
        for (_, webVC) in webControllers { // TODO: limit this when we add more services
            webVC.execute(query: query)
        }
        
        scrollToService(service: service)
    }
    
    func scrollToService(service: SherlockService?){
        userScrolling = false
        
        if let selectedService = service {
            // scroll to selected service
            let type = selectedService.type
            guard let curVC = webControllers[type] else {
                return
            }
            delegate?.switchedTo(service: selectedService.type)
            currentResult = curVC
            scrollView.contentOffset = curVC.view.frame.origin
            currentIndex = Int(scrollView.contentOffset.x / currentResult.view.frame.size.width)
            serviceSelector.select(service: type)
        } else {
            let firstType = services.first!.type
            delegate?.switchedTo(service: firstType)
            currentResult = webControllers[firstType]
            currentIndex = 0
        }
        
        currentResult.webView.navigationDelegate = self
        userScrolling = true
    }
    
    
}

// MARK: UIScrollViewDelegate
extension ScrollResultsViewController: UIScrollViewDelegate {
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        let offset = scrollView.contentOffset

        for (serviceType, webVC) in webControllers { // TODO: refactor this - use dictionary to map offsets to viewcontroller instances
            if offset == webVC.view.frame.origin && currentResult.sherlockService.type != webVC.sherlockService.type {
                delegate?.switchedTo(service: serviceType)
                currentResult = webVC
                webVC.webView.navigationDelegate = self
                serviceSelector.select(service: serviceType)
                currentIndex = Int(offset.x / webVC.view.frame.width)
                break
            }
        }
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if !userScrolling {return}
        let offset = scrollView.contentOffset
        let screenWidth = UIScreen.main.bounds.width
        if lastContentOffset.x > offset.x {
            // going left
            let leftOffset = CGFloat(currentIndex - 1) * screenWidth
            let cOffset = (leftOffset + screenWidth) - offset.x
            let percentCompleted = cOffset / screenWidth
            serviceSelector.scrollTo(Percent: percentCompleted, direction: .left)
            print("going left, percenCompleted: \(percentCompleted) offset: \(offset) cOffset: \(cOffset)")
        } else {
            // going right
            let rightOffset = CGFloat(currentIndex + 1) * screenWidth
            let percentCompleted = offset.x / rightOffset
            serviceSelector.scrollTo(Percent: percentCompleted, direction: .right)
            print("going right, percentCompleted: \(percentCompleted) offset: \(offset)")
        }
        
        lastContentOffset = offset
        
    }
}

// MARK: WKNavigationDelegate
extension ScrollResultsViewController: WKNavigationDelegate {
    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        // prevent clicks on search results - to be overridden with custom content viewer
        if navigationAction.navigationType == .linkActivated {
            decisionHandler(.cancel)
            delegate?.selectedLink(url: navigationAction.request.url!)
        } else {
            decisionHandler(.allow)
        }
    }
}

// MARK: ServiceSelectorBarDelegate
extension ScrollResultsViewController: ServiceSelectorBarDelegate {
    func selected(service: SherlockService) {
        scrollToService(service: service)
    }
}
