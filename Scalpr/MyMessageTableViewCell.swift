//
//  MyMessageTableViewCell.swift
//  Scalpr
//
//  Created by Cam Connor on 12/7/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import UIKit

class MyMessageTableViewCell: UITableViewCell {
    
    @IBOutlet weak var myMessage: UILabel!

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
