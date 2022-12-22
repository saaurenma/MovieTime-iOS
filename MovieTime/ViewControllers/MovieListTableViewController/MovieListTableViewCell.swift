//
//  MovieListTableViewCell.swift
//  MovieTime
//
//  Created by Saauren Mankad on 2/6/2022.
//

import UIKit

/// Defines a cell for a cell in the MovieListTableViewController
class MovieListTableViewCell: UITableViewCell {

    // label outlet
    @IBOutlet weak var movieTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }

}
