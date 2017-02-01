//
//  MenuController.swift
//  SidebarMenu
//
//  Created by Simon Ng on 2/2/15.
//  Copyright (c) 2015 AppCoda. All rights reserved.
//

import UIKit
import MessageUI
import Whisper
import MBProgressHUD

class LoggedInMenuController: UITableViewController, MFMailComposeViewControllerDelegate {
    @IBOutlet weak var bLogOut: UITableViewCell!
    @IBOutlet weak var bPostTicket: UITableViewCell!
    @IBOutlet weak var bContactUs: UITableViewCell!
    @IBOutlet weak var bSearchTickets: UITableViewCell!

    // MARK: UILabels
    @IBOutlet weak var initialsLabel: UILabel!
    @IBOutlet weak var fullNameLabel: UILabel!
    
    let loginHelper: LoginHelper = LoginHelper()!
    
    let coreDataHelper: CoreDataHelper = CoreDataHelper()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let user = loginHelper.getLoggedInUser()

        
        initialsLabel.text = String(user.firstName.characters.prefix(1)) + String(user.lastName.characters.prefix(1))
        initialsLabel.bounds = CGRect(x: 0.0, y: 0.0, width: initialsLabel.frame.size.width, height: initialsLabel.frame.size.height)
        initialsLabel.layer.cornerRadius = initialsLabel.frame.size.height/2
        initialsLabel.layer.backgroundColor = MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71).cgColor
        
        fullNameLabel.text = user.firstName + " " + user.lastName
        
        let logoutTapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(self.showLogout))
        bLogOut.addGestureRecognizer(logoutTapGestureRecognizer)
        
        let postTicketTapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(self.postTicket))
        postTicketTapGestureRecognizer.cancelsTouchesInView = false
        
        bPostTicket.addGestureRecognizer(postTicketTapGestureRecognizer)
        
        let contactUsTapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(self.sendEmail))
        contactUsTapGestureRecognizer.cancelsTouchesInView = false
        
        bContactUs.addGestureRecognizer(contactUsTapGestureRecognizer)
        
        let searchTicketsTapGestureRecognizer = UITapGestureRecognizer(target:self, action: #selector(self.searchTickets))
        searchTicketsTapGestureRecognizer.cancelsTouchesInView = false
        
        bSearchTickets.addGestureRecognizer(searchTicketsTapGestureRecognizer)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        let updatedUser = loginHelper.getLoggedInUser()
        fullNameLabel.text = updatedUser.firstName + " " + updatedUser.lastName
    }
    
    func sendEmail() {
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = self
            mail.setToRecipients(["support@proquoapp.com"])
            
            present(mail, animated: true)
        } else {
            //showSendMailErrorAlert(email: recipientEmail)
            let coded = "mailto:support@proquoapp.com"
            if let emailURL:URL = URL(string: coded)
            {
                if UIApplication.shared.canOpenURL(emailURL as URL)
                {
                    UIApplication.shared.open(emailURL, options: [:])
                }else{
                    showSendMailErrorAlert(email: "support@proquoapp.com")
                }
            }
            
        }
    }
    
    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
        controller.dismiss(animated: true)
    }
    
    
    func showSendMailErrorAlert(email: String) {
        let refreshAlert = UIAlertController(title: "Could Not Send Email", message: "This is likely because you don't have the default 'Mail' app installed or your 'Mail' settings are configured improperly.\n\nOur email \n \(email) \n has been copied to your clipboard.\n\nSorry for the inconvenience.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: { (test) -> Void in
            UIPasteboard.general.string = email
            //self.view.makeToast("Sellers email copied to clipboard.", duration: 2.0, position: .bottom)
        }))
        
        present(refreshAlert, animated: true, completion: nil)
        
    }

    
    
    
    
    func postTicket(){
        revealViewController().revealToggle(animated: true)
       // self.performSegue(withIdentifier: "menuPostTicket", sender: nil)
    }
    
    func showLogout(){
        let refreshAlert = UIAlertController(title: "Logout", message: "Are you sure you want to logout?", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Yes", style: .default, handler: { (action: UIAlertAction!) in
            
            let preferences = UserDefaults.standard
            
            let deviceToken = preferences.string(forKey: "deviceNotificationToken")
            
            if deviceToken != nil{
                let convoHelper = ConversationHelper()
                
                let loadingNotification = MBProgressHUD.showAdded(to: self.view, animated: true)
                loadingNotification.mode = MBProgressHUDMode.indeterminate
                loadingNotification.label.text = "Logging Out"
                
                let _ = self.loginHelper.removeIOSDeviceToken(deviceToken: deviceToken!){ responseObject, error in
                    loadingNotification.hide(animated: true)
                    
                    if error == nil{
                        if responseObject == "1" {
                            self.logoutLogic();
                        }else{
                            self.logoutError()
                        }
                    }else{
                        self.logoutError()
                    }
                    return
                }
            
            }else{
                self.logoutLogic();
            }
            
        }))
        
        refreshAlert.addAction(UIAlertAction(title: "No", style: .cancel, handler: { (action: UIAlertAction!) in
        
        }))
        
        present(refreshAlert, animated: true, completion: nil)

    }
    
    func logoutLogic(){
        self.coreDataHelper.wipeMessagesFromDB()
        let _ = self.loginHelper.logout()
        
        let loggedOutMenuController: LoggedOutMenuController = self.storyboard?.instantiateViewController(withIdentifier: "LoggedOutMenuController") as! LoggedOutMenuController
        self.revealViewController().setRear(loggedOutMenuController, animated: false)
    }
    
    func logoutError(){
        let refreshAlert = UIAlertController(title: "Logout Error", message: "Unable to logout without a network connection.", preferredStyle: UIAlertControllerStyle.alert)
        
        refreshAlert.addAction(UIAlertAction(title: "Ok", style: .default, handler: nil))
        
        present(refreshAlert, animated: true, completion: nil)

    }

    
    func searchTickets(){
        FlagHelper.focusSearch = true
        self.revealViewController().revealToggle(animated: true)
    }
    
   
}


