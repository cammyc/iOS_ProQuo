//
//  AppDelegate.swift
//  Scalpr
//
//  Created by Cam Connor on 9/27/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import UIKit
import GoogleMaps
import IQKeyboardManagerSwift
import FacebookCore
import FBSDKCoreKit
import UserNotifications
import Whisper
import Kingfisher


protocol PushNotificationDelegate : class {
    var pushNotificationDelegateID: Int {get set}
    func didReceivePushNotification(data: [String: Any])
}

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    let loginHelper = LoginHelper()
    var pushDelegates = [PushNotificationDelegate]()



    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        GMSServices.provideAPIKey("AIzaSyBTdWruMNgtn_OBwVZtPXeTXwhroo2KIyE")
        
        IQKeyboardManager.sharedManager().enable = true
        
        UINavigationBar.appearance().tintColor = MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71)
        
        UIApplication.shared.setMinimumBackgroundFetchInterval(UIApplicationBackgroundFetchIntervalMinimum)

        
        // iOS 10 support
        if #available(iOS 10, *) {
            UNUserNotificationCenter.current().requestAuthorization(options:[.badge, .alert, .sound]){ (granted, error) in }
            application.registerForRemoteNotifications()
        }
            // iOS 9 support
        else if #available(iOS 9, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 8 support
        else if #available(iOS 8, *) {
            UIApplication.shared.registerUserNotificationSettings(UIUserNotificationSettings(types: [.badge, .sound, .alert], categories: nil))
            UIApplication.shared.registerForRemoteNotifications()
        }
            // iOS 7 support
        else {  
            application.registerForRemoteNotifications(matching: [.badge, .sound, .alert])
        }
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        var configureError: NSError?
        GGLContext.sharedInstance().configureWithError(&configureError)
        assert(configureError == nil, "Error configuring Google services: \(configureError)")
                
        return true
    }
    
    func application(_ application: UIApplication, open url: URL, sourceApplication: String?, annotation: Any) -> Bool {
        
        GIDSignIn.sharedInstance().handle(url,
                                          sourceApplication: sourceApplication,
                                          annotation: annotation)
        
        return FBSDKApplicationDelegate.sharedInstance().application(
            application,
            open: url,
            sourceApplication: sourceApplication,
            annotation: annotation)
    }
    
    
