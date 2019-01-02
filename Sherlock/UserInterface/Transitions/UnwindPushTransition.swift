//
//  UnwindPushTransition.swift
//  Sherlock
//
//  Created by Kevin Turner on 12/25/18.
//  Copyright © 2018 Kevin Turner. All rights reserved.
//

import UIKit

class UnwindPushTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return  0.3
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let fromView = transitionContext.view(forKey: .from),
            let toView = transitionContext.view(forKey: .to),
            let toVC  = transitionContext.viewController(forKey: .to)
            else {
                return
        }
        
        let containerView = transitionContext.containerView
        toView.frame = transitionContext.finalFrame(for: toVC)
        
        
        let identity = CGAffineTransform.identity
        let transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        toView.transform = transform
        
        // frame for from view
        let screenWidth = UIScreen.main.bounds.width
        let finalFrame = CGRect(x: screenWidth, y: 0, width: fromView.bounds.width, height: fromView.bounds.height)
        
        containerView.insertSubview(toView, belowSubview: fromView)
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.5, animations: {() in
            fromView.frame = finalFrame
            toView.transform = identity
        }, completion: {(done) in
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
        
    }
    
}
