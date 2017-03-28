//
//  HomeTutorialViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 3/27/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import UIKit

class HomeTutorialViewController: UIViewController {
    
    // MARK: posts
    @IBOutlet weak var blueImage: UIImageView!
    @IBOutlet weak var greenImage: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        blueImage.image = ImageHelper.circleImageBordered(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: blueImage.image!), size: CGSize(width: 55, height: 55)), rgb: 0x3498db, borderWidth: 3)

        greenImage.image = ImageHelper.circleImageBordered(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: greenImage.image!), size: CGSize(width: 55, height: 55)), rgb: 0x2ecc71, borderWidth: 3)
        
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
