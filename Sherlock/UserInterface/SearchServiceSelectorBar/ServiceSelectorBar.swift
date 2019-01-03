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
    private var services: [SherlockService] = []
    private var buttons: [UIButton] = []
    private var selectionView: UIView!
    private var buttonOffsets: [CGFloat] = []
    private var selectedOffset = CGPoint(x: 0, y: 0)
    weak var delegate: ServiceSelectorBarDelegate?
    
    init() {
        super.init(frame: CGRect.zero)
        backgroundColor = UIColor.white
        scrollView.showsHorizontalScrollIndicator = false
        addSubview(scrollView)
        
        // setup selection view
        selectionView = UIGradientView(frame: CGRect.zero, andColors: ApplicationConstants._sherlockGradientColors)
        selectionView.layer.cornerRadius = 2
        scrollView.addSubview(selectionView)
        
        layer.borderWidth = 1
        layer.borderColor = UIColor.gray.cgColor
    }
    
    override func layoutSubviews() {
        scrollView.frame = bounds
        layoutButtons()
    }
    
    private func layoutButtons(){
        // set scrollview contentsize
        let width = CGFloat(services.count) * ServiceSelectorBar.iconSize
        let height = scrollView.bounds.height
        scrollView.contentSize = CGSize(width: width , height: height)
        
        // layout scrollview elements
        selectionView.frame = CGRect(x: selectedOffset.x, y: 0, width: ServiceSelectorBar.iconSize, height: 10)
        
        var yMult: CGFloat = 0.4
        if UIApplication.shared.keyWindow!.safeAreaInsets.bottom > CGFloat(0) {
            // has home indicator
            yMult = 0.2
        }
        
        var curX: CGFloat = 0
        let y = (yMult * (height - ServiceSelectorBar.iconSize))
        for button in buttons {
            button.frame = CGRect(x: curX, y: y, width: ServiceSelectorBar.iconSize, height: ServiceSelectorBar.iconSize)
            buttonOffsets.append(curX)
            curX += ServiceSelectorBar.iconSize
        }
        
    }
    
    func display(Services services: [SherlockService]){
        self.services = services
        // clear any views
        for button in buttons {
            button.removeFromSuperview()
        }
        buttons.removeAll()
        
        var index = 1
        for service in services {
            let iconButton = UIButton(type: .custom)
            iconButton.setImage(service.icon, for: .normal)
            let padding = ServiceSelectorBar.padding
            iconButton.imageEdgeInsets = UIEdgeInsets(top: padding, left: padding, bottom: padding, right: padding)
            iconButton.contentMode = .scaleAspectFit
            iconButton.tag = index
            iconButton.addTarget(self, action: #selector(buttonPressed(_:)), for: .touchUpInside)
            scrollView.addSubview(iconButton)
            buttons.append(iconButton)
            index += 1
        }
        
        layoutButtons()
    }
    
    @objc
    func buttonPressed(_ sender: UIButton){
        // select button
        let serviceIndex = sender.tag - 1
        selectButtonAt(Index: serviceIndex)
        // notify delegate
        let service = services[serviceIndex]
        delegate?.selected(service: service)
    }
    
    func selectButtonAt(Index serviceIndex: Int){
        if serviceIndex >= buttonOffsets.count {return}
        let selectedOffset = buttonOffsets[serviceIndex]
        // scroll to make visible if necesssary
        let buttonEnd = selectedOffset + ServiceSelectorBar.iconSize
        let scrollVisible = (scrollView.contentOffset.x + bounds.width)
        if buttonEnd > scrollVisible {
            let diff = abs(scrollVisible - buttonEnd)
            let offset = CGPoint(x: diff, y: 0)
            scrollView.setContentOffset(offset, animated: true)
        } else if selectedOffset < scrollView.contentOffset.x {
            let offset = CGPoint(x: selectedOffset, y: 0)
            scrollView.setContentOffset(offset, animated: true)
        }
        
        UIView.animate(withDuration: 0.1, animations: {() in
            let selectedPoint = CGPoint(x: selectedOffset, y: 0)
            self.selectedOffset = selectedPoint // TODO: just store x value
            self.selectionView.frame = CGRect(origin: selectedPoint, size: self.selectionView.bounds.size)
        })
        

    }
    
    func scrollTo(Percent percent: CGFloat, direction: ScrollDirection){
        if  direction == .right {
            let nextOffset = CGPoint(x: selectedOffset.x + ServiceSelectorBar.iconSize, y: 0)
            selectionView.frame = CGRect(origin: CGPoint(x: percent * nextOffset.x, y: 0), size: selectionView.frame.size)
        } else {
            selectionView.frame = CGRect(origin: CGPoint(x: selectedOffset.x - (percent * ServiceSelectorBar.iconSize), y: 0), size: selectionView.frame.size)
        }
    }
    
    func select(service selectedService: serviceType){
        var index = 0
        for service in services {
            if service.type == selectedService  {
                break
            }
            index += 1
        }
        
        selectButtonAt(Index: index)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