//    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
//        
//        GIDSignIn.sharedInstance().handle(url,
//                                          sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as? String,
//                                          annotation: options[UIApplicationOpenURLOptionsKey.annotation])
//        
//        return FBSDKApplicationDelegate.sharedInstance().application(
//            app,
//            open: url,
//            sourceApplication: UIApplicationOpenURLOptionsKey.sourceApplication.rawValue,
//            annotation: UIApplicationOpenURLOptionsKey.annotation.rawValue)
//    }
    
    func application(application: UIApplication,
                     openURL url: NSURL, sourceApplication: String?, annotation: AnyObject?) -> Bool {
        var options: [String: AnyObject] = [UIApplicationOpenURLOptionsKey.sourceApplication.rawValue: sourceApplication as AnyObject,
                                            UIApplicationOpenURLOptionsKey.annotation.rawValue: annotation!]
        return GIDSignIn.sharedInstance().handle(url as URL!,
                                                 sourceApplication: sourceApplication,
                                                 annotation: annotation)
        
    }
    
    
    // Called when APNs has assigned the device a unique token
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        // Convert token to string
        let deviceTokenString = deviceToken.reduce("", {$0 + String(format: "%02X", $1)})
        
        let user = LoginHelper()?.getLoggedInUser();
        
            let preferences = UserDefaults.standard
            
            preferences.set(deviceTokenString, forKey: "deviceNotificationToken")
            
            preferences.synchronize()
        
        if user?.ID != 0 {
            
            loginHelper?.updateIOSDeviceToken(userID: (user?.ID)!, deviceToken: deviceTokenString){ responseObject, error in
                if responseObject == "1"{
                }else{
                    print(responseObject!)
                }
                return
            }
            
        }
        
        // Print it to console
        print("APNs device token: \(deviceTokenString)")
        
        // Persist it in your backend in case it's new
    }
    
    func addPushNotificationDelegate(newDelegate: PushNotificationDelegate) {
        if (pushDelegates.index{$0 === newDelegate} == nil) {
            pushDelegates.append(newDelegate)
        }
    }
    
    func removePushNotificationDelegate(oldDelegate: PushNotificationDelegate){
        for i in 0 ..< pushDelegates.count{
            if pushDelegates[i].pushNotificationDelegateID == oldDelegate.pushNotificationDelegateID {
                pushDelegates.remove(at: i);
                return
            }
        }
    }
    
    // Push notification received
    func application(_ application: UIApplication, didReceiveRemoteNotification data: [AnyHashable : Any]) {
        // Print notification payload data
        //print("Push notification received: \(data)")
//        let badgeCount = UIApplication.shared.applicationIconBadgeNumber + 1
//        UIApplication.shared.applicationIconBadgeNumber = badgeCount
        if application.applicationState == .inactive || application.applicationState == .background {
//            // Access the storyboard and fetch an instance of the view controller
//            let viewController = self.window!.rootViewController as? SWRevealViewController
//            viewController?.rearViewController.performSegue(withIdentifier: "segue_my_convos", sender: nil)
//            let badgeCount = UIApplication.shared.applicationIconBadgeNumber + 1
//            UIApplication.shared.applicationIconBadgeNumber = badgeCount
            
            //this isnt being called
        }else{
            let push = data as NSDictionary
            
            do {
                if let data = push["data"] as? String{
                    
                    if let customData = try? JSONSerialization.jsonObject(with: data.data(using: .utf8)!, options: []) as! [String: Any]
                    {
                    
                        let hideWhisper = self.window?.currentViewController() is SelectedConversationMessagesViewController || self.window?.currentViewController() is ConversationsTableViewController
                        
                        if hideWhisper {
                            UIApplication.shared.applicationIconBadgeNumber = 0

                            for delegate in pushDelegates {
                                delegate.didReceivePushNotification(data: customData)
                            }
                        }else{
                            KingfisherManager.shared.retrieveImage(with: Foundation.URL(string: (customData["imageURL"]) as! String)!, options: nil, progressBlock: nil, completionHandler: { (image, error, cacheType, imageURL) -> () in
                                if image != nil{
                                    let circleImage = ImageHelper.circleImage(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: image!), size: CGSize(width: 50, height: 50)))
                                    let announcement = Announcement(title: customData["yourName"] as! String, subtitle: customData["message"] as? String, image: circleImage, duration: TimeInterval(5), action: nil)
                                    
                                    Whisper.show(shout: announcement, to: (self.window?.currentViewController())!)
                                    
                                }else{
                                    let announcement = Announcement(title: customData["yourName"] as! String, subtitle: customData["message"] as? String, image: nil, duration: TimeInterval(5), action: nil)
                                    
                                    Whisper.show(shout: announcement, to: (self.window?.currentViewController())!)
                                }
                            })
                        }
                    }
                    
                }
            } catch {
                print("Error deserializing JSON: \(error)")
            }
        }
        
    }
    

    
    // Called when APNs failed to register the device for push notifications
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // Print the error to console (you should alert the user that registration failed)
        print("APNs registration failed: \(error)")
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
        //convoHelper.stopBackgroundMessageCheckTimer()
        self.window?.currentViewController()?.beginAppearanceTransition(false, animated: false)
        self.window?.currentViewController()?.endAppearanceTransition()
    }
    

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        self.window?.currentViewController()?.beginAppearanceTransition(true, animated: false)
        self.window?.currentViewController()?.endAppearanceTransition()
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
        AppEventsLogger.activate(application)
        //convoHelper.startBackgroundMessageCheckTimer()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
    }
    
//    func application(_ application: UIApplication, performFetchWithCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
//        convoHelper.backgroundCheckForNewMessageRequest(userID: (LoginHelper()?.getLoggedInUser().ID)!){
//            responseObject, error in
//            
//            if error == nil{
//                return completionHandler(.newData)
//            }else{
//                return completionHandler(.failed)
//            }
//        }
//    }


}

