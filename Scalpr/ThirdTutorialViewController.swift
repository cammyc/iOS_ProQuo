//
//  ThirdTutorialViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 3/28/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import UIKit

class ThirdTutorialViewController: UIViewController {
    
    
    @IBOutlet weak var chance: UIImageView!
    @IBOutlet weak var yankee: UIImageView!

    override func viewDidLoad() {
        super.viewDidLoad()
        
        chance.image = ImageHelper.circleImageBordered(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: chance.image!), size: CGSize(width: 60, height: 60)), rgb: 0x3498db, borderWidth: 3)
        
        yankee.image = ImageHelper.circleImageBordered(image: ImageHelper.ResizeImage(image: ImageHelper.centerImage(image: yankee.image!), size: CGSize(width: 60, height: 60)), rgb: 0x2ecc71, borderWidth: 3)


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
