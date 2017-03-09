//
//  ModalViewController.swift
//  HalfModalPresentationController
//
//  Created by Martin Normark on 17/01/16.
//  Copyright © 2016 martinnormark. All rights reserved.
//

import UIKit
import DLRadioButton

class ModalViewController: UIViewController, HalfModalPresentable {
    
    
    
    
    @IBOutlet var radioRequestSell: [DLRadioButton]!
    
    
    @IBOutlet weak var radioRequest: DLRadioButton!
    @IBOutlet weak var radioSell: DLRadioButton!
    
    override func viewDidAppear(_ animated: Bool) {
        radioRequest.isMultipleSelectionEnabled = true
        radioSell.isMultipleSelectionEnabled = true
    }
    
    @IBAction func bFullScreen(_ sender: Any) {
        maximizeToFullScreen()
    }
    
    
    @IBAction func bCancelTapped(_ sender: Any) {
        if let delegate = navigationController?.transitioningDelegate as? HalfModalTransitioningDelegate {
            delegate.interactiveDismiss = false
        }
        
        dismiss(animated: true, completion: nil)
    }
    
}
