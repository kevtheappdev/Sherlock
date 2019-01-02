//
//  ServiceSelectorBar.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/22/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class ServiceSelectorBar: UIView {
    private static let iconSize: CGFloat = 40
    private static let padding: CGFloat = 25
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
        self.selectionView = UIView()
        self.selectionView.backgroundColor = UIColor.gray
        self.selectionView.layer.opacity = 0.4
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
        let width = CGFloat(self.services.count) * (ServiceSelectorBar.iconSize + (2 * ServiceSelectorBar.padding))
        let height = self.scrollView.bounds.height
        self.scrollView.contentSize = CGSize(width: width , height: height)
        // layout scrollview elements
        self.selectionView.frame = CGRect(x: selectedOffset.x, y: selectedOffset.y, width: ServiceSelectorBar.iconSize + (2 * ServiceSelectorBar.padding), height: height)
        
        var curX: CGFloat = ServiceSelectorBar.padding
        let y = (0.4 * (height - ServiceSelectorBar.iconSize))
        for button in self.buttons {
            button.frame = CGRect(x: curX, y: y, width: ServiceSelectorBar.iconSize, height: ServiceSelectorBar.iconSize)
            self.buttonOffsets.append(curX - ServiceSelectorBar.padding)
            curX += ServiceSelectorBar.iconSize + (2 * ServiceSelectorBar.padding)
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
            iconButton.contentMode = .scaleAspectFit
            iconButton.tag = index
            iconButton.addTarget(self, action: #selector(self.buttonPressed(_:)), for: .touchDown)
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
        if selectedOffset > self.bounds.width {
            let diff = selectedOffset - self.bounds.width
            self.scrollView.contentOffset = CGPoint(x: diff, y: 0) // TODO: refine this
        }
        UIView.animate(withDuration: 0.1, animations: {() in
            let selectedPoint = CGPoint(x: selectedOffset, y: 0)
            self.selectedOffset = selectedPoint
            self.selectionView.frame = CGRect(origin: selectedPoint, size: self.selectionView.bounds.size)
        })
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
