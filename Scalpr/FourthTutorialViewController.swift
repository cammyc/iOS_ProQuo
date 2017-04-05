//
//  FourthTutorialViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 4/2/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import UIKit

class FourthTutorialViewController: UIViewController {
    
    
    @IBOutlet weak var pic: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        pic.image = ImageHelper.circleImage(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: pic.image!), size: CGSize(width: 60, height: 60)))

        // Do any additional setup after loading the view.
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
