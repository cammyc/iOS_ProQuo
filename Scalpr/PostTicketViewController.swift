//
//  PostTicketViewController.swift
//  Scalpr
//
//  Created by Cam Connor on 9/30/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import UIKit
import Kingfisher

class PostTicketViewController: UIViewController, UICollectionViewDataSource, UICollectionViewDelegate,  UITextFieldDelegate, UITextViewDelegate{
    
    // MARK: Input Field Initialization
    @IBOutlet weak var tfAttractionName: UITextField!
    @IBOutlet weak var tfVenueName: UITextField!
    @IBOutlet weak var tfTicketPrice: UITextField!
    @IBOutlet weak var tfNumTickets: UITextField!
    @IBOutlet weak var tfDate: UITextField!
    @IBOutlet weak var tvDescription: UITextView!
    @IBOutlet weak var tfSearchImageQuery: UITextField!
    
    @IBOutlet weak var bSetPostLocation: UIButton!
    @IBOutlet weak var bCancel: UIButton!

    @IBOutlet weak var dialogView: UIView!
    
    @IBOutlet weak var collectionView: UICollectionView!
    
    @IBOutlet weak var ivSelectedImage: UIImageView!
    
    var selectedImageURL: String = ""
    
    let bingHelper = BingImageHelper()
    let imgHelper = ImageHelper()
    
    
    let reuseIdentifier = "cell" // also enter this string as the cell identifier in the storyboard
    var items: [String] = []
    
    var attraction: Attraction = Attraction()
    
    var editAttraction: Attraction? = nil
    
    var firstIvTap = true;
    
    // MARK: View Initializaton


    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tfAttractionName.delegate = self
        self.tfVenueName.delegate = self
        self.tfTicketPrice.delegate = self
        self.tfNumTickets.delegate = self
        self.tfDate.delegate = self
        self.tvDescription.delegate = self
        self.tvDescription.textColor = UIColor.lightGray
        self.tvDescription.layer.borderWidth = 1.0
        self.tvDescription.layer.cornerRadius = 5.0
        let borderColor = UIColor(red:204.0/255.0, green:204.0/255.0, blue:204.0/255.0, alpha:1.0);
        self.tvDescription.layer.borderColor = borderColor.cgColor
        
        initializeDatePicker()
        
        self.tfSearchImageQuery.delegate = self
        
        self.collectionView.delegate = self
        
        if !UIAccessibilityIsReduceTransparencyEnabled() && editAttraction == nil {
            self.view.backgroundColor = UIColor.clear
            
            let blurEffect = UIBlurEffect(style: UIBlurEffectStyle.light)
            let blurEffectView = UIVisualEffectView(effect: blurEffect)
            //always fill the view
            blurEffectView.frame = self.view.bounds
            blurEffectView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
            
            self.view.insertSubview(blurEffectView, belowSubview: dialogView)
        }
        
        dialogView.layer.cornerRadius = 5.0
        
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PostTicketViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
        
