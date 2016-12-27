//
//  MyTicketTableViewCell.swift
//  Scalpr
//
//  Created by Cam Connor on 10/10/16.
//  Copyright © 2016 Cam Connor. All rights reserved.
//

import UIKit

class MyTicketTableViewCell: UITableViewCell {
    
    @IBOutlet weak var attractionName: UILabel!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var priceAndNumTickets: UILabel!
    @IBOutlet weak var ivImage: UIImageView!
    @IBOutlet weak var bEditLocation: UIButton!
    @IBOutlet weak var bEditDetails: UIButton!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
}
