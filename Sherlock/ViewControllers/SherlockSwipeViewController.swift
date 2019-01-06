//
//  SherlockSwipeViewController.swift
//  Sherlock
//
//  Created by Kevin Turner on 1/5/19.
//  Copyright © 2019 Kevin Turner. All rights reserved.
//

import UIKit

class SherlockSwipeViewController: UIViewController {
    var interactor: PushInteractor!

    
    // transition gesture
    @objc func didPan(_ sender: UIPanGestureRecognizer){
        let percentThreshold: CGFloat = 0.3
        // convert x-position rightward pull progress
        let translation = sender.translation(in: view)
        let horizontalMovement = translation.x / view.bounds.width
        let rightwardMovement = fmaxf(Float(horizontalMovement), 0.0)
        let rightwardMovementPercent = fminf(rightwardMovement,  1.0)
        let progress = CGFloat(rightwardMovementPercent)
        
        guard let interactor = interactor else {return}
        
        switch sender.state {
        case .began:
            interactor.hasStarted = true
            dismiss(animated: true, completion: nil)
        case .changed:
            interactor.shouldFinish = progress > percentThreshold
            interactor.update(progress)
        case .ended:
            interactor.hasStarted = false
            interactor.completionSpeed = 0.99
            if interactor.shouldFinish {
                interactor.finish()
            } else {
                interactor.cancel()
            }
        default:
            break
        }
    }

}