        let ivTap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(PostTicketViewController.ivSelectedTap))
        ivTap.cancelsTouchesInView = false
        ivSelectedImage.addGestureRecognizer(ivTap)
        
        bSetPostLocation.isEnabled = false
        
        initializeIfFromEdit()
    }
    
    func initializeDatePicker(){
        let datePickerView = UIDatePicker()
        datePickerView.datePickerMode = UIDatePickerMode.date
        datePickerView.minimumDate = Date()
        
        datePickerView.addTarget(self, action: #selector(PostTicketViewController.dateSelected), for: .valueChanged)
        
        let toolBar = UIToolbar()
        toolBar.barStyle = UIBarStyle.default
        toolBar.isTranslucent = true
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItemStyle.done, target: self, action: #selector(self.dismissKeyboard))

        toolBar.setItems([UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: self, action: nil), doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        tfDate.inputAccessoryView = toolBar
        
        self.tfDate.inputView = datePickerView
    }
    
    
    func initializeIfFromEdit(){
        
        if editAttraction != nil{
            self.tfAttractionName.returnKeyType = .done
            self.tfVenueName.returnKeyType = .done
            self.tfTicketPrice.returnKeyType = .done
            self.tfNumTickets.returnKeyType = .done
            self.tfDate.returnKeyType = .done
            self.tvDescription.returnKeyType = .done
            
            self.tfAttractionName.text = editAttraction!.name
            self.tfVenueName.text = editAttraction!.venueName
            self.tfTicketPrice.text = String(describing: editAttraction!.ticketPrice) + ""
            self.tfNumTickets.text = String(describing: editAttraction!.numTickets)
            self.tfDate.text = MiscHelper.dateToString(date: (editAttraction?.date)!, format: "MM/dd/yyyy")
            
            if editAttraction!.description != ""{
                self.tvDescription.text = editAttraction!.description
                tvDescription.textColor = UIColor.black
            }
            
            self.selectedImageURL = (editAttraction!.imageURL)
            
            
            self.ivSelectedImage.isHidden = false
            self.collectionView.isHidden = true
            self.ivSelectedImage.kf.setImage(with: URL(string: selectedImageURL))
            
            self.bSetPostLocation.setTitle("Save Changes", for: .normal)
            
            self.validateFields()
            
            attraction = editAttraction!

        }
        
    }
    
    
    func dateSelected(sender: UIDatePicker){
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        tfDate.text = dateFormatter.string(from: sender.date)
    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        self.view.endEditing(true)
    }
    
    func ivSelectedTap(){
        if firstIvTap && editAttraction != nil{
            tfSearchImageQuery.text = tfAttractionName.text
            bingHelper.getSearchImages(query: tfSearchImageQuery.text!){ responseObject, error in
                if responseObject != nil {
                    self.items = self.bingHelper.getImageThumbURLs(array: responseObject!)
                    self.collectionView.reloadData()
                }
                return
            }
            firstIvTap = false
        }
        
        self.ivSelectedImage.isHidden = true
        self.collectionView.isHidden = false
        self.tfSearchImageQuery.isHidden = false
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    // MARK: TextField data handling

    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        
        if editAttraction == nil{
        
            switch textField {
            case tfAttractionName:
                tfVenueName.becomeFirstResponder()
                break
            case tfVenueName:
                tfTicketPrice.becomeFirstResponder()
                break
            case tfTicketPrice:
                tfNumTickets.becomeFirstResponder()
                break
            case tfNumTickets:
                tfDate.becomeFirstResponder()
                break
            case tfDate:
                tvDescription.becomeFirstResponder()
                break
            case tfSearchImageQuery:
                //self.view.endEditing(true)
                break
            default:
                self.view.endEditing(true)
                break
            }
        }
        return false
    }

    
    func textFieldDidEndEditing(_ textField: UITextField) {
        switch textField {
            case tfAttractionName:
                if !textFieldIsNull(field: tfAttractionName){
                    tfSearchImageQuery.text = tfAttractionName.text
                    bingHelper.getSearchImages(query: tfAttractionName.text!){ responseObject, error in
                        if responseObject != nil {
                            self.items = self.bingHelper.getImageThumbURLs(array: responseObject!)
                            self.collectionView.reloadData()
                        }else if error != nil{
                            self.showErrorAlert()
                        }
                        
                        return
                    }
                }
            break
            case tfSearchImageQuery:
                if !textFieldIsNull(field: tfSearchImageQuery){
                    bingHelper.getSearchImages(query: tfSearchImageQuery.text!){ responseObject, error in
                        if responseObject != nil {
                            self.items = self.bingHelper.getImageThumbURLs(array: responseObject!)
                            self.collectionView.reloadData()
                        }else if error != nil{
                            self.showErrorAlert()
                        }

                        return
                    }
                }
            break
        default:
            self.view.endEditing(true)
            break
        }
        validateFields()
    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n"
        {
            textView.resignFirstResponder()
            return false
        }
        
        let fullString = textView.text! + text
        
        if fullString.characters.count > 140 {
            return false
        }else{
            return true
        }
        return true
    }
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "Description (Optional)"
            textView.textColor = UIColor.lightGray
        }
    }
    
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        if textField == tfNumTickets {
            // Create an `NSCharacterSet` set which includes everything *but* the digits
            let inverseSet = NSCharacterSet(charactersIn:"0123456789").inverted
            
            // At every character in this "inverseSet" contained in the string,
            // split the string up into components which exclude the characters
            // in this inverse set
            let components = string.components(separatedBy: inverseSet)
            
            // Rejoin these components
            let filtered = components.joined(separator: "")  // use join("", components) if you are using Swift 1.2
            
            // If the original string is equal to the filtered string, i.e. if no
            // inverse characters were present to be eliminated, the input is valid
            // and the statement returns true; else it returns false
            if string == filtered{
                var startString = ""
                if (textField.text != nil)
                {
                    startString += textField.text!
                }
                startString += string
                let limitNumber = Int(startString)
                if limitNumber! > 1000000 || limitNumber! < 1
                {
                    return false
                }
                else
                {
                    return true;
                }
            }else{
                return false
            }
        }else if textField == tfTicketPrice{
            let inverseSet = NSCharacterSet(charactersIn:".0123456789").inverted
            
            let components = string.components(separatedBy: inverseSet)
            
            let filtered = components.joined(separator: "")
            
            if string == filtered{
                var decimalFound = false
                var charactersAfterDecimal = 0
                
                let fullString = textField.text! + string
                
                for ch in (fullString.characters.reversed()) {
                    if ch == "." {
                        decimalFound = true
                        break
                    }
                    charactersAfterDecimal += 1
                }
                
                if decimalFound && charactersAfterDecimal > 2 {
                    return false
                }
                
                var startString = ""
                if (textField.text != nil)
                {
                    startString += textField.text!
                }
                startString += string
                if let limitNumber = Double(startString){
                    if limitNumber > 1000000
                    {
                        return false
                    }
                    else
                    {
                        return true;
                    }

                }
                
                return true
            }else{
                return false
            }

        }else{
            let fullString = textField.text! + string

            if fullString.characters.count > 140 {
                return false
            }else{
                return true
            }
        }

    }
   
    
    // MARK: Validate Fields
    
    func validateFields(){
        
        
        if textFieldIsNull(field: tfAttractionName){
            bSetPostLocation.isEnabled = false
            return
        }
        
        if textFieldIsNull(field: tfVenueName){
            bSetPostLocation.isEnabled = false
            return
        }
        
        if textFieldIsNull(field: tfTicketPrice){
            bSetPostLocation.isEnabled = false
            return
        }
        
        if textFieldIsNull(field: tfNumTickets){
            bSetPostLocation.isEnabled = false
            return
        }
        
        if textFieldIsNull(field: tfDate){
            bSetPostLocation.isEnabled = false
            return
        }
        
        if selectedImageURL == "" {
            bSetPostLocation.isEnabled = false
            return
        }
        
        bSetPostLocation.isEnabled = true
    }
    
    func textFieldIsNull(field: UITextField) ->Bool {
        return trimString(string: (field.text)!) == ""
    }
    
    func trimString(string: String)-> String{
        return string.trimmingCharacters(in: NSCharacterSet.whitespacesAndNewlines)
    }
    
    // MARK: Buttons
    @IBAction func bCancel(_ sender: UIButton) {
        //self.dismiss(animated: true)
        //navigationController?.popViewController(animated: true)
        if editAttraction == nil{
            self.performSegue(withIdentifier: "unwindToHomeFromPost", sender: sender)
        }else{
            sender.tag = 1
            self.performSegue(withIdentifier: "unwindToMyTicketsFromPost", sender: sender)
        }
    }
    
    @IBAction func bSetPostLocation(_ sender: UIButton) {
        attraction.name = tfAttractionName.text!
        attraction.venueName = tfVenueName.text!
        attraction.ticketPrice = Double(tfTicketPrice.text!)!
        attraction.numTickets = Int(tfNumTickets.text!)!
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        let dateObj = dateFormatter.date(from: tfDate.text!)
        
        attraction.date = dateObj!
        if tvDescription.textColor == UIColor.lightGray{
            attraction.description = ""
        }else{
            attraction.description = tvDescription.text!
        }
        attraction.imageURL = selectedImageURL
        
        if editAttraction == nil{
            self.performSegue(withIdentifier: "set_post_location", sender: sender)
        }else{
            sender.tag = 0
            self.performSegue(withIdentifier: "unwindToMyTicketsFromPost", sender: sender)
        }
    }
    
    // MARK: - Prepare for seague
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "set_post_location"{
            let setTicketLocationViewController = (segue.destination as! SetTicketLocationViewController)
            setTicketLocationViewController.attraction = self.attraction
        }else if segue.identifier == "unwindToMyTicketsFromPost"{
            
            if sender as? UIButton == bSetPostLocation{
                
                let myTicketsViewController = (segue.destination as! MyTicketsTableViewController)
                myTicketsViewController.editedAttraction = self.attraction
            }
        }
    }
    
    @IBAction func unwindToPostTicket(segue:UIStoryboardSegue) {
    }
    

    // MARK: - UICollectionViewDataSource protocol
    
    // tell the collection view how many cells to make
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.items.count
    }
    
    // make a cell for each cell index path
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        // get a reference to our storyboard cell
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath as IndexPath) as! BingImageCollectionViewCell
        
        // Use the outlet in our custom class to get a reference to the UILabel in the cell
        let url = URL(string: self.items[indexPath.item])
        cell.image.kf.setImage(with: url)
        
        
        
        return cell
    }
    
    // MARK: - UICollectionViewDelegate protocol
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // handle tap events
        
        KingfisherManager.shared.cache.removeImage(forKey: selectedImageURL)
        selectedImageURL = self.items[indexPath.item]
        ivSelectedImage.kf.setImage(with: URL(string: selectedImageURL))
        ivSelectedImage.isHidden = false
        collectionView.isHidden = true
        self.tfSearchImageQuery.isHidden = true
        validateFields()
    }
    
    // MARK: Show error alert
    
    func showErrorAlert(){
        let refreshAlert = UIAlertController(title: "Unable to Connect", message: "We were unable to retreive images for you to select from. You will not be able to submit a post without an image so please check your internet connection and try again.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action: UIAlertAction!) in
            self.navigationController?.dismiss(animated: true)
        }))
        
        self.present(refreshAlert,animated: true,completion: nil)
    }
    
    
}
