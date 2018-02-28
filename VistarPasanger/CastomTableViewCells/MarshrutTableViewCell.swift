//
//  MarshrutTableViewCell.swift
//  VistarPasanger
//
//  Created by Всеволод on 28.02.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import UIKit

class MarshrutTableViewCell: UITableViewCell {
    
    @IBOutlet weak var busName: UILabel!
    @IBOutlet weak var arivalTime: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
