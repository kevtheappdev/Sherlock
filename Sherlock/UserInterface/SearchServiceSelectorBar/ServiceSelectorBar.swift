//
//  ServiceSelectorBar.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/22/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class ServiceSelectorBar: UIView {
    private static let iconSize: CGFloat = 85
    private static let padding: CGFloat = 20
    private let scrollView = UIScrollView()
    private var services: [SherlockService] = Array<SherlockService>()
    private var buttons: [UIButton] = Array<UIButton>()
    private var selectionView: UIView!
    private var buttonOffsets: [CGFloat] = Array<CGFloat>()
    private var selectedOffset = CGPoint(x: 0, y: 0)
    weak var delegate: ServiceSelectorBarDelegate?
    
    init() {
        super.init(frame: CGRect.zero)
        self.backgroundColor = UIColor.white
        scrollView.showsHorizontalScrollIndicator = false
        self.addSubview(scrollView)
        
        // setup selection view
        self.selectionView = UIGradientView(frame: CGRect.zero, andColors: ApplicationConstants._sherlockGradientColors)
        self.selectionView.layer.cornerRadius = 2
        self.scrollView.addSubview(selectionView)
        
        self.layer.borderWidth = 1
        self.layer.borderColor = UIColor.gray.cgColor
    }
    
    override func layoutSubviews() {
        scrollView.frame = self.bounds
        self.layoutButtons()
    }
    
    private func layoutButtons(){
        // set scrollview contentsize
        let width = CGFloat(self.services.count) * ServiceSelectorBar.iconSize
        let height = self.scrollView.bounds.height
        self.scrollView.contentSize = CGSize(width: width , height: height)
        
        // layout scrollview elements
        self.selectionView.frame = CGRect(x: selectedOffset.x, y: 0, width: ServiceSelectorBar.iconSize, height: 10)
        
        var yMult: CGFloat = 0.4
        if UIApplication.shared.keyWindow!.safeAreaInsets.bottom > CGFloat(0) {
            // has home indicator
            yMult = 0.2
        }
        
        var curX: CGFloat = 0
        let y = (yMult * (height - ServiceSelectorBar.iconSize))
        for button in self.buttons {
            button.frame = CGRect(x: curX, y: y, width: ServiceSelectorBar.iconSize, height: ServiceSelectorBar.iconSize)
            self.buttonOffsets.append(curX)
            curX += ServiceSelectorBar.iconSize
        }
        
    }
    
    func display(Services services: [SherlockService]){
        self.services = services
        // clear any views
        for button in self.buttons {
            button.removeFromSuperview()
        }
        self.buttons.removeAll()
        
        var index = 1
        for service in self.services {
            let iconButton = UIButton(type: .custom)
            iconButton.setImage(service.icon, for: .normal)
            let padding = ServiceSelectorBar.padding
            iconButton.imageEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
            iconButton.contentMode = .scaleAspectFit
            iconButton.tag = index
            iconButton.addTarget(self, action: #selector(self.buttonPressed(_:)), for: .touchUpInside)
            self.scrollView.addSubview(iconButton)
            self.buttons.append(iconButton)
            index += 1
        }
        
        self.layoutButtons()
    }
    
    @objc
    func buttonPressed(_ sender: UIButton){
        // select button
        let serviceIndex = sender.tag - 1
        self.selectButtonAt(Index: serviceIndex)
        // notify delegate
        let service = self.services[serviceIndex]
        self.delegate?.selected(service: service)
    }
    
    func selectButtonAt(Index serviceIndex: Int){
        if serviceIndex >= self.buttonOffsets.count {return}
        let selectedOffset = self.buttonOffsets[serviceIndex]
        // scroll to make visible if necesssary
        let buttonEnd = selectedOffset + ServiceSelectorBar.iconSize
        let scrollVisible = (self.scrollView.contentOffset.x + self.bounds.width)
        if buttonEnd > scrollVisible {
            let diff = abs(scrollVisible - buttonEnd)
            let offset = CGPoint(x: diff, y: 0)
            self.scrollView.setContentOffset(offset, animated: true)
        } else if selectedOffset < self.scrollView.contentOffset.x {
            let offset = CGPoint(x: selectedOffset, y: 0)
            self.scrollView.setContentOffset(offset, animated: true)
        }
        
        UIView.animate(withDuration: 0.1, animations: {() in
            let selectedPoint = CGPoint(x: selectedOffset, y: 0)
            self.selectedOffset = selectedPoint // TODO: just store x value
            self.selectionView.frame = CGRect(origin: selectedPoint, size: self.selectionView.bounds.size)
        })
        

    }
    
    func scrollTo(Percent percent: CGFloat, direction: ScrollDirection){
        if  direction == .right {
            let nextOffset = CGPoint(x: self.selectedOffset.x + ServiceSelectorBar.iconSize, y: 0)
            self.selectionView.frame = CGRect(origin: CGPoint(x: percent * nextOffset.x, y: 0), size: self.selectionView.frame.size)
        } else {
            self.selectionView.frame = CGRect(origin: CGPoint(x: self.selectedOffset.x - (percent * ServiceSelectorBar.iconSize), y: 0), size: self.selectionView.frame.size)
        }
    }
    
    func select(service selectedService: serviceType){
        var index = 0
        for service in self.services {
            if service.type == selectedService  {
                break
            }
            index += 1
        }
        
        self.selectButtonAt(Index: index)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
