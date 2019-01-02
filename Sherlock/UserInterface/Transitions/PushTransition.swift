//
//  PushTransition.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/25/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class PushTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromVC = transitionContext.viewController(forKey: .from),
            let toVC = transitionContext.viewController(forKey: .to)
        else {
            return
        }
        
        let container = transitionContext.containerView
        
        // start off the screen to the right
        let screenWidth = UIScreen.main.bounds.width
        toVC.view.frame = CGRect(origin: CGPoint(x: screenWidth, y: 0), size: toVC.view.frame.size)
        container.addSubview(toVC.view)

        UIView.animate(withDuration: self.transitionDuration(using: transitionContext), animations: {() in
            toVC.view.frame = transitionContext.finalFrame(for: toVC)
            fromVC.view.transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        }, completion: {(done) in
            fromVC.view.transform = CGAffineTransform.identity
            transitionContext.completeTransition(done)
        })
        
    }
    

}
