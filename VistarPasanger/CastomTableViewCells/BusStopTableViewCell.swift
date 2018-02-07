//
//  BusStopTableViewCell.swift
//  VistarPasanger
//
//  Created by Всеволод on 26.01.2018.
//  Copyright © 2018 me4air. All rights reserved.
//

import UIKit

class BusStopTableViewCell: UITableViewCell {
    var isChecked = false
    @IBOutlet weak var nameLabel: UILabel!
    @IBOutlet weak var commentLabel: UILabel!
    @IBOutlet weak var favoriteImage: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        nameLabel.adjustsFontSizeToFitWidth = true
        nameLabel.minimumScaleFactor = 0.2
        commentLabel.adjustsFontSizeToFitWidth = true
        commentLabel.minimumScaleFactor = 0.2
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
