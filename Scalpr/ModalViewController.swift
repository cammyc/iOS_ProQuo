//
//  ModalViewController.swift
//  HalfModalPresentationController
//
//  Created by Martin Normark on 17/01/16.
//  Copyright © 2016 martinnormark. All rights reserved.
//

import UIKit
import DLRadioButton
import ZMSwiftRangeSlider
import ARNTransitionAnimator
import TTRangeSlider
import KCFloatingActionButton


class ModalViewController: UIViewController, TTRangeSliderDelegate, KCFloatingActionButtonDelegate {
    
    
    // MARK: Label init
    @IBOutlet weak var labelShowTickets: UILabel!
    
    // MARK: Radio init
    @IBOutlet var radioRequestSell: [DLRadioButton]!
    @IBOutlet weak var radioRequest: DLRadioButton!
    @IBOutlet weak var radioSell: DLRadioButton!
    
    // MARK: Slider init
    @IBOutlet weak var priceSlider: TTRangeSlider!
    var delegate: SliderDelegate?
    
    // MARK: Fab init
    @IBOutlet weak var fabBackToMap: KCFloatingActionButton!
    
    // MARK: tfDate init
    @IBOutlet weak var tfDateStart: UITextField!
    @IBOutlet weak var tfDateEnd: UITextField!
    var startDatePicker: UIDatePicker? = nil
    var endDatePicker: UIDatePicker? = nil
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        fabBackToMap.fabDelegate = self
        
        radioRequest.isMultipleSelectionEnabled = true
        radioSell.isMultipleSelectionEnabled = true
        
        
        let format:NumberFormatter = NumberFormatter()
        format.positiveSuffix = "$"
        
        priceSlider.numberFormatterOverride = format
        
        self.priceSlider.delegate = self
        
        initializeDatePicker(dateField: self.tfDateStart, action: #selector(ModalViewController.dateSelectedDateStart))
        initializeDatePicker(dateField: self.tfDateEnd, action: #selector(ModalViewController.dateSelectedDateEnd))
    
    }
    
    // MARK: Slider
    
    func didStartTouches(in sender: TTRangeSlider!) {
        delegate?.sliderFocused()
    }
    
    func didEndTouches(in sender: TTRangeSlider!) {
        delegate?.sliderUnfocused()
    }
    
    func rangeSlider(_ sender: TTRangeSlider!, didChangeSelectedMinimumValue selectedMinimum: Float, andMaximumValue selectedMaximum: Float) {
        
    }
    
    // MARK: Date
    
    func initializeDatePicker(dateField: UITextField, action: Selector){
        let datePickerView = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.minimumDate = Date()
        
        if dateField == tfDateStart{
            self.startDatePicker = datePickerView
        }else{
            self.endDatePicker = datePickerView
        }
        
        datePickerView.addTarget(self, action: action, for: .valueChanged)
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(self.dismissKeyboard))
        
        toolBar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil), doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        dateField.inputAccessoryView = toolBar
        dateField.inputView = datePickerView
    }
    
    func dateSelectedDateStart(sender: UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        tfDateStart.text = dateFormatter.string(from: sender.date)
        
        if let datePicker = endDatePicker as UIDatePicker!{
            datePicker.minimumDate = sender.date
        }
    }
    
    func dateSelectedDateEnd(sender: UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        tfDateEnd.text = dateFormatter.string(from: sender.date)
    }
    
    // MARK: Fab
    
    func emptyKCFABSelected(_ fab: KCFloatingActionButton) {
        if fab == fabBackToMap{
            self.dismiss(animated: true, completion: nil)
        }
    }
    
    // MARK: Misc
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.view.endEditing(true)
    }
    
}
