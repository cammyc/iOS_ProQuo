//
//  ModalViewController.swift
//  HalfModalPresentationController
//
//  Created by Martin Normark on 17/01/16.
//  Copyright © 2016 martinnormark. All rights reserved.
//

import UIKit
import DLRadioButton
import ARNTransitionAnimator
import TTRangeSlider
import KCFloatingActionButton
import MMSegmentSlider


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
    @IBOutlet weak var bUpdateMax: UIButton!
    @IBOutlet weak var tfUpdateMax: UITextField!
    
    
    // MARK: Fab init
    @IBOutlet weak var fabBackToMap: KCFloatingActionButton!
    @IBOutlet weak var fabClearFilters: KCFloatingActionButton!
    
    // MARK: tfDate init
    @IBOutlet weak var tfDateStart: UITextField!
    @IBOutlet weak var tfDateEnd: UITextField!
    var startDatePicker: UIDatePicker? = nil
    var endDatePicker: UIDatePicker? = nil
    
    // MARK: # tickets init
    @IBOutlet weak var ticketIntervalSlider: MMSegmentSlider!
    
    override func viewDidLoad() {
        fabBackToMap.fabDelegate = self
        fabClearFilters.fabDelegate = self
        
        setDates()
        
        radioRequest.isMultipleSelectionEnabled = true
        radioSell.isMultipleSelectionEnabled = true

        
        self.priceSlider.delegate = self
        
        initializeDatePicker(dateField: self.tfDateStart, action: #selector(ModalViewController.dateSelectedDateStart))
        initializeDatePicker(dateField: self.tfDateEnd, action: #selector(ModalViewController.dateSelectedDateEnd))
        
        bUpdateMax.layer.cornerRadius = 5
        
        ticketIntervalSlider.values = [-1, 1, 2, 3, 4]
        ticketIntervalSlider.labels = ["Any", "1", "2", "3" , "4+"]

    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        let format:NumberFormatter = NumberFormatter() //cool animiation
        format.positiveSuffix = "$"
        
        priceSlider.numberFormatterOverride = format
        
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
        }else if fab == fabClearFilters {
            
            setDates()
            
            if !self.radioRequest.isSelected{
                self.radioRequest.isSelected = true
            }
            
            if !self.radioSell.isSelected{
                self.radioSell.isSelected = true
            }
            
            priceSlider.selectedMaximum = priceSlider.maxValue
            priceSlider.selectedMinimum = priceSlider.minValue
                        
            ticketIntervalSlider.selectedItemIndex = 0
        }
    }
    
    // MARK: Misc
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.view.endEditing(true)
    }
    
    func setDates(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        tfDateStart.text = dateFormatter.string(from: Date())
        tfDateEnd.text = dateFormatter.string(from: Calendar.current.date(byAdding: .year, value: 1, to: Date())!)
    }
    
}
