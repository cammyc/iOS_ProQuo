//
//  ConversationTableViewCell.swift
//  Scalpr
//
//  Created by Cam Connor on 12/7/16.
//  Copyright © 2016 ProQuo. All rights reserved.
//

import UIKit

class ConversationTableViewCell: UITableViewCell {
    
    // MARK: views
    @IBOutlet weak var ivAttractionImage: UIImageView!
    @IBOutlet weak var labelYourName: UILabel!
    @IBOutlet weak var labelLastMessage: UILabel!
    @IBOutlet weak var labelLastMessageTimestamp: UILabel!
    

    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
