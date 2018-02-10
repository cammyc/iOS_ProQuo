//
//  ModalViewController.swift
//  HalfModalPresentationController
//
//  Created by Martin Normark on 17/01/16.
//  Copyright © 2016 martinnormark. All rights reserved.
//

import UIKit
import DLRadioButton
import TTRangeSlider
import KCFloatingActionButton
import MMSegmentSlider


class ModalViewController: UIViewController, TTRangeSliderDelegate, KCFloatingActionButtonDelegate {
    
    // MARK: Global
    var delegate: FilterDelegate?

    
    // MARK: Label init
    @IBOutlet weak var labelShowTickets: UILabel!
    
    // MARK: Radio init
    @IBOutlet var radioRequestSell: [DLRadioButton]!
    @IBOutlet weak var radioRequest: DLRadioButton!
    @IBOutlet weak var radioSell: DLRadioButton!
    
    // MARK: Slider init
    @IBOutlet weak var priceSlider: TTRangeSlider!
    @IBOutlet weak var tfUpdateMax: UITextField!
    @IBOutlet weak var bUpdateMax: UIButton!
    
    
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
    
    var filters = Filters()
    
    override func viewDidLoad() {
        fabBackToMap.fabDelegate = self
        fabClearFilters.fabDelegate = self
        
        fabBackToMap.sticky = true
        fabClearFilters.sticky = true
        
        radioRequest.isMultipleSelectionEnabled = true
        radioSell.isMultipleSelectionEnabled = true
        
        radioRequest.addTarget(self, action: #selector(ModalViewController.radioTapped), for: UIControlEvents.touchUpInside)
        radioSell.addTarget(self, action: #selector(ModalViewController.radioTapped), for: UIControlEvents.touchUpInside)
        
        radioSell.otherButtons = [radioRequest]
        
        self.priceSlider.delegate = self
        
        initializeDatePicker(dateField: self.tfDateStart, action: #selector(ModalViewController.dateSelectedDateStart))
        initializeDatePicker(dateField: self.tfDateEnd, action: #selector(ModalViewController.dateSelectedDateEnd))
        
        setDates()
        
        bUpdateMax.layer.cornerRadius = 5
        bUpdateMax.addTarget(self, action: #selector(ModalViewController.updateMaxPrice), for: UIControlEvents.touchUpInside)
        
        ticketIntervalSlider.values = [-1, 1, 2, 3, 4]
        ticketIntervalSlider.labels = ["Any", "1", "2", "3" , "4+"]
        
        ticketIntervalSlider.addTarget(self, action: #selector(ModalViewController.intervalSliderTapped), for: UIControlEvents.valueChanged)
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        let format:NumberFormatter = NumberFormatter() //cool animiation
        format.positivePrefix = "$"
        
        priceSlider.numberFormatterOverride = format
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        delegate?.updateFilters(updatedFilter: self.filters)
    }
    
    // MARK: Price Slider
    
    func didStartTouches(in sender: TTRangeSlider!) {
        delegate?.sliderFocused()
    }
    
    func didEndTouches(in sender: TTRangeSlider!) {
        delegate?.sliderUnfocused()
    }
    
    func rangeSlider(_ sender: TTRangeSlider!, didChangeSelectedMinimumValue selectedMinimum: Float, andMaximumValue selectedMaximum: Float) {
        self.filters.minPrice = Int(selectedMinimum.rounded())
        self.filters.maxPrice = Int(selectedMaximum.rounded())
    }
    
    func updateMaxPrice(){
        if let newMax = Float(self.tfUpdateMax.text!), newMax <= 10000, newMax > 0{
            self.priceSlider.maxValue = newMax
        }
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
        
        filters.startDate = sender.date
    }
    
    func dateSelectedDateEnd(sender: UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        tfDateEnd.text = dateFormatter.string(from: sender.date)
        
        if let datePicker = startDatePicker as UIDatePicker!{
            datePicker.maximumDate = sender.date
        }
        
        filters.endDate = sender.date
    }
    
    // MARK: Fab
    
    func emptyKCFABSelected(_ fab: KCFloatingActionButton) {
        if fab == fabBackToMap{
            if !radioRequest.isSelected && !radioSell.isSelected {
                self.view.makeToast("Please select post type", duration: 2.0, position: .bottom)
            }else{
                self.dismiss(animated: true, completion: nil)
            }
        }else if fab == fabClearFilters {
            
            setDates()
            
            if !self.radioRequest.isSelected{
                self.radioRequest.isSelected = true
            }
            
            if !self.radioSell.isSelected{
                self.radioSell.isSelected = true
            }
            
            priceSlider.maxValue = 1000
            
            priceSlider.selectedMaximum = priceSlider.maxValue
            priceSlider.selectedMinimum = priceSlider.minValue
                        
            ticketIntervalSlider.setSelectedItemIndex(0, animated: true)
            
            filters = Filters() //resets to default
        }
    }
    
    // MARK: Radio Buttons
    
    func radioTapped(){
        filters.showRequested = (self.radioRequest.isSelected) ? true : false
        filters.showSelling = (self.radioSell.isSelected) ? true : false
    }
    
    
    // MARK: Number of Tickets
    
    func intervalSliderTapped(){
        filters.numTickets = ticketIntervalSlider.currentValue as! Int
    }

    
    // MARK: Misc
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.view.endEditing(true)
    }
    
    func setDates(){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        let start = Date()
        let end = Calendar.current.date(byAdding: .year, value: 1, to: Date())!
        
        startDatePicker?.maximumDate = end
        
        tfDateStart.text = dateFormatter.string(from: start)
        tfDateEnd.text = dateFormatter.string(from: end)
        
        filters.startDate = start
        filters.endDate = end
    }
    
}
