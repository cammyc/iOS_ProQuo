//
//  SecondTutorialViewController.swift
//  Scalpr
//
//  Created by Cameron Connor on 3/27/17.
//  Copyright © 2017 ProQuo. All rights reserved.
//

import UIKit
import TTRangeSlider
import MMSegmentSlider

class SecondTutorialViewController: UIViewController{
    
    // MARK: Var init
    @IBOutlet weak var priceSlider: TTRangeSlider!
    @IBOutlet weak var numTicketSlider: MMSegmentSlider!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        numTicketSlider.values = [-1, 1, 2, 3, 4]
        numTicketSlider.labels = ["Any", "1", "2", "3" , "4+"]
        
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        
        let format:NumberFormatter = NumberFormatter() //cool animiation
        format.positiveSuffix = "$"
        
        priceSlider.numberFormatterOverride = format
        
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
