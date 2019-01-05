//
//  FlipTransition.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/4/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class FlipTransition: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard
            let toView = transitionContext.view(forKey: .to),
            let fromView = transitionContext.view(forKey: .from)
        else {
            return
        }
        
        CATransaction.flush()
        let duration = transitionDuration(using: transitionContext)
        UIView.transition(from: fromView, to: toView, duration: duration, options: .transitionFlipFromRight, completion: {(done) in
            transitionContext.completeTransition(done)
        })
        
    }

}
