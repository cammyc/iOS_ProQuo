//
//  CreateAccountViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 4/29/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import UIKit
import AVKit
import AVFoundation

class CreateAccountViewController: UIViewController {
    
    // MARK: bgVideo
    var player: AVPlayer?
    
    // MARK: fields
    @IBOutlet weak var tfEmailPhone: UITextField!
    @IBOutlet weak var tfEmailPhoneConfirm: UITextField!
    @IBOutlet weak var tfPassword: UITextField!
    @IBOutlet weak var tfPasswordConfirm: UITextField!
    

    override func viewDidLoad() {
        super.viewDidLoad()

//        let gradient: CAGradientLayer = CAGradientLayer()
//        
//        gradient.colors = [MiscHelper.UIColorFromRGB(rgbValue: 0x49d986).cgColor, MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71).cgColor, MiscHelper.UIColorFromRGB(rgbValue: 0x39cb77).cgColor]
//        gradient.locations = [0.0 , 0.4, 1.0]
//        gradient.startPoint = CGPoint(x: 0.0, y: 0.5)
//        gradient.endPoint = CGPoint(x: 1.0, y: 1.0)
//        gradient.frame = self.view.bounds
//        
//        self.view.layer.insertSublayer(gradient, at: 0)
        
        //initVideoBG()
        makeFieldsLookPretty()
    }
    
    // MARK: Video
    
    func initVideoBG(){
        // Do any additional setup after loading the view.
        let videoURL: NSURL = Bundle.main.url(forResource: "videobg_alt", withExtension: "mp4")! as NSURL
        
        player = AVPlayer(url: videoURL as URL)
        player?.actionAtItemEnd = .none
        player?.isMuted = true
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
        playerLayer.zPosition = -1
        
        playerLayer.frame = view.frame
        
        view.layer.addSublayer(playerLayer)
        
        player?.play()
        
        //loop video
        NotificationCenter.default.addObserver(self, selector: #selector(CreateAccountOrLoginViewController.loopVideo), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: nil)
    }
    
    func loopVideo() {
        player?.seek(to: kCMTimeZero)
        player?.play()
    }
    
    // MARK: Form styling

    
    func makeFieldsLookPretty(){
        updatedTextField(textField: tfEmailPhone)
        updatedTextField(textField: tfEmailPhoneConfirm)
        updatedTextField(textField: tfPassword)
        updatedTextField(textField: tfPasswordConfirm)
//        updatedTextField(textField: tfPassword)
//        updateLoginButton(button: bLogin)
//        bSignUp.backgroundColor = UIColor.white.withAlphaComponent(0.25)
        
    }
    
    func updatedTextField(textField: UITextField){
        textField.backgroundColor = MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71).withAlphaComponent(0.75)
        textField.layer.cornerRadius = 5.0
//        textField.layer.borderColor = MiscHelper.UIColorFromRGB(rgbValue: 0x2ecc71).cgColor
//        textField.layer.borderWidth = 2.0
        textField.attributedPlaceholder = NSAttributedString(string: textField.placeholder!, attributes: [NSForegroundColorAttributeName:UIColor.white.withAlphaComponent(0.75)])
        textField.attributedText = NSAttributedString(string: "", attributes: [NSForegroundColorAttributeName:UIColor.white.withAlphaComponent(0.75)])
        textField.layer.sublayerTransform = CATransform3DMakeTranslation(10,0,0)
        
    }



    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
