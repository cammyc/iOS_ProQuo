//
//  MusicPlayerTransitionAnimation.swift
//  MusicPlayerTransition
//
//  Created by xxxAIRINxxx on 2016/11/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit
import ARNTransitionAnimator

final class MusicPlayerTransitionAnimation : TransitionAnimatable {
    
    fileprivate weak var rootVC: HomeViewController!
    fileprivate weak var modalVC: ModalViewController!
    
    var completion: ((Bool) -> Void)?
    
    private var miniPlayerStartFrame: CGRect
    
    private var containerView: UIView?
    
    deinit {
        print("deinit MusicPlayerTransitionAnimation")
    }
    
    init(rootVC: HomeViewController, modalVC: ModalViewController) {
        self.rootVC = rootVC
        self.modalVC = modalVC
        
        self.miniPlayerStartFrame = rootVC.optionsView.frame
    }
    
    // @see : http://stackoverflow.com/questions/25588617/ios-8-screen-blank-after-dismissing-view-controller-with-custom-presentation
    func prepareContainer(_ transitionType: TransitionType, containerView: UIView, from fromVC: UIViewController, to toVC: UIViewController) {
        self.containerView = containerView
        if transitionType.isPresenting {
//            self.modalVC.view.removeFromSuperview()
            self.rootVC.view.insertSubview(self.modalVC.view, belowSubview: self.rootVC.optionsView)
        } else {
//            self.modalVC.view.removeFromSuperview()
            self.rootVC.view.insertSubview(self.modalVC.view, belowSubview: self.rootVC.optionsView)
        }
        self.rootVC.view.setNeedsLayout()
        self.rootVC.view.layoutIfNeeded()
        self.modalVC.view.setNeedsLayout()
        self.modalVC.view.layoutIfNeeded()
        
        self.miniPlayerStartFrame = self.rootVC.optionsView.frame
    }
    
    func willAnimation(_ transitionType: TransitionType, containerView: UIView) {
        if transitionType.isPresenting {
            self.rootVC.beginAppearanceTransition(true, animated: false)
            
//            if !UIAccessibilityIsReduceTransparencyEnabled(){
//                self.modalVC.view.backgroundColor = UIColor.clear
//                self.modalVC.mainView.backgroundColor = UIColor.clear
//                
//                let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
//                let blurEffectView = UIVisualEffectView(effect: blurEffect)
//                //always fill the view
//                blurEffectView.frame = self.modalVC.view.bounds
//                blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
//                
//                blurEffectView.removeFromSuperview()
//                
//                self.modalVC.mainView.insertSubview(blurEffectView, belowSubview: self.modalVC.labelShowTickets)
//                
//                
//                //self.view.insertSubview(blurEffectView, belowSubview: dialogView)
//            }
//
            
            self.modalVC.view.frame.origin.y = self.rootVC.optionsView.frame.origin.y + self.rootVC.optionsView.frame.size.height
        } else {
            self.rootVC.beginAppearanceTransition(false, animated: false)
            
            self.rootVC.optionsView.alpha = 1.0
            self.rootVC.optionsView.frame.origin.y = -self.rootVC.optionsView.bounds.size.height
//            self.rootVC.tabBar.frame.origin.y = containerView.bounds.size.height
        }
    }
    
    func updateAnimation(_ transitionType: TransitionType, percentComplete: CGFloat) {
        if transitionType.isPresenting {
            // optionsView
            let startOriginY = self.miniPlayerStartFrame.origin.y
            let endOriginY = -self.miniPlayerStartFrame.size.height
            let diff = -endOriginY + startOriginY
            // tabBar
//            let tabStartOriginY = self.tabBarStartFrame.origin.y
//            let tabEndOriginY = self.modalVC.view.frame.size.height
//            let tabDiff = tabEndOriginY - tabStartOriginY
            
            let playerY = startOriginY - (diff * percentComplete)
            self.rootVC.optionsView.frame.origin.y = max(min(playerY, self.miniPlayerStartFrame.origin.y), endOriginY)

            self.modalVC.view.frame.origin.y = self.rootVC.optionsView.frame.origin.y + self.rootVC.optionsView.frame.size.height
//            let tabY = tabStartOriginY + (tabDiff * percentComplete)
//            self.rootVC.tabBar.frame.origin.y = min(max(tabY, self.tabBarStartFrame.origin.y), tabEndOriginY)
            
            let alpha = 1.0 - (1.0 * percentComplete)
//            self.rootVC.containerView.alpha = alpha + 0.5
//            self.rootVC.tabBar.alpha = alpha
            //self.rootVC.
        } else {
            // optionsView
            let startOriginY = 0 - self.rootVC.optionsView.bounds.size.height
            let endOriginY = self.miniPlayerStartFrame.origin.y
            let diff = -startOriginY + endOriginY
            // tabBar
//            let tabStartOriginY = self.rootVC.containerView.bounds.size.height
//            let tabEndOriginY = self.tabBarStartFrame.origin.y
//            let tabDiff = tabStartOriginY - tabEndOriginY
            
            self.rootVC.optionsView.frame.origin.y = startOriginY + (diff * percentComplete)
            self.modalVC.view.frame.origin.y = self.rootVC.optionsView.frame.origin.y + self.rootVC.optionsView.frame.size.height
            
//            self.rootVC.tabBar.frame.origin.y = tabStartOriginY - (tabDiff *  percentComplete)
            
            let alpha = 1.0 * percentComplete
//            self.rootVC.containerView.alpha = alpha + 0.5
//            self.rootVC.tabBar.alpha = alpha
            self.rootVC.optionsView.alpha = 1.0
        }
    }
    
    func finishAnimation(_ transitionType: TransitionType, didComplete: Bool) {
        self.rootVC.endAppearanceTransition()
        
        if transitionType.isPresenting {
            if didComplete {
                self.rootVC.optionsView.alpha = 0.0
                self.modalVC.view.removeFromSuperview()
                self.containerView?.addSubview(self.modalVC.view)
                
                self.completion?(transitionType.isPresenting)
            } else {
                self.rootVC.beginAppearanceTransition(true, animated: false)
                self.rootVC.endAppearanceTransition()
            }
        } else {
            if didComplete {
                self.modalVC.view.removeFromSuperview()
                
                self.completion?(transitionType.isPresenting)
            } else {
                self.rootVC.optionsView.alpha = 0.0
                
                self.modalVC.view.removeFromSuperview()
                self.containerView?.addSubview(self.modalVC.view)
                
                self.rootVC.beginAppearanceTransition(false, animated: false)
                self.rootVC.endAppearanceTransition()
            }
        }
    }
}

extension MusicPlayerTransitionAnimation {
    
    func sourceVC() -> UIViewController { return self.rootVC }
    
    func destVC() -> UIViewController { return self.modalVC }
}


