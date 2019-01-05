//
//  UnwindNewModal.swift
//  Tock
//
//  Created by Kevin Turner on 7/4/16.
//  Copyright © 2016 Kevin Turner. All rights reserved.
//

import UIKit

class UnwindNewModal: NSObject, UIViewControllerAnimatedTransitioning
{
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning)
    {
        let containerView = transitionContext.containerView
        let  toView = transitionContext.view(forKey: UITransitionContextViewKey.to)!
        let froMView = transitionContext.view(forKey: UITransitionContextViewKey.from)!
        let toVC = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to)!
        toView.frame = transitionContext.finalFrame(for: toVC)
        
        let identity = CGAffineTransform.identity
        
        let transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
        toView.transform = transform
        

        
        let screenHeight = UIScreen.main.bounds.height
        let finalFrame = CGRect(x: 0, y: screenHeight, width: froMView.bounds.width, height: froMView.bounds.height)
        containerView.insertSubview(toView, belowSubview: froMView)
        
        UIView.animate(withDuration: transitionDuration(using: transitionContext), animations: {() in
            froMView.frame = finalFrame
            toView.transform = identity
            }, completion: {(done) in
                if transitionContext.transitionWasCancelled {
                    toView.transform = identity
                }
            transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
        })
    }
    
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.2
    }
    
    
    
}
